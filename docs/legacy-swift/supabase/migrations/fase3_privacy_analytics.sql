-- ============================================================
-- Fase 3 — Privacy-by-design analytics + demografie
--
-- Draai dit ÉÉN keer in: Supabase → SQL Editor → New query → plak → Run.
-- Volledig idempotent: meermaals draaien kan geen kwaad.
--
-- Hoort bij het actieve project (de URL/key in Services/SupabaseManager.swift).
-- Achtergrond + grenzen: zie MEGA_PROMPT_DATA_PRIVACY_LAAG.md.
--
-- Wat dit opzet:
--   1. consents            — expliciete, intrekbare toestemming per doel
--   2. analytics_events     — pseudonieme ruwe events (RLS, geen PII)
--   3. aggregatie-views     — k-anoniem (≥5), de ENIGE deelbare laag
--   4. demografie           — geslacht/geboortejaar/PC4 op profiles + trigger
--   5. demografie-views     — k-anonieme gemeente-aggregaties
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- ENUMS
-- ------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE consent_purpose AS ENUM (
        'product_analytics',   -- app verbeteren (eigen gebruik)
        'research_insights'    -- geaggregeerde, anonieme inzichten (evt. delen/verkopen)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE analytics_event_type AS ENUM (
        'app_open',
        'help_requested',
        'task_accepted',
        'task_completed',
        'task_cancelled',
        'visit_checkin',
        'buddy_available_on',
        'buddy_available_off'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 1. CONSENTS — juridische basis, per gebruiker per doel (append-only)
-- ============================================================
CREATE TABLE IF NOT EXISTS consents (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    purpose        consent_purpose NOT NULL,
    granted        BOOLEAN NOT NULL,
    policy_version TEXT NOT NULL DEFAULT 'v1',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_consents_user ON consents(user_id);

ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Eigen consent toevoegen" ON consents;
DROP POLICY IF EXISTS "Eigen consent lezen"     ON consents;
-- (select auth.uid()) i.p.v. auth.uid() → één evaluatie per query (perf-advies).
CREATE POLICY "Eigen consent toevoegen" ON consents
    FOR INSERT WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY "Eigen consent lezen" ON consents
    FOR SELECT USING (user_id = (select auth.uid()));

-- Huidige (laatste) keuze per gebruiker+doel.
-- security_invoker = on → de view respecteert de RLS van de opvrager
-- (lost de "Security Definer View"-waarschuwing op).
CREATE OR REPLACE VIEW v_current_consent
WITH (security_invoker = on) AS
SELECT DISTINCT ON (user_id, purpose)
       user_id, purpose, granted, policy_version, created_at
FROM consents
ORDER BY user_id, purpose, created_at DESC;

-- Helper: heeft deze gebruiker NU toestemming voor een doel?
-- Leest direct uit consents (niet via de view) zodat de RLS-hot-path
-- onafhankelijk is van view-grants.
CREATE OR REPLACE FUNCTION public.has_consent(p_user UUID, p_purpose public.consent_purpose)
RETURNS BOOLEAN LANGUAGE sql STABLE SET search_path = '' AS $$
    SELECT COALESCE(
        (SELECT granted FROM public.consents
         WHERE user_id = p_user AND purpose = p_purpose
         ORDER BY created_at DESC LIMIT 1), FALSE);
$$;

-- ============================================================
-- 2. ANALYTICS_EVENTS — pseudonieme ruwe events (geen PII, geen exacte locatie)
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics_events (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
    role        user_role,
    event_type  analytics_event_type NOT NULL,
    region      TEXT,            -- grove regio: gemeente of PC4, NOOIT exact adres
    category    task_category,   -- alleen bij taak-events
    props       JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_events_type_time ON analytics_events(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_events_region    ON analytics_events(region);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigen event loggen met toestemming" ON analytics_events;
CREATE POLICY "Eigen event loggen met toestemming" ON analytics_events
    FOR INSERT WITH CHECK (
        user_id = (select auth.uid())
        AND has_consent((select auth.uid()), 'product_analytics')
    );

DROP POLICY IF EXISTS "Eigen events lezen" ON analytics_events;
CREATE POLICY "Eigen events lezen" ON analytics_events
    FOR SELECT USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Eigen events verwijderen" ON analytics_events;
CREATE POLICY "Eigen events verwijderen" ON analytics_events
    FOR DELETE USING (user_id = (select auth.uid()));

-- ============================================================
-- 3. AGGREGATIE-VIEWS — de ENIGE deelbare laag. k-anoniem (HAVING COUNT(*) >= 5).
-- ============================================================
CREATE OR REPLACE VIEW v_events_by_region_week
WITH (security_invoker = on) AS
SELECT region,
       date_trunc('week', created_at)::date AS week,
       event_type,
       COUNT(*) AS aantal
FROM analytics_events
WHERE region IS NOT NULL
GROUP BY region, week, event_type
HAVING COUNT(*) >= 5;

CREATE OR REPLACE VIEW v_task_demand_by_category
WITH (security_invoker = on) AS
SELECT region,
       category,
       date_trunc('month', created_at)::date AS maand,
       COUNT(*) AS aantal
FROM analytics_events
WHERE event_type = 'help_requested' AND category IS NOT NULL AND region IS NOT NULL
GROUP BY region, category, maand
HAVING COUNT(*) >= 5;

CREATE OR REPLACE VIEW v_funnel_daily
WITH (security_invoker = on) AS
SELECT date_trunc('day', created_at)::date AS dag,
       COUNT(*) FILTER (WHERE event_type = 'help_requested') AS hulpvragen,
       COUNT(*) FILTER (WHERE event_type = 'task_accepted')  AS aangenomen,
       COUNT(*) FILTER (WHERE event_type = 'task_completed') AS afgerond
FROM analytics_events
GROUP BY dag
HAVING COUNT(*) >= 5;

-- ============================================================
-- 4. DEMOGRAFIE op profiles + vulling vanuit registratie-metadata
-- ============================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender     TEXT;     -- 'vrouw'|'man'|'anders'
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS birth_year INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS postcode4  TEXT;     -- 4 cijfers (PC4)

-- Leeftijdsband uit geboortejaar (banden voorkomen herleidbaarheid).
CREATE OR REPLACE FUNCTION public.age_band(p_birth_year INTEGER)
RETURNS TEXT LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT CASE
        WHEN p_birth_year IS NULL THEN 'onbekend'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 30 THEN '<30'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 50 THEN '30-49'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 65 THEN '50-64'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 80 THEN '65-79'
        ELSE '80+'
    END;
$$;

-- Vult profiles met (rol/naam +) demografie uit de auth-metadata.
-- ON CONFLICT maakt dit veilig naast een eventueel bestaande "new user"-trigger:
-- bestaat de profielrij al, dan worden alleen de velden bijgewerkt.
CREATE OR REPLACE FUNCTION public.handle_new_user_demographics()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
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
        -- Geen rol in metadata (bv. OTP): alleen demografie bijwerken als de rij bestaat.
        UPDATE public.profiles SET
            gender     = COALESCE(m->>'gender', gender),
            birth_year = COALESCE((m->>'birth_year')::int, birth_year),
            postcode4  = COALESCE(m->>'postcode4', postcode4)
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END $$;

-- 'z'-prefix → draait ná een eventueel bestaande on_auth_user_created-trigger.
DROP TRIGGER IF EXISTS ztrg_new_user_demographics ON auth.users;
CREATE TRIGGER ztrg_new_user_demographics
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user_demographics();

-- ============================================================
-- 5. DEMOGRAFIE-VIEWS — k-anoniem (≥5), gebruik altijd age_band (nooit exact jaar)
-- ============================================================
CREATE OR REPLACE VIEW v_demographics_by_region
WITH (security_invoker = on) AS
SELECT postcode4,
       age_band(birth_year) AS leeftijdsband,
       gender,
       role,
       COUNT(*) AS aantal
FROM profiles
WHERE postcode4 IS NOT NULL
GROUP BY postcode4, leeftijdsband, gender, role
HAVING COUNT(*) >= 5;

CREATE OR REPLACE VIEW v_demand_by_demographics
WITH (security_invoker = on) AS
SELECT e.region AS postcode4,
       age_band(p.birth_year) AS leeftijdsband,
       p.gender,
       e.category,
       date_trunc('month', e.created_at)::date AS maand,
       COUNT(*) AS aantal
FROM analytics_events e
JOIN profiles p ON p.id = e.user_id
WHERE e.event_type = 'help_requested' AND e.region IS NOT NULL
GROUP BY e.region, leeftijdsband, p.gender, e.category, maand
HAVING COUNT(*) >= 5;

-- ============================================================
-- 6. API-toegang afschermen (defense-in-depth)
--
-- De oogst-views zijn alleen voor jou (SQL Editor / service_role). Haal ze
-- weg bij de API-rollen anon/authenticated, zodat de app ze nooit kan opvragen.
-- (postgres en service_role behouden toegang en negeren RLS sowieso.)
-- ============================================================
REVOKE ALL ON
    v_current_consent,
    v_events_by_region_week,
    v_task_demand_by_category,
    v_funnel_daily,
    v_demographics_by_region,
    v_demand_by_demographics
FROM anon, authenticated;

-- ============================================================
-- KLAAR.
--   Ruwe events:  Table Editor → analytics_events (debug/inzage).
--   Deelbaar:     SELECT * FROM v_demand_by_demographics;  (en de andere v_*-views)
-- ============================================================
