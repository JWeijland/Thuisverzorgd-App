-- ============================================================================
-- Fase 27 — Huidige locatie van de buddy (voor 500m-meldingen onderweg)
-- ----------------------------------------------------------------------------
-- buddy_profiles.latitude/longitude is het THUISADRES. Voor "krijg een melding
-- als iemand binnen 500 m van waar je NU bent hulp zoekt" houden we de live
-- locatie apart bij. De app werkt deze periodiek bij (significante
-- locatiewijziging + bij openen), ook op de achtergrond.
--
-- location_updated_at gebruikt de edge function om verouderde posities te negeren.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

alter table public.buddy_profiles
    add column if not exists current_latitude   double precision,
    add column if not exists current_longitude  double precision,
    add column if not exists location_updated_at timestamptz;
