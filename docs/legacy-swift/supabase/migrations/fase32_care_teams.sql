-- ===========================================================================
-- fase32_care_teams.sql
--
-- Punt 12 (feedback batch 2): ZORG-teams. Een groepje buddies zorgt samen voor
-- 1 specifieke ouder. De aangevraagde hulpbezoeken van die ouder komen in een
-- schema; teamleden claimen bezoeken.
--
--   • Regel 1 (voorrang): niet binnen 1 dag door een teamlid opgepakt → terug
--     naar de gewone buddy-pool.
--   • Regel 2 (deadline): alleen aanvragen die >= 2 dagen vooruit zijn ingepland
--     komen voor het team in aanmerking; korter dag → direct de pool.
--
-- Dit is de datalaag + kern-RPC's. De app dwingt regel 1 en regel 2 af (zie
-- CareTeam-logica); in productie hoort daar ook een geplande job bij die
-- verlopen, niet-geclaimde bezoeken vrijgeeft aan de pool (release-RPC hieronder).
-- ===========================================================================

create table if not exists public.care_teams (
    id          uuid primary key default gen_random_uuid(),
    name        text not null,
    elderly_id  uuid references public.profiles(id) on delete set null,
    elderly_name text,
    accent      text default 'teal',
    invite_code text,
    created_by  uuid references public.profiles(id) on delete set null,
    created_at  timestamptz not null default now()
);

create table if not exists public.care_team_members (
    id           uuid primary key default gen_random_uuid(),
    care_team_id uuid not null references public.care_teams(id) on delete cascade,
    buddy_id     uuid not null references public.profiles(id) on delete cascade,
    role         text not null default 'lid' check (role in ('eigenaar','lid')),
    joined_at    timestamptz not null default now(),
    unique (care_team_id, buddy_id)
);
create index if not exists idx_care_members_team  on public.care_team_members(care_team_id);
create index if not exists idx_care_members_buddy on public.care_team_members(buddy_id);

create table if not exists public.care_team_visits (
    id           uuid primary key default gen_random_uuid(),
    care_team_id uuid not null references public.care_teams(id) on delete cascade,
    category     text not null,
    scheduled_at timestamptz not null,
    note         text,
    claimed_by   uuid references public.profiles(id) on delete set null,
    -- Optionele koppeling naar de echte hulpvraag (tasks) zodra geclaimd.
    task_id      uuid,
    -- Regel 1: teamleden hebben tot deze tijd voorrang.
    claim_deadline timestamptz not null default (now() + interval '1 day'),
    -- Regel 1 (fallback): vrijgegeven aan de gewone buddy-pool.
    released     boolean not null default false,
    created_at   timestamptz not null default now()
);
create index if not exists idx_care_visits_team on public.care_team_visits(care_team_id, scheduled_at);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.care_teams        enable row level security;
alter table public.care_team_members enable row level security;
alter table public.care_team_visits  enable row level security;

drop policy if exists "Zorg-teams zichtbaar" on public.care_teams;
create policy "Zorg-teams zichtbaar" on public.care_teams
    for select using (auth.role() = 'authenticated');

drop policy if exists "Zorg-team aanmaken" on public.care_teams;
create policy "Zorg-team aanmaken" on public.care_teams
    for insert with check (created_by = (select auth.uid()));

drop policy if exists "Zorg-teamleden zichtbaar" on public.care_team_members;
create policy "Zorg-teamleden zichtbaar" on public.care_team_members
    for select using (auth.role() = 'authenticated');

drop policy if exists "Eigen zorg-lidmaatschap" on public.care_team_members;
create policy "Eigen zorg-lidmaatschap" on public.care_team_members
    for insert with check (buddy_id = (select auth.uid()));

drop policy if exists "Zorg-bezoeken zichtbaar" on public.care_team_visits;
create policy "Zorg-bezoeken zichtbaar" on public.care_team_visits
    for select using (auth.role() = 'authenticated');

-- ---------------------------------------------------------------------------
-- RPC's
-- ---------------------------------------------------------------------------

-- Zorg-team aanmaken + de maker als eigenaar toevoegen (atomair).
create or replace function public.create_care_team(
    p_name text, p_elderly_id uuid, p_elderly_name text, p_accent text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid := auth.uid();
    v_id  uuid;
    v_code text := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
begin
    if v_uid is null then raise exception 'Niet ingelogd'; end if;
    insert into public.care_teams (name, elderly_id, elderly_name, accent, invite_code, created_by)
    values (p_name, p_elderly_id, p_elderly_name, coalesce(p_accent, 'teal'), v_code, v_uid)
    returning id into v_id;
    insert into public.care_team_members (care_team_id, buddy_id, role)
    values (v_id, v_uid, 'eigenaar');
    return v_id;
end;
$$;
grant execute on function public.create_care_team(text, uuid, text, text) to authenticated;

-- Lid worden van een zorg-team (open voor v1; in productie evt. met goedkeuring).
create or replace function public.join_care_team(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_uid uuid := auth.uid();
begin
    if v_uid is null then raise exception 'Niet ingelogd'; end if;
    insert into public.care_team_members (care_team_id, buddy_id, role)
    values (p_team_id, v_uid, 'lid')
    on conflict (care_team_id, buddy_id) do nothing;
end;
$$;
grant execute on function public.join_care_team(uuid) to authenticated;

-- Een bezoek claimen: alleen een teamlid, alleen als het nog vrij is en de
-- voorrangsdeadline (regel 1) nog niet is verstreken.
create or replace function public.claim_care_visit(p_visit_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid := auth.uid();
    v_team uuid;
begin
    if v_uid is null then raise exception 'Niet ingelogd'; end if;
    select care_team_id into v_team from public.care_team_visits where id = p_visit_id;
    if v_team is null then raise exception 'Bezoek bestaat niet'; end if;
    if not exists (select 1 from public.care_team_members
                   where care_team_id = v_team and buddy_id = v_uid) then
        raise exception 'Alleen teamleden kunnen bezoeken oppakken';
    end if;
    update public.care_team_visits
       set claimed_by = v_uid
     where id = p_visit_id
       and claimed_by is null
       and released = false
       and now() <= claim_deadline;
    if not found then raise exception 'Dit bezoek is niet meer vrij'; end if;
end;
$$;
grant execute on function public.claim_care_visit(uuid) to authenticated;

-- Regel 1 (fallback): geef verlopen, niet-geclaimde bezoeken vrij aan de pool.
-- In productie aan te roepen via een geplande job (bijv. pg_cron).
create or replace function public.release_overdue_care_visits()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.care_team_visits
       set released = true
     where claimed_by is null
       and released = false
       and now() > claim_deadline;
end;
$$;
grant execute on function public.release_overdue_care_visits() to authenticated;
