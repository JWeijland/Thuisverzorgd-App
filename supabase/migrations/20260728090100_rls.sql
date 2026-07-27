-- Fase 3 · Migratie 2: hulpfuncties, RPC's, Row Level Security, views, storage, realtime.
-- Harde eisen: kringdata alleen voor leden; exacte locatie pas na toestemming;
-- admin uitsluitend geaggregeerde views; ID-documenten nooit in de database.

-- ---------------------------------------------------------------------------
-- Autorisatie-helpers (security definer: geen RLS-recursie)
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.is_makelaar()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'makelaar');
$$;

create or replace function public.is_circle_member(p_circle uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from circle_members
    where circle_id = p_circle
      and profile_id = auth.uid()
      and status in ('actief', 'kijkt_mee')
  );
$$;

create or replace function public.is_circle_beheerder(p_circle uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from circles where id = p_circle and owner_id = auth.uid());
$$;

create or replace function public.shares_circle_with(p_profile uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from circle_members a
    join circle_members b on a.circle_id = b.circle_id
    where a.profile_id = auth.uid()
      and b.profile_id = p_profile
      and a.status in ('actief', 'kijkt_mee')
      and b.status in ('actief', 'kijkt_mee')
  );
$$;

create or replace function public.has_active_subscription(p_profile uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from subscriptions
    where profile_id = p_profile
      and status in ('proef', 'actief')
      and (expires_at is null or expires_at > now())
  );
$$;

-- Gratis limiet: maximaal 2 actieve vrijwilligers per kring zonder abonnement.
create or replace function public.enforce_free_limit()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_count integer;
begin
  if new.member_role = 'vrijwilliger' and new.status = 'actief' then
    select owner_id into v_owner from circles where id = new.circle_id;
    select count(*) into v_count
    from circle_members
    where circle_id = new.circle_id
      and member_role = 'vrijwilliger'
      and status = 'actief'
      and profile_id <> new.profile_id;
    if v_count >= 2 and not public.has_active_subscription(v_owner) then
      raise exception 'gratis_limiet_bereikt'
        using hint = 'Gratis tot 2 vrijwilligers. Meer buddy''s en extra functies met een abonnement.';
    end if;
  end if;
  return new;
end;
$$;

create trigger circle_members_free_limit
  before insert or update on public.circle_members
  for each row execute function public.enforce_free_limit();

-- ---------------------------------------------------------------------------
-- RPC's (server-side flows; allemaal security definer met expliciete checks)
-- ---------------------------------------------------------------------------

-- Hulpvrager koppelt zich met de koppelcode aan de kring ("kijkt mee").
create or replace function public.redeem_circle_code(p_code text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
begin
  select id into v_circle from circles where link_code = upper(trim(p_code));
  if v_circle is null then
    raise exception 'code_onbekend';
  end if;
  insert into circle_members (circle_id, profile_id, member_role, status)
  values (v_circle, auth.uid(), 'hulpvrager', 'kijkt_mee')
  on conflict (circle_id, profile_id) do nothing;
  return v_circle;
end;
$$;

-- Taak claimen, race-veilig: twee vrijwilligers tegelijk → één wint.
create or replace function public.claim_task(p_task uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
begin
  select circle_id into v_circle from tasks where id = p_task;
  if v_circle is null or not public.is_circle_member(v_circle) then
    raise exception 'geen_lid_van_kring';
  end if;
  update tasks
  set claimed_by = auth.uid(), status = 'ingepland'
  where id = p_task and status = 'open' and claimed_by is null;
  return found;
end;
$$;

-- Vrijwilliger geeft een geclaimde taak terug: taak staat weer open.
create or replace function public.release_task(p_task uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  update tasks
  set claimed_by = null, status = 'open'
  where id = p_task and claimed_by = auth.uid() and status = 'ingepland';
  return found;
end;
$$;

-- Afronden met logboekje; notitie verschijnt bij de beheerder onder "Uit de kring".
create or replace function public.complete_task(p_task uuid, p_note text default null)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
begin
  select circle_id into v_circle from tasks
  where id = p_task and claimed_by = auth.uid() and status = 'ingepland';
  if v_circle is null then
    return false;
  end if;
  update tasks set status = 'gedaan' where id = p_task;
  if p_note is not null and length(trim(p_note)) > 0 then
    insert into task_logs (task_id, circle_id, author_id, note)
    values (p_task, v_circle, auth.uid(), trim(p_note));
  end if;
  update profiles set helped_count = helped_count + 1 where id = auth.uid();
  return true;
end;
$$;

-- Conceptplanning in één keer publiceren naar de kring.
create or replace function public.publish_drafts(p_circle uuid)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_count integer;
begin
  if not public.is_circle_beheerder(p_circle) then
    raise exception 'alleen_beheerder';
  end if;
  with moved as (
    insert into tasks (circle_id, type, custom_label, date, time, recurrence, created_by)
    select circle_id, type, custom_label, date, time, recurrence, created_by
    from task_drafts
    where circle_id = p_circle
    returning 1
  )
  select count(*) into v_count from moved;
  delete from task_drafts where circle_id = p_circle;
  return v_count;
end;
$$;

-- Reageren op een uitnodiging (vrijwilliger) of aanvraag (beheerder).
create or replace function public.respond_invitation(p_invitation uuid, p_accept boolean)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  inv record;
begin
  select * into inv from invitations where id = p_invitation and status = 'open';
  if inv is null then
    return false;
  end if;

  if inv.kind = 'uitnodiging' then
    -- alleen de uitgenodigde zelf
    if inv.profile_id is distinct from auth.uid() then
      raise exception 'niet_jouw_uitnodiging';
    end if;
    update invitations set status = case when p_accept then 'geaccepteerd' else 'afgewezen' end::invitation_status
    where id = p_invitation;
    if p_accept then
      insert into circle_members (circle_id, profile_id, member_role, status)
      values (inv.circle_id, auth.uid(), 'vrijwilliger', 'actief')
      on conflict (circle_id, profile_id) do update set status = 'actief';
    end if;
  else
    -- aanvraag: alleen de beheerder van de kring beslist
    if not public.is_circle_beheerder(inv.circle_id) then
      raise exception 'alleen_beheerder';
    end if;
    update invitations set status = case when p_accept then 'geaccepteerd' else 'afgewezen' end::invitation_status
    where id = p_invitation;
    if p_accept then
      insert into circle_members (circle_id, profile_id, member_role, status)
      values (inv.circle_id, inv.profile_id, 'vrijwilliger', 'actief')
      on conflict (circle_id, profile_id) do update set status = 'actief';
    end if;
  end if;
  return true;
end;
$$;

-- Aanbod op directe hulp accepteren: aanvrager kiest, rest wordt afgewezen.
create or replace function public.accept_offer(p_offer uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_request uuid;
  v_volunteer uuid;
begin
  select o.request_id, o.volunteer_id into v_request, v_volunteer
  from request_offers o
  join spontaneous_requests r on r.id = o.request_id
  where o.id = p_offer and r.requester_id = auth.uid() and o.status = 'aangeboden';
  if v_request is null then
    return false;
  end if;
  update request_offers set status = 'geaccepteerd' where id = p_offer;
  update request_offers set status = 'afgewezen'
  where request_id = v_request and id <> p_offer and status = 'aangeboden';
  update spontaneous_requests set status = 'onderweg', helper_id = v_volunteer
  where id = v_request;
  return true;
end;
$$;

create or replace function public.reject_offer(p_offer uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  update request_offers o
  set status = 'afgewezen'
  from spontaneous_requests r
  where o.id = p_offer and r.id = o.request_id
    and r.requester_id = auth.uid() and o.status = 'aangeboden';
  return found;
end;
$$;

-- Directe hulp annuleren, met bericht aan de andere kant.
create or replace function public.cancel_request(p_request uuid, p_message text default null)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  update spontaneous_requests
  set status = 'geannuleerd', cancelled_message = p_message
  where id = p_request
    and (requester_id = auth.uid() or helper_id = auth.uid())
    and status in ('open', 'aanbod', 'onderweg');
  return found;
end;
$$;

create or replace function public.complete_request(p_request uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  update spontaneous_requests
  set status = 'afgerond'
  where id = p_request
    and (requester_id = auth.uid() or helper_id = auth.uid())
    and status = 'onderweg';
  if found then
    update profiles set helped_count = helped_count + 1
    where id = (select helper_id from spontaneous_requests where id = p_request)
      and id = auth.uid();
  end if;
  return found;
end;
$$;

-- Exact adres pas na toestemming (geaccepteerd aanbod) of voor de aanvrager zelf.
create or replace function public.get_request_address(p_request uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_address text;
begin
  select address into v_address
  from spontaneous_requests
  where id = p_request
    and (requester_id = auth.uid() or (helper_id = auth.uid() and status in ('onderweg', 'afgerond')));
  if v_address is null then
    raise exception 'geen_toestemming';
  end if;
  return v_address;
end;
$$;

-- Pilot-stub (ADR-0002): activeert de proefmaand zonder echte betaling.
create or replace function public.activate_subscription_stub()
returns void
language plpgsql security definer set search_path = public as $$
begin
  update subscriptions
  set status = 'proef', source = 'stub', started_at = now(),
      expires_at = now() + interval '1 month', updated_at = now()
  where profile_id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.invitations enable row level security;
alter table public.tasks enable row level security;
alter table public.task_drafts enable row level security;
alter table public.task_logs enable row level security;
alter table public.spontaneous_requests enable row level security;
alter table public.request_offers enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.forum_posts enable row level security;
alter table public.forum_replies enable row level security;
alter table public.forum_reports enable row level security;
alter table public.user_blocks enable row level security;
alter table public.broker_chats enable row level security;
alter table public.broker_messages enable row level security;
alter table public.reviews enable row level security;
alter table public.subscriptions enable row level security;
alter table public.audit_log enable row level security;

-- profiles: jezelf + kringgenoten. Admin heeft géén tabeltoegang (alleen views).
create policy profiles_select on public.profiles for select
  using (id = auth.uid() or public.shares_circle_with(id));
create policy profiles_insert on public.profiles for insert
  with check (id = auth.uid());
create policy profiles_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- circles: alleen leden zien de kring; beheerder beheert.
create policy circles_select on public.circles for select
  using (owner_id = auth.uid() or public.is_circle_member(id));
create policy circles_insert on public.circles for insert
  with check (owner_id = auth.uid());
create policy circles_update on public.circles for update
  using (owner_id = auth.uid());
create policy circles_delete on public.circles for delete
  using (owner_id = auth.uid());

-- circle_members: zichtbaar voor leden; beheerder muteert; lid mag zelf vertrekken.
create policy circle_members_select on public.circle_members for select
  using (profile_id = auth.uid() or public.is_circle_member(circle_id) or public.is_circle_beheerder(circle_id));
create policy circle_members_insert on public.circle_members for insert
  with check (public.is_circle_beheerder(circle_id));
create policy circle_members_update on public.circle_members for update
  using (public.is_circle_beheerder(circle_id));
create policy circle_members_delete on public.circle_members for delete
  using (public.is_circle_beheerder(circle_id) or profile_id = auth.uid());

-- invitations: betrokkene + beheerder.
create policy invitations_select on public.invitations for select
  using (
    profile_id = auth.uid()
    or invited_by = auth.uid()
    or public.is_circle_beheerder(circle_id)
    or (email is not null and lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
  );
create policy invitations_insert on public.invitations for insert
  with check (
    (kind = 'uitnodiging' and public.is_circle_beheerder(circle_id) and invited_by = auth.uid())
    or (kind = 'aanvraag' and profile_id = auth.uid() and invited_by = auth.uid())
  );
create policy invitations_update on public.invitations for update
  using (invited_by = auth.uid() or public.is_circle_beheerder(circle_id));

-- tasks: kringdata alleen voor leden.
create policy tasks_select on public.tasks for select
  using (public.is_circle_member(circle_id) or public.is_circle_beheerder(circle_id));
create policy tasks_insert on public.tasks for insert
  with check (public.is_circle_beheerder(circle_id) and created_by = auth.uid());
create policy tasks_update on public.tasks for update
  using (public.is_circle_beheerder(circle_id));
create policy tasks_delete on public.tasks for delete
  using (public.is_circle_beheerder(circle_id));

-- task_drafts: uitsluitend de beheerder (de kring ziet nog niets).
create policy task_drafts_all on public.task_drafts for all
  using (public.is_circle_beheerder(circle_id))
  with check (public.is_circle_beheerder(circle_id) and created_by = auth.uid());

-- task_logs: leden lezen; schrijven gaat via complete_task().
create policy task_logs_select on public.task_logs for select
  using (public.is_circle_member(circle_id) or public.is_circle_beheerder(circle_id));

-- spontaneous_requests: aanvrager + geaccepteerde helper zien de volledige rij.
-- Vrijwilligers browsen open aanvragen via de view v_open_requests (zonder adres).
create policy requests_select on public.spontaneous_requests for select
  using (requester_id = auth.uid() or helper_id = auth.uid());
create policy requests_insert on public.spontaneous_requests for insert
  with check (requester_id = auth.uid());
create policy requests_update on public.spontaneous_requests for update
  using (requester_id = auth.uid());

-- request_offers: aanvrager ziet aanbiedingen; vrijwilliger zijn eigen aanbod.
create policy offers_select on public.request_offers for select
  using (
    volunteer_id = auth.uid()
    or exists (select 1 from public.spontaneous_requests r where r.id = request_id and r.requester_id = auth.uid())
  );
create policy offers_insert on public.request_offers for insert
  with check (
    volunteer_id = auth.uid()
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.id_verified)
  );
create policy offers_update on public.request_offers for update
  using (volunteer_id = auth.uid());

-- messages (kringchat): alleen leden; blokkades gefilterd.
create policy messages_select on public.messages for select
  using (
    public.is_circle_member(circle_id)
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = sender_id
    )
  );
create policy messages_insert on public.messages for insert
  with check (public.is_circle_member(circle_id) and sender_id = auth.uid());

-- notifications: alleen de eigenaar; aanmaken doet het systeem (service role).
create policy notifications_select on public.notifications for select
  using (profile_id = auth.uid());
create policy notifications_update on public.notifications for update
  using (profile_id = auth.uid());
create policy notifications_delete on public.notifications for delete
  using (profile_id = auth.uid());

-- forum: leesbaar voor ingelogde gebruikers, minus verborgen en geblokkeerd.
create policy forum_posts_select on public.forum_posts for select
  using (
    auth.uid() is not null and not hidden
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = author_id
    )
  );
create policy forum_posts_insert on public.forum_posts for insert
  with check (author_id = auth.uid());
create policy forum_posts_update on public.forum_posts for update
  using (author_id = auth.uid() or public.is_makelaar());

create policy forum_replies_select on public.forum_replies for select
  using (
    auth.uid() is not null and not hidden
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = author_id
    )
  );
create policy forum_replies_insert on public.forum_replies for insert
  with check (author_id = auth.uid());
create policy forum_replies_update on public.forum_replies for update
  using (author_id = auth.uid() or public.is_makelaar());

-- meldingen: melder + hulpmakelaars (moderatie).
create policy forum_reports_select on public.forum_reports for select
  using (reporter_id = auth.uid() or public.is_makelaar());
create policy forum_reports_insert on public.forum_reports for insert
  with check (reporter_id = auth.uid());
create policy forum_reports_update on public.forum_reports for update
  using (public.is_makelaar());

-- blokkades: alleen je eigen lijst.
create policy user_blocks_all on public.user_blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- hulpmakelaar-chat: eigenaar + makelaars.
create policy broker_chats_select on public.broker_chats for select
  using (profile_id = auth.uid() or public.is_makelaar());
create policy broker_chats_insert on public.broker_chats for insert
  with check (profile_id = auth.uid());
create policy broker_chats_update on public.broker_chats for update
  using (profile_id = auth.uid() or public.is_makelaar());

create policy broker_messages_select on public.broker_messages for select
  using (
    public.is_makelaar()
    or exists (select 1 from public.broker_chats c where c.id = chat_id and c.profile_id = auth.uid())
  );
create policy broker_messages_insert on public.broker_messages for insert
  with check (
    sender_id = auth.uid()
    and (
      public.is_makelaar()
      or exists (select 1 from public.broker_chats c where c.id = chat_id and c.profile_id = auth.uid())
    )
  );

-- reviews: kringleden lezen; beheerder schrijft over zijn vrijwilligers.
create policy reviews_select on public.reviews for select
  using (public.is_circle_member(circle_id) or public.is_circle_beheerder(circle_id) or volunteer_id = auth.uid());
create policy reviews_insert on public.reviews for insert
  with check (public.is_circle_beheerder(circle_id) and reviewer_id = auth.uid());

-- subscriptions: alleen je eigen regel zien; muteren via RPC/service.
create policy subscriptions_select on public.subscriptions for select
  using (profile_id = auth.uid());

-- audit_log: niemand leest via de client (alleen service role).

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Kaart: kringen op wijkniveau, voor alle ingelogde gebruikers.
create view public.v_map_circles as
select id, name, location_rounded
from public.circles
where location_rounded is not null;
revoke all on public.v_map_circles from anon;

-- Kaart: buddy's uit de buddy-pool, alleen voornaam + wijkniveau.
create view public.v_map_buddies as
select
  id,
  split_part(name, ' ', 1) as voornaam,
  city,
  helped_count,
  location_rounded
from public.profiles
where role = 'vrijwilliger'
  and pool_opt_in
  and not vacation_mode
  and location_rounded is not null;
revoke all on public.v_map_buddies from anon;

-- Directe hulp: open aanvragen zonder adres, op wijkniveau.
create view public.v_open_requests as
select
  r.id,
  r.type,
  r.status,
  r.location_rounded,
  r.created_at,
  split_part(p.name, ' ', 1) as voornaam
from public.spontaneous_requests r
join public.profiles p on p.id = r.requester_id
where r.status in ('open', 'aanbod');
revoke all on public.v_open_requests from anon;

-- Buddy-kaartje voor uitnodigen/beoordelen: voornaam, plaats, ervaring, waardering.
create view public.v_buddy_cards as
select
  p.id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id) as waardering,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger') as kringen,
  p.location_rounded
from public.profiles p
where p.role = 'vrijwilliger' and p.pool_opt_in;
revoke all on public.v_buddy_cards from anon;

-- Admin: uitsluitend geaggregeerd en geanonimiseerd. Geen tabeltoegang.
create view public.v_admin_kerncijfers as
select
  (select count(*) from public.circles) as actieve_hulpkringen,
  (select count(*) from public.profiles where role = 'vrijwilliger') as buddys,
  (select coalesce(round(100.0 * count(*) filter (where status = 'gedaan')
      / nullif(count(*) filter (where status in ('gedaan', 'open', 'ingepland')), 0)), 0)
     from public.tasks where date >= current_date - 30) as taken_vervuld_pct,
  (select count(*) from public.tasks where date = current_date) as taken_vandaag
where public.is_admin();
revoke all on public.v_admin_kerncijfers from anon;

create view public.v_admin_groei_per_maand as
select to_char(date_trunc('month', created_at), 'YYYY-MM') as maand,
       count(*) as nieuwe_kringen
from public.circles
where public.is_admin()
group by 1
order by 1;
revoke all on public.v_admin_groei_per_maand from anon;

create view public.v_admin_taken_per_type as
select type, count(*) as aantal
from public.tasks
where public.is_admin() and status = 'gedaan' and date >= current_date - 30
group by type
order by aantal desc;
revoke all on public.v_admin_taken_per_type from anon;

create view public.v_admin_matchtijd as
select coalesce(round(avg(extract(epoch from (o.updated_at - r.created_at)) / 3600)::numeric, 1), 0)
         as gemiddelde_uren_tot_match
from public.spontaneous_requests r
join public.request_offers o on o.request_id = r.id and o.status = 'geaccepteerd'
where public.is_admin() and r.created_at >= current_date - 30;
revoke all on public.v_admin_matchtijd from anon;

-- ---------------------------------------------------------------------------
-- Storage: privé buckets. ID-documenten kortlopend (opruiming: edge function).
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false), ('id-documents', 'id-documents', false)
on conflict (id) do nothing;

-- Pad-conventie: <user-id>/bestand.jpg
create policy "avatars eigen beheer" on storage.objects
  for all
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars kringgenoten lezen" on storage.objects
  for select
  using (
    bucket_id = 'avatars'
    and public.shares_circle_with(((storage.foldername(name))[1])::uuid)
  );

-- ID-documenten: alleen zelf uploaden; niemand leest via de client.
create policy "id-documenten upload" on storage.objects
  for insert
  with check (bucket_id = 'id-documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table
  public.tasks,
  public.messages,
  public.notifications,
  public.spontaneous_requests,
  public.request_offers,
  public.broker_messages;
