-- ============================================================
-- Fase 1 — echte hulpverzoeken + voorbereiding pushnotificaties
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent: meermaals draaien kan geen kwaad.
--
-- Hoort bij het actieve project (de URL/key in Services/SupabaseManager.swift).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Weergavevelden op tasks
--
-- Een beschikbare buddy mag (RLS) het profiel van een ouder NIET lezen.
-- Daarom zetten we de minimale weergave-info die nodig is om een open
-- hulpverzoek te tonen (voornaam + globale locatie) op de taakrij zelf.
-- De ouder vult deze bij het aanmaken in (INSERT-policy: elderly_id = auth.uid()).
-- ------------------------------------------------------------

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS elderly_first_name TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS elderly_latitude   DOUBLE PRECISION;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS elderly_longitude  DOUBLE PRECISION;

-- ------------------------------------------------------------
-- 2. Device tokens (APNs) — nodig voor de pushnotificaties in Fase 2
--
-- Eén gebruiker kan meerdere apparaten hebben. De Edge Function leest deze
-- tabel met de service-role (omzeilt RLS) om pushes te versturen.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS device_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token       TEXT NOT NULL UNIQUE,         -- APNs device token
    platform    TEXT NOT NULL DEFAULT 'ios',
    role        user_role,                    -- snelle filtering: stuur alleen naar buddies
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_role ON device_tokens(role);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Een gebruiker beheert uitsluitend zijn eigen tokens.
DROP POLICY IF EXISTS "Eigen device token toevoegen"   ON device_tokens;
DROP POLICY IF EXISTS "Eigen device tokens lezen"       ON device_tokens;
DROP POLICY IF EXISTS "Eigen device token updaten"      ON device_tokens;
DROP POLICY IF EXISTS "Eigen device token verwijderen"  ON device_tokens;

CREATE POLICY "Eigen device token toevoegen"  ON device_tokens FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Eigen device tokens lezen"      ON device_tokens FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Eigen device token updaten"     ON device_tokens FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Eigen device token verwijderen" ON device_tokens FOR DELETE USING (user_id = auth.uid());

-- ------------------------------------------------------------
-- 3. Realtime inschakelen op tasks (zodat clients live updates krijgen)
-- ------------------------------------------------------------

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
EXCEPTION
    WHEN duplicate_object THEN NULL;   -- al toegevoegd
END $$;
