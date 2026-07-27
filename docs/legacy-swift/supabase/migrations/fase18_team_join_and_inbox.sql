-- ============================================================================
-- Fase 18 — Team-join met goedkeuring + berichten-inbox
-- ----------------------------------------------------------------------------
-- Bouwt voort op fase14 (teams, team_members). Buddies kunnen nu een
-- JOIN-VERZOEK sturen voor een team; de teameigenaar moet dit goedkeuren of
-- afwijzen. Elke gebeurtenis (verzoek, goedkeuring, afwijzing) levert een
-- bericht op in de in-app INBOX (tabel notifications).
--
-- Lidmaatschap ontstaat voortaan UITSLUITEND via goedkeuring: de oude policy
-- waarmee iedereen zichzelf direct als lid kon invoegen wordt verwijderd. Alle
-- mutaties lopen via SECURITY DEFINER-RPC's met ingebouwde eigenaarscontrole.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- JOIN-VERZOEKEN
-- ---------------------------------------------------------------------------
create table if not exists public.team_join_requests (
    id          uuid primary key default gen_random_uuid(),
    team_id     uuid not null references public.teams(id)    on delete cascade,
    buddy_id    uuid not null references public.profiles(id) on delete cascade,
    status      text not null default 'pending'
                check (status in ('pending','approved','rejected')),
    created_at  timestamptz not null default now(),
    resolved_at timestamptz,
    resolved_by uuid references public.profiles(id) on delete set null
);
create index if not exists idx_join_req_team  on public.team_join_requests(team_id);
create index if not exists idx_join_req_buddy on public.team_join_requests(buddy_id);

-- Geen dubbele openstaande verzoeken voor hetzelfde team.
create unique index if not exists uq_join_req_pending
    on public.team_join_requests(team_id, buddy_id)
    where status = 'pending';

-- ---------------------------------------------------------------------------
-- INBOX (in-app berichten/meldingen)
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid not null references public.profiles(id) on delete cascade,  -- ontvanger
    kind       text not null,                       -- team_join_request | team_join_approved | team_join_rejected
    title      text not null,
    body       text,
    team_id    uuid references public.teams(id)              on delete cascade,
    request_id uuid references public.team_join_requests(id) on delete cascade,
    read       boolean not null default false,
    created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- RPC'S — alle mutaties met eigenaars-/lidmaatschapscontrole
-- ---------------------------------------------------------------------------

-- Team aanmaken: maakt het team + voegt de maker als eigenaar toe (atomair).
create or replace function public.create_team(
    p_name text, p_icon text, p_accent text, p_outing_target int
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid     uuid := (select auth.uid());
    v_team_id uuid;
begin
    if v_uid is null then
        raise exception 'Niet ingelogd.' using errcode = 'insufficient_privilege';
    end if;

    insert into public.teams (name, icon, accent, outing_target, created_by)
    values (p_name, coalesce(p_icon, ''), p_accent, coalesce(p_outing_target, 1500), v_uid)
    returning id into v_team_id;

    insert into public.team_members (team_id, buddy_id, role)
    values (v_team_id, v_uid, 'eigenaar');

    return v_team_id;
end;
$$;

-- Join-verzoek sturen: guard tegen dubbel lidmaatschap/verzoek; verwittigt de eigenaar.
create or replace function public.request_to_join_team(p_team_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid     uuid := (select auth.uid());
    v_owner   uuid;
    v_team    text;
    v_naam    text;
    v_req_id  uuid;
begin
    if v_uid is null then
        raise exception 'Niet ingelogd.' using errcode = 'insufficient_privilege';
    end if;

    select created_by, name into v_owner, v_team from public.teams where id = p_team_id;
    if v_owner is null then
        raise exception 'Team bestaat niet.' using errcode = 'no_data_found';
    end if;

    if exists (select 1 from public.team_members where team_id = p_team_id and buddy_id = v_uid) then
        raise exception 'Je bent al lid van dit team.' using errcode = 'unique_violation';
    end if;

    if exists (select 1 from public.team_join_requests
               where team_id = p_team_id and buddy_id = v_uid and status = 'pending') then
        raise exception 'Je hebt al een openstaand verzoek voor dit team.' using errcode = 'unique_violation';
    end if;

    insert into public.team_join_requests (team_id, buddy_id)
    values (p_team_id, v_uid)
    returning id into v_req_id;

    select coalesce(nullif(trim(first_name || ' ' || coalesce(last_name, '')), ''), 'Een buddy')
      into v_naam from public.profiles where id = v_uid;

    insert into public.notifications (user_id, kind, title, body, team_id, request_id)
    values (v_owner, 'team_join_request',
            v_naam || ' wil bij ' || v_team || ' komen',
            'Tik om goed te keuren of af te wijzen.', p_team_id, v_req_id);

    return v_req_id;
end;
$$;

-- Verzoek goedkeuren: alleen de teameigenaar; voegt lid toe + verwittigt aanvrager.
create or replace function public.approve_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid     uuid := (select auth.uid());
    v_team_id uuid;
    v_buddy   uuid;
    v_status  text;
    v_owner   uuid;
    v_team    text;
begin
    select r.team_id, r.buddy_id, r.status, t.created_by, t.name
      into v_team_id, v_buddy, v_status, v_owner, v_team
      from public.team_join_requests r
      join public.teams t on t.id = r.team_id
     where r.id = p_request_id;

    if v_team_id is null then
        raise exception 'Verzoek bestaat niet.' using errcode = 'no_data_found';
    end if;
    if v_owner is distinct from v_uid then
        raise exception 'Alleen de teameigenaar kan dit verzoek beoordelen.' using errcode = 'insufficient_privilege';
    end if;
    if v_status <> 'pending' then
        raise exception 'Dit verzoek is al afgehandeld.' using errcode = 'check_violation';
    end if;

    update public.team_join_requests
       set status = 'approved', resolved_at = now(), resolved_by = v_uid
     where id = p_request_id;

    insert into public.team_members (team_id, buddy_id, role)
    values (v_team_id, v_buddy, 'lid')
    on conflict (team_id, buddy_id) do nothing;

    insert into public.notifications (user_id, kind, title, body, team_id, request_id)
    values (v_buddy, 'team_join_approved',
            'Je bent toegelaten tot ' || v_team || '!',
            'Veel plezier met je nieuwe team.', v_team_id, p_request_id);
end;
$$;

-- Verzoek afwijzen: alleen de teameigenaar; verwittigt aanvrager.
create or replace function public.reject_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid     uuid := (select auth.uid());
    v_team_id uuid;
    v_buddy   uuid;
    v_status  text;
    v_owner   uuid;
    v_team    text;
begin
    select r.team_id, r.buddy_id, r.status, t.created_by, t.name
      into v_team_id, v_buddy, v_status, v_owner, v_team
      from public.team_join_requests r
      join public.teams t on t.id = r.team_id
     where r.id = p_request_id;

    if v_team_id is null then
        raise exception 'Verzoek bestaat niet.' using errcode = 'no_data_found';
    end if;
    if v_owner is distinct from v_uid then
        raise exception 'Alleen de teameigenaar kan dit verzoek beoordelen.' using errcode = 'insufficient_privilege';
    end if;
    if v_status <> 'pending' then
        raise exception 'Dit verzoek is al afgehandeld.' using errcode = 'check_violation';
    end if;

    update public.team_join_requests
       set status = 'rejected', resolved_at = now(), resolved_by = v_uid
     where id = p_request_id;

    insert into public.notifications (user_id, kind, title, body, team_id, request_id)
    values (v_buddy, 'team_join_rejected',
            'Je verzoek voor ' || v_team || ' is afgewezen',
            null, v_team_id, p_request_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------------
alter table public.team_join_requests enable row level security;
alter table public.notifications      enable row level security;

-- Join-verzoeken zichtbaar voor de aanvrager én de teameigenaar. Schrijven
-- gebeurt uitsluitend via de SECURITY DEFINER-RPC's hierboven (geen insert/
-- update-policy → de RPC's omzeilen RLS legitiem).
drop policy if exists "Join-verzoeken zichtbaar" on public.team_join_requests;
create policy "Join-verzoeken zichtbaar" on public.team_join_requests
    for select using (
        buddy_id = (select auth.uid())
        or exists (
            select 1 from public.teams t
            where t.id = team_id and t.created_by = (select auth.uid())
        )
    );

-- Inbox: je ziet/beheert alleen je eigen berichten. Insert alleen via RPC.
drop policy if exists "Eigen berichten zichtbaar" on public.notifications;
create policy "Eigen berichten zichtbaar" on public.notifications
    for select using (user_id = (select auth.uid()));

drop policy if exists "Eigen berichten bijwerken" on public.notifications;
create policy "Eigen berichten bijwerken" on public.notifications
    for update using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

drop policy if exists "Eigen berichten verwijderen" on public.notifications;
create policy "Eigen berichten verwijderen" on public.notifications
    for delete using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- AANPASSING fase14: lidmaatschap niet langer zelf-invoegbaar.
-- Lid worden kan voortaan alleen via approve_join_request (eigenaar) of
-- create_team (maker als eigenaar). "Team verlaten" (delete self) blijft.
-- ---------------------------------------------------------------------------
drop policy if exists "Eigen lidmaatschap toevoegen" on public.team_members;
