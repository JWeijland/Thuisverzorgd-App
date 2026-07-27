-- ============================================================================
-- Fase 14 — Gamification: competities & teams
-- ----------------------------------------------------------------------------
-- Buddies verdienen punten met afgeronde hulpvragen e.d. (zie point_rules).
--  * COMPETITIE: individueel. Buddy schrijft zich vóór de deadline in (max 1
--    actieve competitie). De competitie loopt een aantal weken; daarna worden
--    de top 3 beloond (nr. 1 grootste prijs, aflopend). 10–50 deelnemers.
--  * TEAM: met je maatjes (ook buddies) samen punten halen → teamranglijst +
--    team-uitje zodra het puntendoel is gehaald.
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- COMPETITIES
-- ---------------------------------------------------------------------------
create table if not exists public.competitions (
    id                    uuid primary key default gen_random_uuid(),
    name                  text not null,
    tagline               text,
    icon                  text,
    accent                text,                       -- hex voor de UI-tint
    status                text not null default 'inschrijving'
                          check (status in ('inschrijving','loopt','afgelopen')),
    registration_deadline timestamptz,                -- inschrijven kan tot hier
    starts_at             timestamptz,
    ends_at               timestamptz,
    duration_weeks        int,

    
    min_participants      int not null default 10,
    max_participants      int not null default 50,
    -- Top 3 prijzen (aflopend in waarde: 1 > 2 > 3)
    prize_1_title         text,
    prize_2_title         text,
    prize_3_title         text,
    created_at            timestamptz not null default now()
);

create table if not exists public.competition_participants (
    id             uuid primary key default gen_random_uuid(),
    competition_id uuid not null references public.competitions(id) on delete cascade,
    buddy_id       uuid not null references public.profiles(id) on delete cascade,
    points         int  not null default 0,
    joined_at      timestamptz not null default now(),
    unique (competition_id, buddy_id)
);
create index if not exists idx_comp_part_competition on public.competition_participants(competition_id);
create index if not exists idx_comp_part_buddy       on public.competition_participants(buddy_id);

-- Max 1 actieve competitie per buddy (inschrijving of lopend).
create or replace function public.enforce_single_active_competition()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if exists (
        select 1
        from public.competition_participants cp
        join public.competitions c on c.id = cp.competition_id
        where cp.buddy_id = new.buddy_id
          and cp.competition_id <> new.competition_id
          and c.status in ('inschrijving','loopt')
    ) then
        raise exception 'Je kunt aan maximaal 1 actieve competitie meedoen.'
            using errcode = 'check_violation';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_single_active_competition on public.competition_participants;
create trigger trg_single_active_competition
    before insert on public.competition_participants
    for each row execute function public.enforce_single_active_competition();

-- Capaciteitsgrens (max_participants) afdwingen.
create or replace function public.enforce_competition_capacity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    cap   int;
    taken int;
begin
    select max_participants into cap from public.competitions where id = new.competition_id;
    select count(*) into taken from public.competition_participants where competition_id = new.competition_id;
    if cap is not null and taken >= cap then
        raise exception 'Deze competitie zit vol (max % deelnemers).', cap
            using errcode = 'check_violation';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_competition_capacity on public.competition_participants;
create trigger trg_competition_capacity
    before insert on public.competition_participants
    for each row execute function public.enforce_competition_capacity();

-- ---------------------------------------------------------------------------
-- TEAMS
-- ---------------------------------------------------------------------------
create table if not exists public.teams (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    icon          text,
    accent        text,
    outing_target int  not null default 1500,         -- punten nodig voor team-uitje
    created_by    uuid references public.profiles(id) on delete set null,
    created_at    timestamptz not null default now()
);

create table if not exists public.team_members (
    id        uuid primary key default gen_random_uuid(),
    team_id   uuid not null references public.teams(id) on delete cascade,
    buddy_id  uuid not null references public.profiles(id) on delete cascade,
    points    int  not null default 0,
    role      text not null default 'lid' check (role in ('eigenaar','lid')),
    joined_at timestamptz not null default now(),
    unique (team_id, buddy_id)
);
create index if not exists idx_team_members_team  on public.team_members(team_id);
create index if not exists idx_team_members_buddy on public.team_members(buddy_id);

-- ---------------------------------------------------------------------------
-- PUNTEN-LEDGER (bron van alle punten; competitie/team-punten worden hieruit afgeleid)
-- ---------------------------------------------------------------------------
create table if not exists public.point_events (
    id             uuid primary key default gen_random_uuid(),
    buddy_id       uuid not null references public.profiles(id) on delete cascade,
    kind           text not null,                     -- verwijst naar point_rules.kind
    points         int  not null,
    task_id        uuid,
    competition_id uuid references public.competitions(id) on delete set null,
    team_id        uuid references public.teams(id)        on delete set null,
    created_at     timestamptz not null default now()
);
create index if not exists idx_point_events_buddy on public.point_events(buddy_id);

-- ---------------------------------------------------------------------------
-- PUNTENREGELS — één bron van waarheid (ook getoond in de app onder "Spelregels")
-- ---------------------------------------------------------------------------
create table if not exists public.point_rules (
    kind   text primary key,
    title  text not null,
    detail text,
    points int  not null,
    icon   text,
    sort   int  not null default 0
);

insert into public.point_rules (kind, title, detail, points, icon, sort) values
    ('task_completed', 'Hulpvraag afgerond',     'Voor elke voltooide hulpvraag',          50, 'checkmark.circle.fill', 1),
    ('five_star',      '5-sterren beoordeling',  'Bonus bij een topbeoordeling',           20, 'star.fill',             2),
    ('urgent',         'Spoedhulp',              'Een hulpvraag binnen het uur opgepakt',  15, 'bolt.fill',             3),
    ('evening_weekend','Avond of weekend',       'Hulp buiten kantooruren',                10, 'moon.stars.fill',       4),
    ('weekly_streak',  'Wekelijkse streak',      'Elke week minstens één hulpvraag',       25, 'flame.fill',            5),
    ('referral',       'Maatje aangebracht',     'Een nieuwe buddy via jou actief',        40, 'person.2.fill',         6)
on conflict (kind) do update
    set title = excluded.title, detail = excluded.detail,
        points = excluded.points, icon = excluded.icon, sort = excluded.sort;

-- ---------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------------
alter table public.competitions             enable row level security;
alter table public.competition_participants enable row level security;
alter table public.teams                    enable row level security;
alter table public.team_members             enable row level security;
alter table public.point_events             enable row level security;
alter table public.point_rules              enable row level security;

-- Competities: iedereen (ingelogd) mag bekijken; alleen admin beheert.
drop policy if exists "Competities zichtbaar" on public.competitions;
create policy "Competities zichtbaar" on public.competitions
    for select using (auth.role() = 'authenticated');

drop policy if exists "Admin beheert competities" on public.competitions;
create policy "Admin beheert competities" on public.competitions
    for all using (
        exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    ) with check (
        exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    );

-- Deelnames: zichtbaar voor ingelogden (ranglijst); je beheert je eigen deelname.
drop policy if exists "Deelnames zichtbaar" on public.competition_participants;
create policy "Deelnames zichtbaar" on public.competition_participants
    for select using (auth.role() = 'authenticated');

drop policy if exists "Eigen deelname toevoegen" on public.competition_participants;
create policy "Eigen deelname toevoegen" on public.competition_participants
    for insert with check (buddy_id = (select auth.uid()));

drop policy if exists "Eigen deelname verwijderen" on public.competition_participants;
create policy "Eigen deelname verwijderen" on public.competition_participants
    for delete using (buddy_id = (select auth.uid()));

-- Teams: zichtbaar voor ingelogden; maker mag beheren.
drop policy if exists "Teams zichtbaar" on public.teams;
create policy "Teams zichtbaar" on public.teams
    for select using (auth.role() = 'authenticated');

drop policy if exists "Team aanmaken" on public.teams;
create policy "Team aanmaken" on public.teams
    for insert with check (created_by = (select auth.uid()));

drop policy if exists "Team beheren door maker" on public.teams;
create policy "Team beheren door maker" on public.teams
    for update using (created_by = (select auth.uid()));

-- Teamleden: zichtbaar voor ingelogden; je beheert je eigen lidmaatschap.
drop policy if exists "Teamleden zichtbaar" on public.team_members;
create policy "Teamleden zichtbaar" on public.team_members
    for select using (auth.role() = 'authenticated');

drop policy if exists "Eigen lidmaatschap toevoegen" on public.team_members;
create policy "Eigen lidmaatschap toevoegen" on public.team_members
    for insert with check (buddy_id = (select auth.uid()));

drop policy if exists "Eigen lidmaatschap verwijderen" on public.team_members;
create policy "Eigen lidmaatschap verwijderen" on public.team_members
    for delete using (buddy_id = (select auth.uid()));

-- Punten-ledger: je ziet alleen je eigen events; schrijven gebeurt server-side
-- (geen client-insert policy → alleen service-role/SECURITY DEFINER mag toevoegen).
drop policy if exists "Eigen punten zichtbaar" on public.point_events;
create policy "Eigen punten zichtbaar" on public.point_events
    for select using (buddy_id = (select auth.uid()));

-- Puntenregels: leesbaar voor iedereen die is ingelogd.
drop policy if exists "Puntenregels zichtbaar" on public.point_rules;
create policy "Puntenregels zichtbaar" on public.point_rules
    for select using (auth.role() = 'authenticated');
