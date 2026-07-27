-- ============================================================
-- Fase 29 — Intake: zelf een gesprek inplannen (naast de wachtrij)
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Idempotent.
--
-- Naast de bestaande wachtrij ('waiting') kan een buddy nu zelf een moment
-- kiezen: de rij krijgt status 'scheduled' + scheduled_at. De admin ziet deze
-- geplande gesprekken als een planning naast de live-wachtrij. meeting_url is
-- optioneel (voor de agenda-link); de videostream zelf loopt via de edge
-- function intake-video.
-- ============================================================

-- 1) Nieuwe status-waarde toevoegen aan de enum (idempotent).
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'call_status' AND e.enumlabel = 'scheduled'
    ) THEN
        ALTER TYPE call_status ADD VALUE 'scheduled';
    END IF;
END $$;

-- 2) Kolommen voor het geplande moment en de (optionele) agenda-link.
ALTER TABLE intake_calls
    ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS meeting_url  TEXT;

CREATE INDEX IF NOT EXISTS idx_intake_calls_scheduled
    ON intake_calls(status, scheduled_at);

-- ============================================================
-- KLAAR.
-- ============================================================
