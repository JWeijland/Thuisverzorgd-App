-- Fase 7 · Meldingen: device tokens, notificatie-triggers, push-webhook,
-- taak intrekken (met melding) en wekelijkse taakreeksen.

create extension if not exists pg_net;

-- ---------------------------------------------------------------------------
-- Device tokens (Expo push tokens per gebruiker)
-- ---------------------------------------------------------------------------
create table public.device_tokens (
  token text primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text,
  updated_at timestamptz not null default now()
);
create index on public.device_tokens (profile_id);

alter table public.device_tokens enable row level security;
create policy device_tokens_all on public.device_tokens for all
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

alter table public.notifications add column pushed_at timestamptz;

-- ---------------------------------------------------------------------------
-- Meldingen aanmaken: centrale helper die voorkeuren + vakantiemodus respecteert
-- ---------------------------------------------------------------------------
create or replace function public.notify(
  p_profile uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_deeplink text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_prefs jsonb;
  v_vacation boolean;
begin
  if p_profile is null then return; end if;
  select notification_prefs, vacation_mode into v_prefs, v_vacation
  from profiles where id = p_profile;
  -- categorie uitgezet door de gebruiker?
  if coalesce((v_prefs ->> p_kind)::boolean, true) = false then return; end if;
  -- vakantiemodus: geen taaksuggesties
  if v_vacation and p_kind in ('taak_nieuw', 'aanbod_kans') then return; end if;
  insert into notifications (profile_id, kind, title, body, deeplink)
  values (p_profile, p_kind, p_title, p_body, p_deeplink);
end;
$$;

-- Label van een taak voor meldingsteksten.
create or replace function public.task_label(p_type public.task_type, p_custom text)
returns text language sql immutable as $$
  select case
    when p_type = 'anders' and p_custom is not null then p_custom
    when p_type = 'boodschappen' then 'Boodschappen'
    when p_type = 'wandelen' then 'Wandelen'
    when p_type = 'vervoer' then 'Vervoer'
    when p_type = 'gezelschap' then 'Gezelschap'
    else 'Taak' end;
$$;

create or replace function public.first_name(p_profile uuid)
returns text language sql stable security definer set search_path = public as $$
  select split_part(name, ' ', 1) from profiles where id = p_profile;
$$;

-- ---------------------------------------------------------------------------
-- Triggers per gebeurtenis
-- ---------------------------------------------------------------------------

-- Nieuwe taak gepubliceerd → alle actieve vrijwilligers van de kring (behalve maker).
create or replace function public.trg_task_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  member record;
begin
  if new.status <> 'open' then return new; end if;
  -- kopieën uit een weekreeks niet apart melden (de eerste taak meldt al)
  if new.series_id is not null then return new; end if;
  for member in
    select profile_id from circle_members
    where circle_id = new.circle_id and member_role = 'vrijwilliger' and status = 'actief'
      and profile_id <> new.created_by
  loop
    perform public.notify(
      member.profile_id, 'taak_nieuw', 'Nieuwe taak in je kring',
      public.task_label(new.type, new.custom_label) || ' · ' ||
        to_char(new.date, 'DD-MM') || ' om ' || to_char(new.time, 'HH24:MI'),
      'tvz://rooster'
    );
  end loop;
  return new;
end;
$$;
create trigger tasks_notify_created after insert on public.tasks
  for each row execute function public.trg_task_created();

-- Taak geclaimd → beheerder; taak geannuleerd → degene die hem had aangenomen.
create or replace function public.trg_task_updated()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
begin
  select owner_id into v_owner from circles where id = new.circle_id;
  if old.status = 'open' and new.status = 'ingepland' and new.claimed_by is not null then
    if new.claimed_by <> v_owner then
      perform public.notify(
        v_owner, 'taak_geclaimd', public.first_name(new.claimed_by) || ' neemt een taak aan',
        public.task_label(new.type, new.custom_label) || ' · ' ||
          to_char(new.date, 'DD-MM') || ' om ' || to_char(new.time, 'HH24:MI'),
        'tvz://rooster'
      );
    end if;
  elsif new.status = 'geannuleerd' and old.status <> 'geannuleerd' and old.claimed_by is not null then
    perform public.notify(
      old.claimed_by, 'taak_geannuleerd', 'Taak geannuleerd',
      public.task_label(new.type, new.custom_label) || ' op ' || to_char(new.date, 'DD-MM') ||
        ' gaat niet door.',
      'tvz://rooster'
    );
  end if;
  return new;
end;
$$;
create trigger tasks_notify_updated after update on public.tasks
  for each row execute function public.trg_task_updated();

-- Aanbod op directe hulp → aanvrager; antwoord op aanbod → vrijwilliger.
create or replace function public.trg_offer_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_requester uuid;
begin
  select requester_id into v_requester from spontaneous_requests where id = new.request_id;
  perform public.notify(
    v_requester, 'aanbod', public.first_name(new.volunteer_id) || ' kan helpen!',
    coalesce(new.message, 'Bekijk het aanbod op de kaart.'),
    'tvz://buurt'
  );
  return new;
end;
$$;
create trigger offers_notify_created after insert on public.request_offers
  for each row execute function public.trg_offer_created();

create or replace function public.trg_offer_updated()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.status = 'aangeboden' and new.status = 'geaccepteerd' then
    perform public.notify(
      new.volunteer_id, 'aanbod_antwoord', 'Je kunt helpen!',
      'Je aanbod is geaccepteerd. Het adres staat nu voor je klaar.',
      'tvz://buurt'
    );
  elsif old.status = 'aangeboden' and new.status = 'afgewezen' then
    perform public.notify(
      new.volunteer_id, 'aanbod_antwoord', 'Dit keer niet',
      'De aanvrager koos iemand anders. Fijn dat je wilde helpen!',
      'tvz://buurt'
    );
  end if;
  return new;
end;
$$;
create trigger offers_notify_updated after update on public.request_offers
  for each row execute function public.trg_offer_updated();

-- Hulpvraag ingetrokken terwijl er een helper onderweg was.
create or replace function public.trg_request_cancelled()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'geannuleerd' and old.status <> 'geannuleerd' and old.helper_id is not null then
    perform public.notify(
      old.helper_id, 'aanvraag_ingetrokken', 'De hulpvraag is ingetrokken',
      coalesce(new.cancelled_message, 'Dat kan gebeuren, het ligt niet aan jou.'),
      'tvz://buurt'
    );
  end if;
  return new;
end;
$$;
create trigger requests_notify_cancelled after update on public.spontaneous_requests
  for each row execute function public.trg_request_cancelled();

-- Uitnodiging → uitgenodigde; aanvraag voor de kring → beheerder.
create or replace function public.trg_invitation_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_circle_name text;
begin
  select owner_id, name into v_owner, v_circle_name from circles where id = new.circle_id;
  if new.kind = 'uitnodiging' and new.profile_id is not null then
    perform public.notify(
      new.profile_id, 'uitnodiging', 'Uitnodiging voor ' || v_circle_name,
      coalesce(new.message, public.first_name(new.invited_by) || ' nodigt je uit als vrijwilliger.'),
      'tvz://inbox'
    );
  elsif new.kind = 'aanvraag' then
    perform public.notify(
      v_owner, 'uitnodiging', 'Aanvraag voor je kring',
      public.first_name(new.profile_id) || ' wil zich aansluiten en stuurde een voorstelbericht mee.',
      'tvz://inbox'
    );
  end if;
  return new;
end;
$$;
create trigger invitations_notify_created after insert on public.invitations
  for each row execute function public.trg_invitation_created();

-- Nieuw kringbericht → alle leden behalve de afzender.
create or replace function public.trg_message_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  member record;
begin
  for member in
    select profile_id from circle_members
    where circle_id = new.circle_id and status in ('actief', 'kijkt_mee')
      and profile_id <> new.sender_id
  loop
    perform public.notify(
      member.profile_id, 'kringbericht', public.first_name(new.sender_id) || ' in de kringchat',
      left(new.body, 120),
      'tvz://kring'
    );
  end loop;
  return new;
end;
$$;
create trigger messages_notify_created after insert on public.messages
  for each row execute function public.trg_message_created();

-- Antwoord op je forumvraag → vraagsteller.
create or replace function public.trg_forum_reply_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_author uuid;
  v_title text;
begin
  select author_id, title into v_author, v_title from forum_posts where id = new.post_id;
  if v_author <> new.author_id then
    perform public.notify(
      v_author, 'forum_antwoord', 'Antwoord op je vraag',
      '"' || left(v_title, 60) || '" heeft een nieuw antwoord.',
      'tvz://steun'
    );
  end if;
  return new;
end;
$$;
create trigger forum_replies_notify after insert on public.forum_replies
  for each row execute function public.trg_forum_reply_created();

-- Hulpmakelaar antwoordt → eigenaar van de chat.
create or replace function public.trg_broker_message_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
begin
  select profile_id into v_owner from broker_chats where id = new.chat_id;
  if v_owner <> new.sender_id then
    perform public.notify(
      v_owner, 'makelaar', 'De hulpmakelaar heeft geantwoord',
      left(new.body, 120),
      'tvz://steun'
    );
  end if;
  return new;
end;
$$;
create trigger broker_messages_notify after insert on public.broker_messages
  for each row execute function public.trg_broker_message_created();

-- ---------------------------------------------------------------------------
-- Push-webhook: elke nieuwe melding → edge function send-push (Expo Push API).
-- De anon key is publiek (zit ook in de app); de function zelf gebruikt de
-- service role uit zijn omgeving en leest alleen de doorgegeven rij.
-- ---------------------------------------------------------------------------
create or replace function public.trg_notification_push()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://pfvxgzosntzzhydzzkaj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdnhnem9zbnR6emh5ZHp6a2FqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxODg4NjYsImV4cCI6MjEwMDc2NDg2Nn0.5Ysv9ecPa5FhAotGogpBdmqsXJc1WRfNXIB-ietD78w'
    ),
    body := jsonb_build_object('id', new.id)
  );
  return new;
end;
$$;
create trigger notifications_push after insert on public.notifications
  for each row execute function public.trg_notification_push();

-- ---------------------------------------------------------------------------
-- Taak intrekken door de beheerder (ook na claim) — de trigger meldt het netjes.
-- ---------------------------------------------------------------------------
create or replace function public.cancel_task(p_task uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
begin
  select circle_id into v_circle from tasks where id = p_task;
  if v_circle is null or not public.is_circle_beheerder(v_circle) then
    raise exception 'alleen_beheerder';
  end if;
  update tasks set status = 'geannuleerd'
  where id = p_task and status in ('open', 'ingepland');
  return found;
end;
$$;

-- ---------------------------------------------------------------------------
-- Wekelijkse reeks: bij een nieuwe wekelijkse taak meteen 8 weken vooruit plannen.
-- ---------------------------------------------------------------------------
create or replace function public.trg_task_series()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  i integer;
begin
  if new.recurrence = 'wekelijks' and new.series_id is null then
    update tasks set series_id = new.id where id = new.id;
    for i in 1..7 loop
      insert into tasks (circle_id, type, custom_label, date, time, recurrence, series_id, created_by)
      values (new.circle_id, new.type, new.custom_label, new.date + (i * 7), new.time,
              'wekelijks', new.id, new.created_by);
    end loop;
  end if;
  return new;
end;
$$;
create trigger tasks_series after insert on public.tasks
  for each row execute function public.trg_task_series();

-- Reeks in één keer intrekken.
create or replace function public.cancel_task_series(p_series uuid)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
  v_count integer;
begin
  select circle_id into v_circle from tasks where series_id = p_series limit 1;
  if v_circle is null or not public.is_circle_beheerder(v_circle) then
    raise exception 'alleen_beheerder';
  end if;
  update tasks set status = 'geannuleerd'
  where series_id = p_series and status in ('open', 'ingepland') and date >= current_date;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
