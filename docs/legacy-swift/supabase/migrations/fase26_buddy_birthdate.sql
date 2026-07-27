-- ============================================================================
-- Fase 26 — Volledige geboortedatum voor buddies
-- ----------------------------------------------------------------------------
-- Bij registratie werd alleen een geboortejaar gevraagd. We slaan nu de
-- volledige geboortedatum (dag/maand/jaar) op, net als bij cliënten, zodat de
-- leeftijd exact klopt en op het buddy-profiel kan worden getoond.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

alter table public.buddy_profiles
    add column if not exists date_of_birth date;
