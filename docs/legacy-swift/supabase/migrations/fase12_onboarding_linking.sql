-- ============================================================
-- Fase 12 — Echte onboarding & familie-koppeling
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent.
--
-- Model: de OUDERE registreert zichzelf en deelt een persoonlijke
-- 6-cijferige koppelcode. Een familielid voert die code in en wordt
-- gekoppeld. Drie SECURITY DEFINER-functies doen dit veilig en atomair,
-- zodat we geen losse (kwetsbare) INSERT/UPDATE-policies op linking_codes
-- nodig hebben.
-- ============================================================

-- ------------------------------------------------------------
-- family_elderly_links: RLS aan + betrokkenen mogen hun koppeling lezen.
-- (Inserts gebeuren via de functie hieronder, dus geen INSERT-policy nodig.)
-- ------------------------------------------------------------
ALTER TABLE family_elderly_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Betrokkenen zien koppeling" ON family_elderly_links;
CREATE POLICY "Betrokkenen zien koppeling" ON family_elderly_links
    FOR SELECT TO authenticated
    USING (family_id = (select auth.uid()) OR elderly_id = (select auth.uid()));

-- ------------------------------------------------------------
-- 1) Oudere: haal (of maak) mijn persoonlijke koppelcode op.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION ensure_my_linking_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid  UUID := auth.uid();
    v_code TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Niet ingelogd';
    END IF;

    -- Bestaat er al een ongebruikte, niet-verlopen code? Hergebruik die.
    SELECT code INTO v_code
    FROM linking_codes
    WHERE elderly_id = v_uid AND used_at IS NULL AND expires_at >= NOW()
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_code IS NOT NULL THEN
        RETURN v_code;
    END IF;

    -- Genereer een unieke 6-cijferige code.
    LOOP
        v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
        EXIT WHEN NOT EXISTS (SELECT 1 FROM linking_codes WHERE code = v_code);
    END LOOP;

    INSERT INTO linking_codes (code, elderly_id) VALUES (v_code, v_uid);
    RETURN v_code;
END;
$$;

-- ------------------------------------------------------------
-- 2) Familie: wissel een koppelcode in → maak de koppeling + markeer gebruikt.
--    Geeft de oudere terug (id + naam), of NULL bij een ongeldige code.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION redeem_linking_code(p_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_family  UUID := auth.uid();
    v_elderly UUID;
    v_first   TEXT;
    v_last    TEXT;
BEGIN
    IF v_family IS NULL THEN
        RAISE EXCEPTION 'Niet ingelogd';
    END IF;

    SELECT lc.elderly_id, p.first_name, p.last_name
      INTO v_elderly, v_first, v_last
    FROM linking_codes lc
    JOIN profiles p ON p.id = lc.elderly_id
    WHERE lc.code = p_code AND lc.used_at IS NULL AND lc.expires_at >= NOW()
    LIMIT 1;

    IF v_elderly IS NULL THEN
        RETURN NULL;
    END IF;

    INSERT INTO family_elderly_links (family_id, elderly_id)
    VALUES (v_family, v_elderly)
    ON CONFLICT (family_id, elderly_id) DO NOTHING;

    UPDATE linking_codes SET used_at = NOW() WHERE code = p_code;

    RETURN json_build_object('id', v_elderly, 'first_name', v_first, 'last_name', v_last);
END;
$$;

-- ------------------------------------------------------------
-- 3) Familie: alle gekoppelde ouderen (id + naam + locatie) ophalen.
--    Via SECURITY DEFINER zodat we niet afhankelijk zijn van profiel-leesrechten.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION my_linked_elderly()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_family UUID := auth.uid();
BEGIN
    IF v_family IS NULL THEN
        RETURN '[]'::json;
    END IF;

    RETURN COALESCE((
        SELECT json_agg(json_build_object(
            'id',         p.id,
            'first_name', p.first_name,
            'last_name',  p.last_name,
            'address',    COALESCE(ep.address, ''),
            'latitude',   ep.latitude,
            'longitude',  ep.longitude
        ))
        FROM family_elderly_links fel
        JOIN profiles p ON p.id = fel.elderly_id
        LEFT JOIN elderly_profiles ep ON ep.id = fel.elderly_id
        WHERE fel.family_id = v_family
    ), '[]'::json);
END;
$$;

GRANT EXECUTE ON FUNCTION ensure_my_linking_code()        TO authenticated;
GRANT EXECUTE ON FUNCTION redeem_linking_code(TEXT)       TO authenticated;
GRANT EXECUTE ON FUNCTION my_linked_elderly()             TO authenticated;

-- ============================================================
-- KLAAR.
-- ============================================================
