-- ============================================================
-- Fase 4 — RLS performance (Auth RLS Initialization Plan)
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent: meermaals draaien kan geen kwaad.
--
-- Wat & waarom:
--   De Supabase-advisor waarschuwt dat policies die `auth.uid()` direct
--   gebruiken die functie PER RIJ opnieuw evalueren. Door het te wikkelen als
--   `(select auth.uid())` evalueert Postgres het ÉÉN keer per query (initplan).
--   Zelfde gedrag, sneller. Dit herschrijft de bestaande policies uit
--   schema.sql + fase1 met die optimalisatie.
-- ============================================================

-- ------------------------------------------------------------
-- PROFILES
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Eigen profiel lezen"   ON profiles;
DROP POLICY IF EXISTS "Eigen profiel updaten" ON profiles;
CREATE POLICY "Eigen profiel lezen"   ON profiles FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Eigen profiel updaten" ON profiles FOR UPDATE USING ((select auth.uid()) = id);

-- ------------------------------------------------------------
-- ELDERLY PROFILES
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Eigen elderly profiel"               ON elderly_profiles;
DROP POLICY IF EXISTS "Familie kan elderly profiel lezen"   ON elderly_profiles;
DROP POLICY IF EXISTS "Elderly kan eigen profiel updaten"   ON elderly_profiles;
CREATE POLICY "Eigen elderly profiel" ON elderly_profiles FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Familie kan elderly profiel lezen" ON elderly_profiles FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = (select auth.uid()) AND elderly_id = elderly_profiles.id
    )
);
CREATE POLICY "Elderly kan eigen profiel updaten" ON elderly_profiles FOR UPDATE USING ((select auth.uid()) = id);

-- ------------------------------------------------------------
-- BUDDY PROFILES
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Buddy kan eigen profiel updaten" ON buddy_profiles;
CREATE POLICY "Buddy kan eigen profiel updaten" ON buddy_profiles FOR UPDATE USING ((select auth.uid()) = id);

-- ------------------------------------------------------------
-- PARTNER CODES
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Admin kan koppelcodes aanmaken" ON partner_codes;
DROP POLICY IF EXISTS "Admin kan koppelcodes beheren"  ON partner_codes;
CREATE POLICY "Admin kan koppelcodes aanmaken" ON partner_codes FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
);
CREATE POLICY "Admin kan koppelcodes beheren" ON partner_codes FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
);

-- ------------------------------------------------------------
-- TASKS
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Open taken zichtbaar voor ingelogde buddies" ON tasks;
DROP POLICY IF EXISTS "Elderly kan eigen taken aanmaken"            ON tasks;
DROP POLICY IF EXISTS "Buddy kan taakstatus updaten"                ON tasks;
CREATE POLICY "Open taken zichtbaar voor ingelogde buddies" ON tasks FOR SELECT USING (
    (select auth.uid()) IS NOT NULL AND (
        status = 'open'
        OR elderly_id = (select auth.uid())
        OR assigned_buddy_id = (select auth.uid())
        OR EXISTS (
            SELECT 1 FROM family_elderly_links
            WHERE family_id = (select auth.uid()) AND elderly_id = tasks.elderly_id
        )
    )
);
CREATE POLICY "Elderly kan eigen taken aanmaken" ON tasks FOR INSERT WITH CHECK (elderly_id = (select auth.uid()));
CREATE POLICY "Buddy kan taakstatus updaten" ON tasks FOR UPDATE USING (
    assigned_buddy_id = (select auth.uid()) OR elderly_id = (select auth.uid())
);

-- ------------------------------------------------------------
-- REVIEWS
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Elderly kan review plaatsen" ON reviews;
CREATE POLICY "Elderly kan review plaatsen" ON reviews FOR INSERT WITH CHECK (reviewer_id = (select auth.uid()));

-- ------------------------------------------------------------
-- SOS EVENTS
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "SOS events voor betrokkenen" ON sos_events;
DROP POLICY IF EXISTS "Elderly kan SOS aanmaken"    ON sos_events;
CREATE POLICY "SOS events voor betrokkenen" ON sos_events FOR SELECT USING (
    elderly_id = (select auth.uid())
    OR EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = (select auth.uid()) AND elderly_id = sos_events.elderly_id
    )
);
CREATE POLICY "Elderly kan SOS aanmaken" ON sos_events FOR INSERT WITH CHECK (elderly_id = (select auth.uid()));

-- ------------------------------------------------------------
-- LINKING CODES
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Elderly kan eigen codes lezen" ON linking_codes;
CREATE POLICY "Elderly kan eigen codes lezen" ON linking_codes FOR SELECT USING (elderly_id = (select auth.uid()));

-- ------------------------------------------------------------
-- DEVICE TOKENS
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Eigen device token toevoegen"   ON device_tokens;
DROP POLICY IF EXISTS "Eigen device tokens lezen"       ON device_tokens;
DROP POLICY IF EXISTS "Eigen device token updaten"      ON device_tokens;
DROP POLICY IF EXISTS "Eigen device token verwijderen"  ON device_tokens;
CREATE POLICY "Eigen device token toevoegen"  ON device_tokens FOR INSERT WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY "Eigen device tokens lezen"      ON device_tokens FOR SELECT USING (user_id = (select auth.uid()));
CREATE POLICY "Eigen device token updaten"     ON device_tokens FOR UPDATE USING (user_id = (select auth.uid()));
CREATE POLICY "Eigen device token verwijderen" ON device_tokens FOR DELETE USING (user_id = (select auth.uid()));

-- ============================================================
-- KLAAR. Ververs de Advisor → de "Auth RLS Initialization Plan"-meldingen
-- voor deze tabellen verdwijnen.
-- ============================================================
