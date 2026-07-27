-- ============================================================================
-- Fase 19 — Teamprijs bij het aanmaken
-- ----------------------------------------------------------------------------
-- Bij het starten van een team verbindt de maker er een PRIJS aan, die wordt
-- uitgedeeld zodra het puntendoel (outing_target) is behaald. We bewaren de
-- prijs als tekst op de teams-tabel en breiden create_team uit met de prijs.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

alter table public.teams
    add column if not exists prize_title text;

-- create_team krijgt een extra parameter (p_prize_title). De oude 4-argument-
-- versie uit fase18 verwijderen we, zodat er geen dubbele/overladen functie blijft.
drop function if exists public.create_team(text, text, text, int);

create or replace function public.create_team(
    p_name text, p_icon text, p_accent text, p_outing_target int, p_prize_title text
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

    insert into public.teams (name, icon, accent, outing_target, prize_title, created_by)
    values (p_name, coalesce(p_icon, ''), p_accent,
            coalesce(p_outing_target, 1500), p_prize_title, v_uid)
    returning id into v_team_id;

    insert into public.team_members (team_id, buddy_id, role)
    values (v_team_id, v_uid, 'eigenaar');

    return v_team_id;
end;
$$;
