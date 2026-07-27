-- ============================================================================
-- Fase 23 — Geboortejaar van de cliënt
-- ----------------------------------------------------------------------------
-- De leeftijd werd in live-modus afgeleid van een hardcoded standaard-
-- geboortedatum (1-1-1945) → iedereen leek "81". We bewaren nu een echt
-- geboortejaar; de app toont de leeftijd alleen als die bekend is.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

alter table public.elderly_profiles
    add column if not exists birth_year int;
