-- ============================================================================
-- Fase 20 — Prijzen worden door de beheerder bepaald (niet door de gebruiker)
-- ----------------------------------------------------------------------------
-- Teamprijzen vormen een LADDER: per puntendoel hoort één prijs. Hoe hoger het
-- doel, hoe mooier de prijs. De beheerder beheert deze ladder (team_prizes).
-- Bij het aanmaken van een team kiest de maker alleen het puntendoel; de prijs
-- wordt automatisch afgeleid uit de ladder en als snapshot op het team bewaard.
--
-- Competitieprijzen blijven per competitie ingesteld (plek 1/2/3 — fase14).
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- TEAM-PRIJZENLADDER (beheerd door de admin)
-- ---------------------------------------------------------------------------
create table if not exists public.team_prizes (
    id               uuid primary key default gen_random_uuid(),
    points_threshold int  not null unique,        -- puntendoel waaraan de prijs hangt
    title            text not null,                -- de prijs
    icon             text,                         -- SF Symbol voor de UI
    created_at       timestamptz not null default now()
);
create index if not exists idx_team_prizes_threshold on public.team_prizes(points_threshold);

-- Standaard-ladder (alleen invoegen als die nog niet bestaat).
insert into public.team_prizes (points_threshold, title, icon) values
    (1000, 'Bioscoopbon voor het team',  'popcorn.fill'),
    (1500, 'High tea met het team',      'cup.and.saucer.fill'),
    (2000, 'Uit eten met het team',      'fork.knife'),
    (3000, 'Weekendje weg met het team', 'suitcase.fill')
on conflict (points_threshold) do nothing;

-- ---------------------------------------------------------------------------
-- RLS — iedereen leest, alleen admin beheert
-- ---------------------------------------------------------------------------
alter table public.team_prizes enable row level security;

drop policy if exists "Teamprijzen zichtbaar" on public.team_prizes;
create policy "Teamprijzen zichtbaar" on public.team_prizes
    for select using (auth.role() = 'authenticated');

drop policy if exists "Admin beheert teamprijzen" on public.team_prizes;
create policy "Admin beheert teamprijzen" on public.team_prizes
    for all using (
        exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    ) with check (
        exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    );

-- ---------------------------------------------------------------------------
-- create_team: prijs niet meer als parameter, maar afgeleid uit de ladder.
-- De fase19-versie (met p_prize_title) verwijderen we.
-- ---------------------------------------------------------------------------
drop function if exists public.create_team(text, text, text, int, text);

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
    v_target  int  := coalesce(p_outing_target, 1500);
    v_prize   text;
begin
    if v_uid is null then
        raise exception 'Niet ingelogd.' using errcode = 'insufficient_privilege';
    end if;

    -- Hoogste prijs-tier die binnen het gekozen doel valt.
    select title into v_prize
      from public.team_prizes
     where points_threshold <= v_target
     order by points_threshold desc
     limit 1;

    insert into public.teams (name, icon, accent, outing_target, prize_title, created_by)
    values (p_name, coalesce(p_icon, ''), p_accent, v_target, v_prize, v_uid)
    returning id into v_team_id;

    insert into public.team_members (team_id, buddy_id, role)
    values (v_team_id, v_uid, 'eigenaar');

    return v_team_id;
end;
$$;
