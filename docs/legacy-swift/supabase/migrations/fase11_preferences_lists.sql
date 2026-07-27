-- ============================================================
-- Fase 11 — Voorkeuren & lijsten persistent maken
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Maakt vier dingen persistent die voorheen alleen lokaal (per apparaat) leefden:
--   1) Oudere-voorkeuren: grote letters + formeel aanspreken
--   2) Buddy welzijn-services (welke soort hulp een buddy wil doen)
--   3) Favoriete ("vaste") buddies van een oudere
--   4) Overgeslagen beoordelingen (zodat de vraag niet blijft terugkomen)
-- ============================================================

-- ------------------------------------------------------------
-- 1) Oudere-voorkeuren
-- ------------------------------------------------------------
ALTER TABLE elderly_profiles ADD COLUMN IF NOT EXISTS large_text_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE elderly_profiles ADD COLUMN IF NOT EXISTS prefers_formal     BOOLEAN NOT NULL DEFAULT TRUE;

-- ------------------------------------------------------------
-- 2) Buddy welzijn-services (array van service-namen)
-- ------------------------------------------------------------
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS preferred_services TEXT[] NOT NULL DEFAULT '{}';

-- ------------------------------------------------------------
-- 3) Favoriete buddies (oudere markeert een vaste buddy)
--    buddy_name wordt gedenormaliseerd meegeschreven zodat de app
--    de lijst kan tonen zonder extra join.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favorite_buddies (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    elderly_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    buddy_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    buddy_name  TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(elderly_id, buddy_id)
);
CREATE INDEX IF NOT EXISTS idx_favorite_buddies_elderly ON favorite_buddies(elderly_id);

ALTER TABLE favorite_buddies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Oudere beheert eigen favorieten" ON favorite_buddies;
CREATE POLICY "Oudere beheert eigen favorieten" ON favorite_buddies
    FOR ALL TO authenticated
    USING (elderly_id = (select auth.uid()))
    WITH CHECK (elderly_id = (select auth.uid()));

-- Een buddy mag zien wie hem/haar als vaste buddy heeft gekozen.
DROP POLICY IF EXISTS "Buddy ziet eigen fans" ON favorite_buddies;
CREATE POLICY "Buddy ziet eigen fans" ON favorite_buddies
    FOR SELECT TO authenticated
    USING (buddy_id = (select auth.uid()));

-- ------------------------------------------------------------
-- 4) Overgeslagen beoordelingen
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS skipped_reviews (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reviewer_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    task_id      UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(reviewer_id, task_id)
);
CREATE INDEX IF NOT EXISTS idx_skipped_reviews_reviewer ON skipped_reviews(reviewer_id);

ALTER TABLE skipped_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Reviewer beheert eigen overslaan" ON skipped_reviews;
CREATE POLICY "Reviewer beheert eigen overslaan" ON skipped_reviews
    FOR ALL TO authenticated
    USING (reviewer_id = (select auth.uid()))
    WITH CHECK (reviewer_id = (select auth.uid()));

-- ============================================================
-- KLAAR.
-- ============================================================
