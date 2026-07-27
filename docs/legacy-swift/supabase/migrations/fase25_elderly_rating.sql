-- ============================================================================
-- Fase 25 — Beoordeling van de hulpvrager (buddy → cliënt) + cliënt-gemiddelde
-- ----------------------------------------------------------------------------
-- Reviews waren tot nu toe eenrichting (cliënt → buddy). De buddy beoordeelt nu
-- óók de hulpvrager. De `reviews`-tabel is al generiek (reviewer_id/reviewee_id)
-- en de INSERT-policy staat elke schrijver toe (reviewer_id = auth.uid()), dus
-- een buddy mag een review plaatsen. We bewaren hier het cliënt-gemiddelde op
-- elderly_profiles en werken dat bij via een eigen trigger.
--
-- De bestaande trigger trg_update_buddy_rating blijft bestaan; hij raakt 0 rijen
-- bij een cliënt-reviewee (geen buddy_profiles-rij) en is dus onschadelijk. Deze
-- nieuwe trigger raakt op zijn beurt 0 rijen bij een buddy-reviewee.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

alter table public.elderly_profiles
    add column if not exists rating_average double precision default 0,
    add column if not exists total_reviews  int default 0;

create or replace function public.update_elderly_rating()
returns trigger language plpgsql set search_path = '' as $$
begin
    update public.elderly_profiles
    set rating_average = coalesce((
            select round(avg(stars)::numeric, 1)
            from public.reviews
            where reviewee_id = new.reviewee_id
        ), 0),
        total_reviews = (
            select count(*)
            from public.reviews
            where reviewee_id = new.reviewee_id
        )
    where id = new.reviewee_id;  -- raakt alleen een rij als de reviewee een cliënt is
    return new;
end;
$$;

drop trigger if exists trg_update_elderly_rating on public.reviews;
create trigger trg_update_elderly_rating
    after insert on public.reviews
    for each row execute function public.update_elderly_rating();
