-- ============================================================
-- FASE 16 — White-label per vrijwilligersorganisatie
-- ------------------------------------------------------------
-- Elke gebruiker kan bij de registratie aangeven bij welke aangesloten
-- vrijwilligersorganisatie hij/zij hoort. De app kleurt daarna volledig om naar
-- de huisstijl van die organisatie (kleuren, hoeken, fonts, iconenset) terwijl
-- de werking identiek blijft. De keuze bewaren we als thema-sleutel op het
-- profiel, zodat de juiste skin meteen bij login bekend is.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================

-- 1. Kolom op profiles (tekstuele thema-sleutel; NULL = standaard Thuisverzorgd)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS organization_key text;

COMMENT ON COLUMN public.profiles.organization_key IS
    'White-label thema-sleutel van de gekozen vrijwilligersorganisatie (bv. zuid, present). NULL = standaard Thuisverzorgd.';

-- 2. Trigger uitbreiden zodat organization_key uit de signup-metadata wordt
--    overgenomen. Verder identiek aan fase 3 (demografie via raw_user_meta_data).
CREATE OR REPLACE FUNCTION public.handle_new_user_demographics()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
    m JSONB := NEW.raw_user_meta_data;
BEGIN
    IF m ? 'role' THEN
        INSERT INTO public.profiles (id, role, first_name, last_name, gender, birth_year, postcode4, organization_key)
        VALUES (
            NEW.id,
            (m->>'role')::public.user_role,
            COALESCE(m->>'first_name', ''),
            COALESCE(m->>'last_name', ''),
            m->>'gender',
            (m->>'birth_year')::int,
            m->>'postcode4',
            m->>'organization_key'
        )
        ON CONFLICT (id) DO UPDATE SET
            gender           = COALESCE(EXCLUDED.gender, public.profiles.gender),
            birth_year       = COALESCE(EXCLUDED.birth_year, public.profiles.birth_year),
            postcode4        = COALESCE(EXCLUDED.postcode4, public.profiles.postcode4),
            organization_key = COALESCE(EXCLUDED.organization_key, public.profiles.organization_key);
    ELSE
        -- Geen rol in metadata (bv. OTP): alleen aanvullende velden bijwerken als de rij bestaat.
        UPDATE public.profiles SET
            gender           = COALESCE(m->>'gender', gender),
            birth_year       = COALESCE((m->>'birth_year')::int, birth_year),
            postcode4        = COALESCE(m->>'postcode4', postcode4),
            organization_key = COALESCE(m->>'organization_key', organization_key)
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;
