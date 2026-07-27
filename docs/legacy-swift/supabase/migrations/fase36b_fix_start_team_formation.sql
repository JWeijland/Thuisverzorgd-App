-- ===========================================================================
-- fase36b_fix_start_team_formation.sql
--
-- Bugfix, gevonden met de 20-gebruikers-simulatie (sim-users):
-- start_team_formation (fase35) verwees naar p.full_name, maar profiles
-- heeft first_name/last_name. Daardoor faalde het starten van teamvorming
-- ("Start mijn team") in de live app met "column p.full_name does not exist".
--
-- Zelfde functie, nu op first_name. Idempotent (create or replace).
-- ===========================================================================

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

    select coalesce(nullif(btrim(p.first_name), ''), 'Hulpvrager'),
           coalesce(nullif(trim(regexp_replace(coalesce(e.address, ''), '^[^,]*,', '')), ''), ''),
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
               elderly_name = v_first,
               approx_latitude = round(v_lat::numeric, 2),
               approx_longitude = round(v_lng::numeric, 2),
               area = v_area
         where id = v_team;
    end if;

    update elderly_profiles set team_mode = 'team' where id = v_elderly;
    return v_team;
end;
$$;

grant execute on function public.start_team_formation(text, int, int, uuid) to authenticated;
