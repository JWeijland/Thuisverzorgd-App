-- ============================================================================
-- Fase 21 — Familie/beheerder dient hulpvraag in namens een cliënt
-- ----------------------------------------------------------------------------
-- De RLS-policy laat alleen de cliënt zélf een taak inschieten
-- (elderly_id = auth.uid()). Hierdoor bereikten verzoeken van familie/admin de
-- buddy-kaart niet in live-modus. Deze SECURITY DEFINER-RPC laat een
-- GEKOPPELD familielid (family_elderly_links) of een ADMIN een hulpvraag voor
-- de cliënt aanmaken. De locatie wordt server-side van de CLIËNT genomen
-- (elderly_profiles), zodat de druppel altijd op het adres van de hulpvrager
-- staat — nooit op dat van de aanvrager.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

create or replace function public.create_task_for_elderly(
    p_elderly_id   uuid,
    p_category     text,
    p_timing_type  text,
    p_scheduled_at timestamptz,
    p_note         text
)
returns public.tasks
language plpgsql
security definer
set search_path = public
as $$
declare
    v_caller   uuid := (select auth.uid());
    v_is_admin boolean;
    v_linked   boolean;
    v_first    text;
    v_lat      double precision;
    v_lon      double precision;
    v_row      public.tasks;
begin
    if v_caller is null then
        raise exception 'Niet ingelogd.' using errcode = 'insufficient_privilege';
    end if;

    select exists(select 1 from public.profiles p
                  where p.id = v_caller and p.role = 'admin') into v_is_admin;
    select exists(select 1 from public.family_elderly_links fel
                  where fel.family_id = v_caller and fel.elderly_id = p_elderly_id) into v_linked;

    if not (v_is_admin or v_linked) then
        raise exception 'Geen koppeling met deze cliënt.' using errcode = 'insufficient_privilege';
    end if;

    -- Weergavenaam + locatie van de CLIËNT (niet van de aanvrager).
    select pr.first_name, ep.latitude, ep.longitude
      into v_first, v_lat, v_lon
      from public.profiles pr
      left join public.elderly_profiles ep on ep.id = pr.id
     where pr.id = p_elderly_id;

    insert into public.tasks
        (elderly_id, category, timing_type, scheduled_at, note,
         elderly_first_name, elderly_latitude, elderly_longitude)
    values
        (p_elderly_id, p_category::task_category,
         coalesce(p_timing_type, 'now')::task_timing_type, p_scheduled_at,
         coalesce(p_note, ''), v_first, v_lat, v_lon)
    returning * into v_row;

    return v_row;
end;
$$;

grant execute on function public.create_task_for_elderly(uuid, text, text, timestamptz, text) to authenticated;
