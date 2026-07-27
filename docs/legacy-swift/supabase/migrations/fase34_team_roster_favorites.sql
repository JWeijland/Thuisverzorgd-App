-- ===========================================================================
-- fase34_team_roster_favorites.sql
--
-- 1) Vaste buddy persoonlijker:
--    • favorite_buddies krijgt een gedenormaliseerde elderly_name, zodat de
--      buddy op zijn profiel kan zien wíe hem als vaste buddy koos ("Vaste
--      buddy van Riet") zonder join op profiles.
--    • De edge function notify-favorite-buddy leest deze rij en stuurt de
--      buddy een push + inbox-bericht (kind: favorite_buddy).
--
-- 2) Team goed maken (sporadisch + inzetrooster):
--    • RPC request_care_visits: de ouder van het team (of een gekoppeld
--      familielid, of een teamlid) zet één of meer hulpbezoeken in het
--      inzetrooster van het zorg-team. Sporadisch = 1 datum; periodiek =
--      alle datums uit het herhaalschema (max 52 per aanroep).
--    • Regel 1 (voorrangsdag) blijft gelden via claim_deadline (default 1 dag).
--    • Regel 2 (>= 2 dagen vooruit) wordt hier ook server-side afgedwongen.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1) Vaste buddy: naam van de kiezende ouder erbij
-- ---------------------------------------------------------------------------
alter table public.favorite_buddies
    add column if not exists elderly_name text not null default '';

create index if not exists idx_favorite_buddies_buddy
    on public.favorite_buddies(buddy_id);

-- ---------------------------------------------------------------------------
-- 2) Inzetrooster: bezoeken aanvragen bij het eigen zorg-team
-- ---------------------------------------------------------------------------
create or replace function public.request_care_visits(
    p_team_id  uuid,
    p_category text,
    p_note     text,
    p_dates    timestamptz[]
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid     uuid := auth.uid();
    v_elderly uuid;
    v_count   integer := 0;
    v_date    timestamptz;
begin
    if v_uid is null then raise exception 'Niet ingelogd'; end if;
    if p_dates is null or array_length(p_dates, 1) is null then
        raise exception 'Geen datums opgegeven';
    end if;
    if array_length(p_dates, 1) > 52 then
        raise exception 'Maximaal 52 bezoeken per aanvraag';
    end if;

    select elderly_id into v_elderly from public.care_teams where id = p_team_id;
    if not found then raise exception 'Team bestaat niet'; end if;

    -- Alleen de ouder van het team, een gekoppeld familielid of een teamlid.
    if not (
        (v_elderly is not null and v_elderly = v_uid)
        or exists (select 1 from public.family_elderly_links
                    where family_id = v_uid and elderly_id = v_elderly)
        or exists (select 1 from public.care_team_members
                    where care_team_id = p_team_id and buddy_id = v_uid)
    ) then
        raise exception 'Geen toegang tot dit team';
    end if;

    foreach v_date in array p_dates loop
        -- Regel 2: alleen bezoeken die 2 dagen of meer vooruit zijn ingepland.
        if v_date < now() + interval '2 days' then
            continue;
        end if;
        insert into public.care_team_visits (care_team_id, category, scheduled_at, note)
        values (p_team_id, p_category, v_date, nullif(p_note, ''));
        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;
grant execute on function public.request_care_visits(uuid, text, text, timestamptz[]) to authenticated;
