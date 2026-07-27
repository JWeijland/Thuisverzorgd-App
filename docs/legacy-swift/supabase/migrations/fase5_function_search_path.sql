-- ============================================================
-- Fase 5 — Function Search Path Mutable (advisor)
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Wat & waarom:
--   Functies zonder vast `search_path` kunnen via een gemanipuleerd
--   search_path naar verkeerde objecten verwijzen. Vooral voor SECURITY
--   DEFINER-functies is dat een risico. We pinnen het search_path.
--
--   • Mijn functies → herschreven met `SET search_path = ''` en volledig
--     gekwalificeerde namen (public.*), de veiligste variant.
--   • Bestaande functies (update_*) → search_path gepind via ALTER, in een
--     DO-block zodat een afwijkende signatuur de migratie niet afbreekt.
-- ============================================================

-- ------------------------------------------------------------
-- has_consent — leest de laatste toestemmingskeuze (gebruikt in RLS)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.has_consent(p_user UUID, p_purpose public.consent_purpose)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
    SELECT COALESCE(
        (SELECT granted FROM public.consents
         WHERE user_id = p_user AND purpose = p_purpose
         ORDER BY created_at DESC LIMIT 1), FALSE);
$$;

-- ------------------------------------------------------------
-- age_band — leeftijdsband uit geboortejaar (geen tabel-refs)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.age_band(p_birth_year INTEGER)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
    SELECT CASE
        WHEN p_birth_year IS NULL THEN 'onbekend'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 30 THEN '<30'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 50 THEN '30-49'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 65 THEN '50-64'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 80 THEN '65-79'
        ELSE '80+'
    END;
$$;

-- ------------------------------------------------------------
-- handle_new_user_demographics — SECURITY DEFINER trigger (volledig gekwalificeerd)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user_demographics()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    m JSONB := NEW.raw_user_meta_data;
BEGIN
    IF m ? 'role' THEN
        INSERT INTO public.profiles (id, role, first_name, last_name, gender, birth_year, postcode4)
        VALUES (
            NEW.id,
            (m->>'role')::public.user_role,
            COALESCE(m->>'first_name', ''),
            COALESCE(m->>'last_name', ''),
            m->>'gender',
            (m->>'birth_year')::int,
            m->>'postcode4'
        )
        ON CONFLICT (id) DO UPDATE SET
            gender     = COALESCE(EXCLUDED.gender, public.profiles.gender),
            birth_year = COALESCE(EXCLUDED.birth_year, public.profiles.birth_year),
            postcode4  = COALESCE(EXCLUDED.postcode4, public.profiles.postcode4);
    ELSE
        UPDATE public.profiles SET
            gender     = COALESCE(m->>'gender', gender),
            birth_year = COALESCE((m->>'birth_year')::int, birth_year),
            postcode4  = COALESCE(m->>'postcode4', postcode4)
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END $$;

-- ------------------------------------------------------------
-- Bestaande functies (uit schema.sql): search_path pinnen.
-- DO-block → een afwijkende/ontbrekende signatuur breekt de migratie niet.
-- ------------------------------------------------------------
DO $$ BEGIN
    EXECUTE 'ALTER FUNCTION public.update_updated_at() SET search_path = public';
EXCEPTION WHEN undefined_function THEN
    RAISE NOTICE 'update_updated_at() niet gevonden met deze signatuur — overgeslagen';
END $$;

DO $$ BEGIN
    EXECUTE 'ALTER FUNCTION public.update_buddy_rating() SET search_path = public';
EXCEPTION WHEN undefined_function THEN
    RAISE NOTICE 'update_buddy_rating() niet gevonden met deze signatuur — overgeslagen';
END $$;

-- ============================================================
-- KLAAR. Ververs de Advisor → de "Function Search Path Mutable"-meldingen
-- voor deze functies verdwijnen.
--
-- LET OP — handmatig (geen SQL): zet "Leaked Password Protection" aan onder
-- Authentication → Settings. Dat lost de laatste auth-melding op.
-- ============================================================
