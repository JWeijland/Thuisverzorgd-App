-- ===========================================================================
-- fase36_teamchat_vervanging.sql
--
-- KAART-HOME & TEAM-UPDATE (juli 2026):
--   1. Teamchat binnen de zorgkring, met twee duidelijk gescheiden kanalen:
--        • 'all'     — het hele team mét de hulpvrager en familie
--        • 'buddies' — alleen de vrijwilligers onderling
--      Lezen direct (RLS per kanaal); versturen via RPC. De pushmeldingen
--      lopen via de edge function notify-team-event (app-invoked).
--   2. Vervanging in het inzetrooster: een buddy die een moment heeft
--      geclaimd kan vervanging vragen; een ander teamlid neemt het over.
--      Het hele team (incl. hulpvrager/familie) krijgt hier bericht van.
--   3. Shift-herinnering: 2 uur vóór een geclaimd moment krijgt de buddy een
--      pushmelding (schedule-watchdog, kolom claim_reminder_sent).
--
-- Idempotent: veilig om opnieuw te draaien.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Teamchat
-- ---------------------------------------------------------------------------

create table if not exists public.care_team_messages (
    id            uuid primary key default gen_random_uuid(),
    care_team_id  uuid not null references public.care_teams(id) on delete cascade,
    sender_id     uuid not null references public.profiles(id) on delete cascade,
    -- Gedenormaliseerd zodat de chat geen join op profiles nodig heeft.
    sender_name   text not null default '',
    -- 'all' = team + hulpvrager/familie; 'buddies' = alleen vrijwilligers.
    channel       text not null default 'all' check (channel in ('all','buddies')),
    body          text not null,
    created_at    timestamptz not null default now()
);
create index if not exists idx_ct_messages_team
    on public.care_team_messages(care_team_id, channel, created_at);

alter table public.care_team_messages enable row level security;

-- Helper: zit de caller als buddy in dit team?
create or replace function public.is_care_team_buddy(p_team_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from care_team_members
        where care_team_id = p_team_id and buddy_id = auth.uid()
    );
$$;

-- Kanaal 'buddies' is uitsluitend voor de vrijwilligers; kanaal 'all' ook
-- voor de hulpvrager en gekoppelde familie (is_care_team_manager, fase35).
drop policy if exists ct_messages_select on public.care_team_messages;
create policy ct_messages_select on public.care_team_messages
    for select to authenticated
    using (
        (channel = 'buddies' and public.is_care_team_buddy(care_team_id))
        or (channel = 'all' and (public.is_care_team_buddy(care_team_id)
                                 or public.is_care_team_manager(care_team_id)))
    );
-- Schrijven uitsluitend via de RPC hieronder (geen insert-policy).

-- Bericht sturen. Retourneert het bericht-id.
create or replace function public.send_care_team_message(
    p_team_id uuid, p_channel text, p_body text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
    v_uid  uuid := auth.uid();
    v_name text;
    v_id   uuid;
begin
    if v_uid is null then raise exception 'Niet ingelogd'; end if;
    if p_channel not in ('all','buddies') then
        raise exception 'Onbekend kanaal';
    end if;
    if coalesce(btrim(p_body), '') = '' then
        raise exception 'Leeg bericht';
    end if;

    if p_channel = 'buddies' then
        if not public.is_care_team_buddy(p_team_id) then
            raise exception 'Alleen vrijwilligers van dit team mogen hier schrijven';
        end if;
    else
        if not (public.is_care_team_buddy(p_team_id)
                or public.is_care_team_manager(p_team_id)) then
            raise exception 'Geen toegang tot deze teamchat';
        end if;
    end if;

    select coalesce(nullif(first_name, ''), 'Iemand') into v_name
      from profiles where id = v_uid;

    insert into public.care_team_messages (care_team_id, sender_id, sender_name, channel, body)
    values (p_team_id, v_uid, coalesce(v_name, 'Iemand'), p_channel, left(btrim(p_body), 2000))
    returning id into v_id;
    return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Vervanging in het inzetrooster
-- ---------------------------------------------------------------------------

alter table public.care_team_visits
    -- De geclaimde buddy zoekt vervanging voor dit moment.
    add column if not exists swap_requested     boolean not null default false,
    add column if not exists swap_reason        text,
    add column if not exists swap_requested_at  timestamptz,
    -- Shift-herinnering (2 uur vooraf) al verstuurd? (schedule-watchdog)
    add column if not exists claim_reminder_sent boolean not null default false;

-- 2.1 Vervanging vragen: alleen de buddy die het moment heeft geclaimd.
create or replace function public.request_visit_swap(p_visit_id uuid, p_reason text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
    v_visit record;
begin
    select * into v_visit from care_team_visits where id = p_visit_id;
    if v_visit is null then raise exception 'Moment niet gevonden'; end if;
    if v_visit.claimed_by is distinct from auth.uid() then
        raise exception 'Alleen de buddy die dit moment heeft opgepakt kan vervanging vragen';
    end if;
    if v_visit.scheduled_at < now() then raise exception 'Dit moment is al voorbij'; end if;

    update care_team_visits
       set swap_requested = true,
           swap_reason = nullif(btrim(coalesce(p_reason, '')), ''),
           swap_requested_at = now()
     where id = p_visit_id;
end;
$$;

-- 2.2 Vervanging intrekken (de buddy doet het toch zelf).
create or replace function public.withdraw_visit_swap(p_visit_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
    update care_team_visits
       set swap_requested = false, swap_reason = null, swap_requested_at = null
     where id = p_visit_id and claimed_by = auth.uid();
end;
$$;

-- 2.3 Vervanging aanbieden/overnemen: een ánder teamlid neemt het moment over.
--     Retourneert de buddy die het moment eerst had (voor de melding).
create or replace function public.take_over_visit(p_visit_id uuid)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
    v_visit record;
    v_prev  uuid;
begin
    select * into v_visit from care_team_visits where id = p_visit_id;
    if v_visit is null then raise exception 'Moment niet gevonden'; end if;
    if not v_visit.swap_requested then
        raise exception 'Voor dit moment is geen vervanging gevraagd';
    end if;
    if v_visit.claimed_by = auth.uid() then
        raise exception 'Je kunt je eigen moment niet overnemen';
    end if;
    if v_visit.scheduled_at < now() then raise exception 'Dit moment is al voorbij'; end if;
    if not public.is_care_team_buddy(v_visit.care_team_id) then
        raise exception 'Alleen teamleden kunnen een moment overnemen';
    end if;

    v_prev := v_visit.claimed_by;
    update care_team_visits
       set claimed_by = auth.uid(),
           swap_requested = false,
           swap_reason = null,
           swap_requested_at = null,
           -- De nieuwe buddy krijgt zijn eigen shift-herinnering weer.
           claim_reminder_sent = false
     where id = p_visit_id;
    return v_prev;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Grants
-- ---------------------------------------------------------------------------

grant execute on function public.is_care_team_buddy(uuid) to authenticated;
grant execute on function public.send_care_team_message(uuid, text, text) to authenticated;
grant execute on function public.request_visit_swap(uuid, text) to authenticated;
grant execute on function public.withdraw_visit_swap(uuid) to authenticated;
grant execute on function public.take_over_visit(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Kaart-home (ouder/familie): veilige view met buddy-druppels
-- ---------------------------------------------------------------------------
-- profiles is bewust alleen self-leesbaar (RLS). Voor de druppels op de kaart
-- is alléén de voornaam + grove locatie + foto-vlag nodig. Deze definer-view
-- geeft precies dat vrij (geen telefoonnummer, adres of andere velden), en
-- alleen voor gescreende buddies (VOG + intake).
create or replace view public.buddy_map_pins as
select bp.id,
       p.first_name,
       bp.latitude,
       bp.longitude,
       bp.current_latitude,
       bp.current_longitude,
       bp.location_updated_at,
       bp.is_available_now,
       (coalesce(bp.avatar_url, '') <> '') as has_avatar
  from public.buddy_profiles bp
  join public.profiles p on p.id = bp.id
 where p.role = 'buddy'
   and bp.vog_valid = true
   and bp.intake_completed = true;

-- Definer-view: bewust langs de RLS van profiles, met een minimale kolomset.
alter view public.buddy_map_pins set (security_invoker = off);
grant select on public.buddy_map_pins to authenticated;
