-- ===========================================================================
-- fase35_zorgkring.sql
--
-- ZORGKRING-PIVOT (zie MEGA_PROMPT_ZORGKRING_PIVOT.md).
-- De zorgkring (care_teams) wordt hét centrale teambegrip:
--   • Na de onboarding van een hulpvrager start teamvorming: buddies in de
--     buurt krijgen per ring van 5 (elke 5 min) een uitnodiging.
--   • De hulpvrager stelt min/max teamgrootte in, reviewt het team en kan
--     buddies weigeren; pas daarna gaat de kring live.
--   • Schema-momenten escaleren 48u → 24u (team) → 30 min (urgente broadcast).
--   • Spontane hulpvragen zijn 8 min exclusief voor het team, daarna fallback.
--   • Gamification (punten/uitjes-doel) hangt voortaan aan de zorgkring;
--     de losse buddy-teams worden gearchiveerd.
--
-- Cron-functions die hierop draaien: team-formation (elke minuut) en
-- schedule-watchdog (elke minuut) — zie supabase/functions/.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Hulpvrager: teamvoorkeur
-- ---------------------------------------------------------------------------

alter table public.elderly_profiles
    add column if not exists team_mode text not null default 'team'
        check (team_mode in ('team','random_only'));

-- ---------------------------------------------------------------------------
-- 2. care_teams: vormingsstatus, grootte, gamification, benaderde locatie
-- ---------------------------------------------------------------------------

alter table public.care_teams
    add column if not exists status text not null default 'live'
        check (status in ('forming','review','live','paused')),
    add column if not exists min_size int not null default 3 check (min_size between 1 and 10),
    add column if not exists max_size int not null default 5 check (max_size between 1 and 15),
    -- Ring-dispatch state (gezet door team-formation cron)
    add column if not exists formation_started_at timestamptz,
    add column if not exists last_ring int not null default 0,
    add column if not exists last_ring_at timestamptz,
    -- Na 1 uur zonder vol team: keuzemelding aan hulpvrager verstuurd?
    add column if not exists choice_sent boolean not null default false,
    -- Herinnering aan weigeraars/negeerders verstuurd?
    add column if not exists invite_reminder_sent boolean not null default false,
    -- Review-klaar-melding (minimum bereikt) verstuurd?
    add column if not exists review_notified boolean not null default false,
    -- Keuze van de hulpvrager: mogen gaten met willekeurige buddies gevuld worden?
    add column if not exists fallback_allowed boolean not null default true,
    -- Afgeronde coördinaten (~1 km nauwkeurig) voor "Teams in de buurt";
    -- het echte adres blijft privé tot een buddy lid is.
    add column if not exists approx_latitude double precision,
    add column if not exists approx_longitude double precision,
    add column if not exists area text not null default '',
    -- Korte omschrijving van de gevraagde hulp, zichtbaar vóór toetreding.
    add column if not exists help_summary text not null default '',
    -- Gamification (vervangt de losse buddy-teams)
    add column if not exists outing_target int not null default 2000,
    add column if not exists milestone_75_notified boolean not null default false,
    add column if not exists milestone_100_notified boolean not null default false;

comment on column public.care_teams.status is
    'forming: werving loopt; review: minimum bereikt, hulpvrager beoordeelt; live: actief; paused: tijdelijk stil';

-- Eén team per hulpvrager.
create unique index if not exists uq_care_teams_elderly
    on public.care_teams(elderly_id) where elderly_id is not null;

-- Punten per teamlid (gamification verhuist naar de zorgkring).
alter table public.care_team_members
    add column if not exists points int not null default 0;

-- ---------------------------------------------------------------------------
-- 3. Uitnodigingen (ring-dispatch) en join-verzoeken
-- ---------------------------------------------------------------------------

create table if not exists public.care_team_invites (
    id            uuid primary key default gen_random_uuid(),
    care_team_id  uuid not null references public.care_teams(id) on delete cascade,
    buddy_id      uuid not null references public.profiles(id) on delete cascade,
    ring          int not null default 1,
    -- pending → accepted / declined / expired; reminded = éénmalige herinnering gehad
    status        text not null default 'pending'
        check (status in ('pending','reminded','accepted','declined','expired')),
    -- true als de buddy al vaste buddy van deze hulpvrager was (conversie-flow)
    is_favorite   boolean not null default false,
    -- Privacy: alleen deze velden ziet de buddy vóór toetreding.
    elderly_name  text not null default '',
    area          text not null default '',
    help_summary  text not null default '',
    sent_at       timestamptz not null default now(),
    responded_at  timestamptz,
    unique (care_team_id, buddy_id)
);
create index if not exists idx_ct_invites_buddy on public.care_team_invites(buddy_id, status);
create index if not exists idx_ct_invites_team  on public.care_team_invites(care_team_id, status);

create table if not exists public.care_team_join_requests (
    id            uuid primary key default gen_random_uuid(),
    care_team_id  uuid not null references public.care_teams(id) on delete cascade,
    buddy_id      uuid not null references public.profiles(id) on delete cascade,
    -- search = via "Teams in de buurt"; fallback = invaller die vast lid wil worden
    source        text not null default 'search' check (source in ('search','fallback')),
    status        text not null default 'pending'
        check (status in ('pending','approved','rejected')),
    created_at    timestamptz not null default now(),
    decided_at    timestamptz,
    decided_by    uuid references public.profiles(id) on delete set null
);
create index if not exists idx_ct_joinreq_team  on public.care_team_join_requests(care_team_id, status);
create index if not exists idx_ct_joinreq_buddy on public.care_team_join_requests(buddy_id, status);

-- ---------------------------------------------------------------------------
-- 4. Schema-escalatie op care_team_visits (48u → 24u → 30 min)
-- ---------------------------------------------------------------------------

alter table public.care_team_visits
    -- "Er staan nieuwe momenten open"-melding aan het team al verstuurd?
    add column if not exists team_notified    boolean not null default false,
    add column if not exists reminder_48_sent boolean not null default false,
    add column if not exists reminder_24_sent boolean not null default false,
    add column if not exists urgent_sent      boolean not null default false;

create index if not exists idx_ct_visits_open
    on public.care_team_visits(scheduled_at)
    where claimed_by is null;

-- ---------------------------------------------------------------------------
-- 5. Spontane hulpvragen: team-exclusief venster + fallback-trap
-- ---------------------------------------------------------------------------

alter table public.tasks
    -- 'pool' = zichtbaar in de open lijst; 'team' = exclusief voor de zorgkring.
    add column if not exists visibility text not null default 'pool'
        check (visibility in ('team','pool')),
    add column if not exists team_exclusive_until timestamptz,
    -- 0 = geen fallback nodig, 1 = team genotificeerd, 2 = pool 2.5 km,
    -- 3 = pool 5 km, 4 = opgegeven (excuses gestuurd)
    add column if not exists fallback_stage smallint not null default 0,
    add column if not exists fallback_stage_at timestamptz;

create index if not exists idx_tasks_team_window
    on public.tasks(status, visibility, team_exclusive_until)
    where status = 'open';

-- Elke nieuwe open hulpvraag van een hulpvrager met een live zorgkring wordt
-- automatisch team-exclusief: 8 minuten venster (daarna zet de
-- schedule-watchdog 'm naar de pool), of onbeperkt als de hulpvrager geen
-- willekeurige buddies wil (fallback_allowed = false). Geldt voor álle
-- aanmaak-routes (app-insert én create_task_for_elderly-RPC).
create or replace function public.apply_team_visibility()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
    v_team record;
begin
    if new.status = 'open' then
        select id, fallback_allowed into v_team
          from care_teams
         where elderly_id = new.elderly_id and status = 'live';
        if found then
            new.visibility := 'team';
            new.fallback_stage := 1;
            new.team_exclusive_until :=
                case when v_team.fallback_allowed then now() + interval '8 minutes'
                     else null end;
        end if;
    end if;
    return new;
end;
$$;

drop trigger if exists trg_tasks_team_visibility on public.tasks;
create trigger trg_tasks_team_visibility
    before insert on public.tasks
    for each row execute function public.apply_team_visibility();

-- ---------------------------------------------------------------------------
-- 6. Inbox: koppeling naar zorgkring + archivering oude buddy-teams
-- ---------------------------------------------------------------------------

alter table public.notifications
    add column if not exists care_team_id uuid references public.care_teams(id) on delete cascade;

alter table public.teams
    add column if not exists archived boolean not null default false;

-- point_events kan voortaan aan een zorgkring hangen.
alter table public.point_events
    add column if not exists care_team_id uuid references public.care_teams(id) on delete set null;

-- ---------------------------------------------------------------------------
-- 7. RLS voor de nieuwe tabellen
-- ---------------------------------------------------------------------------

alter table public.care_team_invites       enable row level security;
alter table public.care_team_join_requests enable row level security;

-- Helper: is de caller de hulpvrager van dit team of een gekoppeld familielid?
create or replace function public.is_care_team_manager(p_team_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from care_teams t
        where t.id = p_team_id
          and (t.elderly_id = auth.uid()
               or exists (select 1 from family_elderly_links l
                          where l.elderly_id = t.elderly_id and l.family_id = auth.uid()))
    );
$$;

drop policy if exists ct_invites_select on public.care_team_invites;
create policy ct_invites_select on public.care_team_invites
    for select to authenticated
    using (buddy_id = auth.uid() or public.is_care_team_manager(care_team_id));
-- Inserts/updates alleen via service-role (team-formation cron) en RPC's.

drop policy if exists ct_joinreq_select on public.care_team_join_requests;
create policy ct_joinreq_select on public.care_team_join_requests
    for select to authenticated
    using (buddy_id = auth.uid() or public.is_care_team_manager(care_team_id));

-- ---------------------------------------------------------------------------
-- 8. RPC's
-- ---------------------------------------------------------------------------

-- 8.1 Teamvorming starten (hulpvrager of familielid), na afronden onboarding
--     of bij conversie vanaf random_only. Retourneert het team-id.
create or replace function public.start_team_formation(
    p_name text,
    p_min int,
    p_max int,
    p_elderly_id uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
    v_elderly uuid;
    v_team uuid;
    v_first text;
    v_area text;
    v_lat double precision;
    v_lng double precision;
begin
    -- Caller is de hulpvrager zelf, of een familielid dat p_elderly_id meegeeft.
    if p_elderly_id is null then
        v_elderly := auth.uid();
    else
        v_elderly := p_elderly_id;
        if v_elderly <> auth.uid() and not exists (
            select 1 from family_elderly_links
            where elderly_id = v_elderly and family_id = auth.uid()
        ) then
            raise exception 'geen toegang tot deze hulpvrager';
        end if;
    end if;

    if p_min < 1 or p_max < p_min or p_max > 15 then
        raise exception 'ongeldige teamgrootte';
    end if;

    select coalesce(nullif(split_part(p.full_name, ' ', 1), ''), 'Hulpvrager'),
           coalesce(nullif(trim(regexp_replace(e.address, '^[^,]*,', '')), ''), ''),
           e.latitude, e.longitude
      into v_first, v_area, v_lat, v_lng
      from profiles p
      left join elderly_profiles e on e.id = p.id
     where p.id = v_elderly;

    select id into v_team from care_teams where elderly_id = v_elderly;

    if v_team is null then
        insert into care_teams (name, elderly_id, elderly_name, created_by,
                                status, min_size, max_size, formation_started_at,
                                approx_latitude, approx_longitude, area)
        values (coalesce(nullif(p_name,''), 'Team van ' || v_first), v_elderly, v_first, auth.uid(),
                'forming', p_min, p_max, now(),
                round(v_lat::numeric, 2), round(v_lng::numeric, 2), v_area)
        returning id into v_team;
    else
        update care_teams
           set status = 'forming',
               min_size = p_min,
               max_size = p_max,
               formation_started_at = now(),
               last_ring = 0, last_ring_at = null,
               choice_sent = false, invite_reminder_sent = false, review_notified = false,
               approx_latitude = round(v_lat::numeric, 2),
               approx_longitude = round(v_lng::numeric, 2),
               area = v_area
         where id = v_team;
    end if;

    update elderly_profiles set team_mode = 'team' where id = v_elderly;
    return v_team;
end;
$$;

-- 8.2 Uitnodiging accepteren → direct teamlid (review door hulpvrager volgt).
create or replace function public.accept_team_invite(p_invite_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
    v_inv record;
    v_members int;
begin
    select * into v_inv from care_team_invites
     where id = p_invite_id and buddy_id = auth.uid();
    if v_inv is null then raise exception 'uitnodiging niet gevonden'; end if;
    if v_inv.status not in ('pending','reminded','declined') then
        raise exception 'uitnodiging is niet meer geldig';
    end if;

    select count(*) into v_members from care_team_members
     where care_team_id = v_inv.care_team_id;
    if v_members >= (select max_size from care_teams where id = v_inv.care_team_id) then
        update care_team_invites set status = 'expired', responded_at = now()
         where id = p_invite_id;
        raise exception 'het team zit al vol';
    end if;

    update care_team_invites set status = 'accepted', responded_at = now()
     where id = p_invite_id;
    insert into care_team_members (care_team_id, buddy_id, role)
    values (v_inv.care_team_id, auth.uid(), 'lid')
    on conflict (care_team_id, buddy_id) do nothing;
end;
$$;

-- 8.3 Uitnodiging afslaan.
create or replace function public.decline_team_invite(p_invite_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
    update care_team_invites
       set status = 'declined', responded_at = now()
     where id = p_invite_id and buddy_id = auth.uid()
       and status in ('pending','reminded');
end;
$$;

-- 8.4 Review door hulpvrager/familie: buddy weigeren (uit het team).
create or replace function public.review_team_member(
    p_team_id uuid, p_buddy_id uuid, p_accept boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
    if not public.is_care_team_manager(p_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    if not p_accept then
        delete from care_team_members
         where care_team_id = p_team_id and buddy_id = p_buddy_id;
        update care_team_invites set status = 'expired'
         where care_team_id = p_team_id and buddy_id = p_buddy_id;
    end if;
end;
$$;

-- 8.5 Review afronden → team live (mag ook onder het minimum, na de 1-uur-keuze).
create or replace function public.finalize_team_review(p_team_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
    if not public.is_care_team_manager(p_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    update care_teams set status = 'live' where id = p_team_id;
end;
$$;

-- 8.6 Keuze na 1 uur: gaten vullen met willekeurige buddies of niet.
create or replace function public.set_team_fallback(p_team_id uuid, p_allowed boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
    if not public.is_care_team_manager(p_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    update care_teams set fallback_allowed = p_allowed where id = p_team_id;
end;
$$;

-- 8.7 Join-verzoek van een buddy (Teams in de buurt / invaller).
create or replace function public.request_join_care_team(
    p_team_id uuid, p_source text default 'search'
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
    v_id uuid;
begin
    if exists (select 1 from care_team_members
               where care_team_id = p_team_id and buddy_id = auth.uid()) then
        raise exception 'je bent al lid van dit team';
    end if;
    -- Eerder afgewezen of geweigerd? Mag later alsnog een verzoek doen.
    delete from care_team_join_requests
     where care_team_id = p_team_id and buddy_id = auth.uid() and status <> 'pending';
    insert into care_team_join_requests (care_team_id, buddy_id, source)
    values (p_team_id, auth.uid(), coalesce(nullif(p_source,''),'search'))
    on conflict do nothing;
    select id into v_id from care_team_join_requests
     where care_team_id = p_team_id and buddy_id = auth.uid() and status = 'pending';
    return v_id;
end;
$$;

-- 8.8 Hulpvrager/familie beslist over een join-verzoek.
create or replace function public.respond_care_join_request(
    p_request_id uuid, p_approve boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
    v_req record;
    v_members int;
begin
    select * into v_req from care_team_join_requests where id = p_request_id;
    if v_req is null then raise exception 'verzoek niet gevonden'; end if;
    if not public.is_care_team_manager(v_req.care_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    if v_req.status <> 'pending' then return; end if;

    if p_approve then
        select count(*) into v_members from care_team_members
         where care_team_id = v_req.care_team_id;
        if v_members >= (select max_size from care_teams where id = v_req.care_team_id) then
            raise exception 'het team zit al vol';
        end if;
        insert into care_team_members (care_team_id, buddy_id, role)
        values (v_req.care_team_id, v_req.buddy_id, 'lid')
        on conflict (care_team_id, buddy_id) do nothing;
    end if;

    update care_team_join_requests
       set status = case when p_approve then 'approved' else 'rejected' end,
           decided_at = now(), decided_by = auth.uid()
     where id = p_request_id;
end;
$$;

-- 8.9 Teamlid verwijderen (hulpvrager/familie, op elk moment).
create or replace function public.remove_care_team_member(p_team_id uuid, p_buddy_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
    if not public.is_care_team_manager(p_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    delete from care_team_members
     where care_team_id = p_team_id and buddy_id = p_buddy_id;
end;
$$;

-- 8.10 claim_care_visit vervangt de fase32-versie:
--      teamleden claimen tot het moment zelf; na de urgente broadcast
--      (30 min vooraf) mag élke buddy claimen (invaller).
create or replace function public.claim_care_visit(p_visit_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
    v_visit record;
    v_is_member boolean;
begin
    select * into v_visit from care_team_visits where id = p_visit_id;
    if v_visit is null then raise exception 'bezoek niet gevonden'; end if;
    if v_visit.claimed_by is not null then raise exception 'al geclaimd'; end if;
    if v_visit.scheduled_at < now() then raise exception 'moment is al voorbij'; end if;

    v_is_member := exists (select 1 from care_team_members
                           where care_team_id = v_visit.care_team_id
                             and buddy_id = auth.uid());
    if not v_is_member and not v_visit.urgent_sent then
        raise exception 'alleen teamleden kunnen dit moment claimen';
    end if;

    update care_team_visits set claimed_by = auth.uid() where id = p_visit_id;
end;
$$;

-- 8.11 request_care_visits vervangt de fase34-versie: geen 2-dagen-regel meer
--      (de 48/24/30-escalatieladder vervangt claim_deadline/released).
create or replace function public.request_care_visits(
    p_team_id uuid, p_category text, p_note text, p_dates timestamptz[]
) returns integer
language plpgsql security definer set search_path = public as $$
declare
    v_allowed boolean;
    v_count int := 0;
    v_date timestamptz;
begin
    select public.is_care_team_manager(p_team_id)
        or exists (select 1 from care_team_members
                   where care_team_id = p_team_id and buddy_id = auth.uid())
      into v_allowed;
    if not v_allowed then raise exception 'geen toegang tot dit team'; end if;
    if array_length(p_dates, 1) is null or array_length(p_dates, 1) > 52 then
        raise exception 'ongeldig aantal datums';
    end if;

    foreach v_date in array p_dates loop
        if v_date > now() then
            insert into care_team_visits (care_team_id, category, scheduled_at, note, claim_deadline)
            values (p_team_id, p_category, v_date, nullif(p_note,''), v_date);
            v_count := v_count + 1;
        end if;
    end loop;
    return v_count;
end;
$$;

-- 8.12 Schema gewijzigd: momenten verwijderen kan alleen de beheerder;
--      geclaimde momenten geven een melding aan de buddy (via cron/edge).
create or replace function public.cancel_care_visit(p_visit_id uuid)
returns uuid  -- buddy die geclaimd had (voor notificatie), of null
language plpgsql security definer set search_path = public as $$
declare
    v_visit record;
    v_name text;
begin
    select * into v_visit from care_team_visits where id = p_visit_id;
    if v_visit is null then return null; end if;
    if not public.is_care_team_manager(v_visit.care_team_id) then
        raise exception 'geen beheerder van dit team';
    end if;
    delete from care_team_visits where id = p_visit_id;

    -- De buddy die dit moment had geclaimd meteen een inboxbericht geven.
    if v_visit.claimed_by is not null then
        select elderly_name into v_name from care_teams where id = v_visit.care_team_id;
        insert into notifications (user_id, kind, title, body, care_team_id)
        values (v_visit.claimed_by, 'schedule_changed',
                'Schema gewijzigd',
                'Het moment van ' || to_char(v_visit.scheduled_at at time zone 'Europe/Amsterdam', 'DD-MM HH24:MI')
                || ' bij ' || coalesce(v_name, 'de hulpvrager') || ' is vervallen.',
                v_visit.care_team_id);
    end if;
    return v_visit.claimed_by;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. Buddy-teams (gamification) archiveren
-- ---------------------------------------------------------------------------

-- Bestaande losse buddy-teams gaan op slot: standen bevroren, niet verwijderd.
update public.teams set archived = true where archived = false;

-- Teams zelf aanmaken kan niet meer (zorgkringen ontstaan rond een hulpvrager).
drop function if exists public.create_team(text, text, text, integer);
drop function if exists public.create_team(text, text, text, integer, text);

-- Bestaande zorgkringen krijgen nette defaults en blijven live.
update public.care_teams set status = 'live' where status is null;

-- ---------------------------------------------------------------------------
-- 10. Grants
-- ---------------------------------------------------------------------------

grant execute on function public.is_care_team_manager(uuid) to authenticated;
grant execute on function public.start_team_formation(text, int, int, uuid) to authenticated;
grant execute on function public.accept_team_invite(uuid) to authenticated;
grant execute on function public.decline_team_invite(uuid) to authenticated;
grant execute on function public.review_team_member(uuid, uuid, boolean) to authenticated;
grant execute on function public.finalize_team_review(uuid) to authenticated;
grant execute on function public.set_team_fallback(uuid, boolean) to authenticated;
grant execute on function public.request_join_care_team(uuid, text) to authenticated;
grant execute on function public.respond_care_join_request(uuid, boolean) to authenticated;
grant execute on function public.remove_care_team_member(uuid, uuid) to authenticated;
grant execute on function public.claim_care_visit(uuid) to authenticated;
grant execute on function public.request_care_visits(uuid, text, text, timestamptz[]) to authenticated;
grant execute on function public.cancel_care_visit(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 11. pg_cron: team-formation en schedule-watchdog elke minuut
-- ---------------------------------------------------------------------------
-- Net als fase22: vul <PROJECT-REF> en <SERVICE_ROLE_KEY> in en draai éénmalig
-- (secrets horen niet in een migratiebestand).
--
-- select cron.schedule(
--     'team-formation-minutely', '* * * * *',
--     $cron$
--     select net.http_post(
--         url     := 'https://<PROJECT-REF>.functions.supabase.co/team-formation',
--         headers := '{"Content-Type":"application/json","Authorization":"Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
--         body    := '{}'::jsonb
--     );
--     $cron$
-- );
--
-- select cron.schedule(
--     'schedule-watchdog-minutely', '* * * * *',
--     $cron$
--     select net.http_post(
--         url     := 'https://<PROJECT-REF>.functions.supabase.co/schedule-watchdog',
--         headers := '{"Content-Type":"application/json","Authorization":"Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
--         body    := '{}'::jsonb
--     );
--     $cron$
-- );
