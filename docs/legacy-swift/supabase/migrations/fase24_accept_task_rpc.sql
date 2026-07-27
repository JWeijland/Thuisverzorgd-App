-- ============================================================================
-- Fase 24 — Atomisch een hulpvraag aannemen (race-safe voor veel gebruikers)
-- ----------------------------------------------------------------------------
-- Probleem: de RLS UPDATE-policy op `tasks` is
--   assigned_buddy_id = auth.uid() OR elderly_id = auth.uid()
-- Een OPEN taak heeft assigned_buddy_id = NULL, dus een buddy die hem wil
-- aannemen voldoet aan geen van beide → de UPDATE raakt 0 rijen (RLS blokkeert,
-- zónder fout). Gevolg: de taak bleef in de database op 'open' staan en de
-- hulpvrager zag nooit "aangenomen".
--
-- Deze SECURITY DEFINER-RPC claimt de taak ATOMISCH: alleen de eerste buddy die
-- 'm pakt wint dankzij `where status = 'open'`. Twee buddies kunnen dus nooit
-- dezelfde hulpvraag aannemen — cruciaal zodra er veel buddies tegelijk kijken.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

create or replace function public.accept_task(
    p_task_id     uuid,
    p_eta_minutes int
)
returns public.tasks
language plpgsql
security definer
set search_path = public
as $$
declare
    v_caller uuid := (select auth.uid());
    v_row    public.tasks;
begin
    if v_caller is null then
        raise exception 'Niet ingelogd.' using errcode = 'insufficient_privilege';
    end if;

    -- Atomische claim. WHERE status = 'open' zorgt dat slechts één buddy wint;
    -- een tweede, gelijktijdige poging raakt 0 rijen en krijgt NULL terug.
    update public.tasks
       set status            = 'accepted',
           assigned_buddy_id = v_caller,
           accepted_at       = now(),
           buddy_eta_minutes = p_eta_minutes
     where id     = p_task_id
       and status = 'open'
    returning * into v_row;

    return v_row;  -- NULL als de taak al was aangenomen of niet meer open is.
end;
$$;

grant execute on function public.accept_task(uuid, int) to authenticated;
