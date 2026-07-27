-- ============================================================
-- Fase 7 — VOG-flow: status + geüpload document + admin-akkoord
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Twee routes voor een buddy:
--   A) Heeft al een VOG → uploadt het document → status 'in_behandeling'.
--   B) Vraagt aan via Thuisverzorgd → status 'aangevraagd'.
-- In beide gevallen zet een admin de status uiteindelijk op 'geldig'
-- (dat zet ook vog_valid = true → de buddy kan taken aannemen).
-- ============================================================

-- ------------------------------------------------------------
-- Status-enum + kolommen op buddy_profiles
-- ------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE vog_status AS ENUM (
        'niet_aangevraagd',
        'aangevraagd',      -- buddy vraagt aan via Thuisverzorgd (org start de aanvraag)
        'in_behandeling',   -- document geüpload of aanvraag loopt; wacht op controle
        'geldig',           -- door admin goedgekeurd
        'afgewezen',
        'verlopen'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS vog_status       vog_status NOT NULL DEFAULT 'niet_aangevraagd';
ALTER TABLE buddy_profiles ADD COLUMN IF NOT EXISTS vog_document_url TEXT;   -- pad in de vog-documents bucket

-- Bestaande buddies die al vog_valid=true hadden → status 'geldig'.
UPDATE buddy_profiles SET vog_status = 'geldig'
WHERE vog_valid IS TRUE AND vog_status = 'niet_aangevraagd';

-- ------------------------------------------------------------
-- Privé storage-bucket voor VOG-documenten
-- ------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('vog-documents', 'vog-documents', false)
ON CONFLICT (id) DO NOTHING;

-- RLS op de bestanden: een buddy beheert alleen zijn eigen map ({uid}/...),
-- admins mogen alles lezen (voor de controle).
DROP POLICY IF EXISTS "VOG eigen map upload"      ON storage.objects;
DROP POLICY IF EXISTS "VOG eigen map bijwerken"   ON storage.objects;
DROP POLICY IF EXISTS "VOG eigen map of admin lezen" ON storage.objects;

CREATE POLICY "VOG eigen map upload" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'vog-documents'
        AND (storage.foldername(name))[1] = (select auth.uid())::text
    );

CREATE POLICY "VOG eigen map bijwerken" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'vog-documents'
        AND (storage.foldername(name))[1] = (select auth.uid())::text
    );

CREATE POLICY "VOG eigen map of admin lezen" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'vog-documents'
        AND (
            (storage.foldername(name))[1] = (select auth.uid())::text
            OR EXISTS (SELECT 1 FROM public.profiles
                       WHERE id = (select auth.uid()) AND role = 'admin')
        )
    );

-- ------------------------------------------------------------
-- Admin mag buddy-profielen lezen + de VOG-status updaten
-- (buddy_profiles is al publiek leesbaar voor matching; de UPDATE-policy
--  staat alleen de buddy zelf toe. We voegen een admin-UPDATE-policy toe.)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Admin kan buddy VOG updaten" ON buddy_profiles;
CREATE POLICY "Admin kan buddy VOG updaten" ON buddy_profiles
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
    );

-- ============================================================
-- KLAAR.
-- ============================================================
