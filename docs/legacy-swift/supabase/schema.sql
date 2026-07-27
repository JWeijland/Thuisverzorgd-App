-- ============================================================
-- Thuisverzorgd (welzijn-versie) — Supabase Database Schema
-- Plak dit in Supabase → SQL Editor → New query → Run
--
-- Vrijwilligersplatform: geen geld (tarieven/verdiensten), geen niveaus,
-- geen cursussen, geen ID/KYC. Buddies hebben VOG + korte intake. Clients
-- sluiten aan via een koppelcode (partner_codes) van gemeente/verzekeraar/werkgever.
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role        AS ENUM ('elderly', 'buddy', 'family', 'admin');
CREATE TYPE task_category    AS ENUM ('companionship','walk_outdoors','groceries','activity','digital_help','social_support','light_cleaning','appointment','other');
CREATE TYPE task_status      AS ENUM ('open','accepted','arrived','in_progress','completed','cancelled');
CREATE TYPE task_timing_type AS ENUM ('now','today','scheduled');
CREATE TYPE partner_type     AS ENUM ('gemeente','zorgverzekeraar','werkgever','organisatie','overig');


-- ============================================================
-- PROFILES (basis voor alle gebruikers, gekoppeld aan auth.users)
-- ============================================================

CREATE TABLE profiles (
    id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role         user_role NOT NULL,
    first_name   TEXT NOT NULL DEFAULT '',
    last_name    TEXT NOT NULL DEFAULT '',
    phone_number TEXT,
    -- Laagdrempelige demografie (optioneel) — alleen geaggregeerd/anoniem gebruikt.
    -- Zie MEGA_PROMPT_DATA_PRIVACY_LAAG.md voor de k-anonieme aggregatie-views.
    gender       TEXT,          -- 'vrouw' | 'man' | 'anders' (null = onbekend)
    birth_year   INTEGER,
    postcode4    TEXT,          -- 4-cijferige postcode (PC4)
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ELDERLY PROFILES (hulpvragers)
-- ============================================================

CREATE TABLE elderly_profiles (
    id                 UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    address            TEXT DEFAULT '',
    latitude           DOUBLE PRECISION,
    longitude          DOUBLE PRECISION,
    date_of_birth      DATE,
    -- De partner-koppelcode waarmee deze cliënt is toegelaten.
    linking_code_used  TEXT
);

-- ============================================================
-- BUDDY PROFILES (vrijwilligers)
-- ============================================================

CREATE TABLE buddy_profiles (
    id                      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    bio                     TEXT DEFAULT '',
    study                   TEXT DEFAULT '',
    avatar_system_name      TEXT DEFAULT 'person.crop.circle.fill',
    rating_average          DOUBLE PRECISION DEFAULT 0.0,
    total_tasks             INTEGER DEFAULT 0,
    -- Vertrouwen: VOG (gratis voor vrijwilligers) + korte intake.
    vog_valid               BOOLEAN DEFAULT FALSE,
    vog_expires_at          TIMESTAMPTZ,
    intake_completed        BOOLEAN DEFAULT FALSE,
    max_distance_km         INTEGER DEFAULT 10,
    is_available_now        BOOLEAN DEFAULT FALSE,
    is_onboarding_complete  BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- FAMILY PROFILES (mantelzorgers)
-- ============================================================

CREATE TABLE family_profiles (
    id           UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    relationship TEXT DEFAULT ''
);

-- ============================================================
-- FAMILY ↔ ELDERLY KOPPELING (via 6-cijferige welkomstcode)
-- ============================================================

CREATE TABLE family_elderly_links (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    elderly_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    linked_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, elderly_id)
);

-- 6-cijferige codes waarmee een familielid aan een bestaande oudere koppelt.
CREATE TABLE linking_codes (
    code        TEXT PRIMARY KEY,              -- bijv. "483921"
    elderly_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    expires_at  TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 year',
    used_at     TIMESTAMPTZ                    -- null = nog niet gebruikt
);

-- ============================================================
-- PARTNER-KOPPELCODES
-- Door admin uitgegeven aan gemeenten/verzekeraars/werkgevers. Clients
-- gebruiken zo'n code om zich op het platform aan te melden.
-- ============================================================

CREATE TABLE partner_codes (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code         TEXT NOT NULL UNIQUE,         -- bijv. "ZEIST2026"
    partner_name TEXT NOT NULL,                -- bijv. "Gemeente Zeist"
    partner_type partner_type NOT NULL DEFAULT 'overig',
    max_uses     INTEGER,                      -- null = onbeperkt
    used_count   INTEGER NOT NULL DEFAULT 0,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    expires_at   TIMESTAMPTZ                   -- null = geen verloopdatum
);

-- ============================================================
-- TAKEN (welzijn — geen niveau, geen prijs)
-- ============================================================

CREATE TABLE tasks (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    elderly_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    assigned_buddy_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
    -- Weergavevelden: een beschikbare buddy mag het profiel van een ouder niet
    -- lezen (RLS), dus de minimale weergave-info staat op de taakrij zelf.
    elderly_first_name   TEXT,
    elderly_latitude     DOUBLE PRECISION,
    elderly_longitude    DOUBLE PRECISION,
    category             task_category NOT NULL,
    timing_type          task_timing_type DEFAULT 'now',
    scheduled_at         TIMESTAMPTZ,
    note                 TEXT DEFAULT '',
    status               task_status DEFAULT 'open',
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    accepted_at          TIMESTAMPTZ,
    arrived_at           TIMESTAMPTZ,
    check_in_selfie_url  TEXT,
    completed_at         TIMESTAMPTZ,
    completion_note      TEXT,
    buddy_eta_minutes    INTEGER
);

-- Storage bucket voor optionele check-in selfies (aanmaken in Supabase dashboard)
-- Bucket naam: check-in-selfies — private, max 2MB JPEG.

-- ============================================================
-- BEOORDELINGEN
-- ============================================================

CREATE TABLE reviews (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id      UUID REFERENCES tasks(id) ON DELETE CASCADE,
    reviewer_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reviewee_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    stars        INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    body         TEXT DEFAULT '',
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SOS EVENTS
-- ============================================================

CREATE TABLE sos_events (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    elderly_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at  TIMESTAMPTZ,
    notes        TEXT DEFAULT ''
);

-- ============================================================
-- DEVICE TOKENS (APNs) — voor pushnotificaties
-- Eén gebruiker kan meerdere apparaten hebben. De Edge Function leest deze
-- tabel met de service-role (omzeilt RLS) om pushes te versturen.
-- ============================================================

CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token       TEXT NOT NULL UNIQUE,
    platform    TEXT NOT NULL DEFAULT 'ios',
    role        user_role,
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXEN (performance)
-- ============================================================

CREATE INDEX idx_tasks_status           ON tasks(status);
CREATE INDEX idx_tasks_elderly_id       ON tasks(elderly_id);
CREATE INDEX idx_tasks_buddy_id         ON tasks(assigned_buddy_id);
CREATE INDEX idx_tasks_created_at       ON tasks(created_at DESC);
CREATE INDEX idx_buddy_available        ON buddy_profiles(is_available_now);
CREATE INDEX idx_family_links_family    ON family_elderly_links(family_id);
CREATE INDEX idx_family_links_elderly   ON family_elderly_links(elderly_id);
CREATE INDEX idx_linking_codes_elderly  ON linking_codes(elderly_id);
CREATE INDEX idx_partner_codes_code     ON partner_codes(code);
CREATE INDEX idx_partner_codes_active   ON partner_codes(is_active);
CREATE INDEX idx_device_tokens_user     ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_role     ON device_tokens(role);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- AUTOMATISCH PROFIEL AANMAKEN BIJ REGISTRATIE
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, first_name, last_name, phone_number)
    VALUES (
        NEW.id,
        (NEW.raw_user_meta_data->>'role')::public.user_role,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.phone
    );

    IF (NEW.raw_user_meta_data->>'role') = 'elderly' THEN
        INSERT INTO public.elderly_profiles (id) VALUES (NEW.id);
    ELSIF (NEW.raw_user_meta_data->>'role') = 'buddy' THEN
        INSERT INTO public.buddy_profiles (id) VALUES (NEW.id);
    ELSIF (NEW.raw_user_meta_data->>'role') = 'family' THEN
        INSERT INTO public.family_profiles (id) VALUES (NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- BUDDY RATING AUTOMATISCH UPDATEN NA NIEUWE REVIEW
-- ============================================================

CREATE OR REPLACE FUNCTION update_buddy_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE buddy_profiles
    SET rating_average = (
        SELECT ROUND(AVG(stars)::numeric, 1)
        FROM reviews
        WHERE reviewee_id = NEW.reviewee_id
    ),
    total_tasks = (
        SELECT COUNT(*)
        FROM tasks
        WHERE assigned_buddy_id = NEW.reviewee_id
          AND status = 'completed'
    )
    WHERE id = NEW.reviewee_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_buddy_rating
    AFTER INSERT ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_buddy_rating();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE elderly_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE buddy_profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_elderly_links  ENABLE ROW LEVEL SECURITY;
ALTER TABLE linking_codes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_codes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews               ENABLE ROW LEVEL SECURITY;
ALTER TABLE sos_events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens         ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Trigger kan profielen aanmaken" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Eigen profiel lezen"            ON profiles FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Eigen profiel updaten"          ON profiles FOR UPDATE USING ((select auth.uid()) = id);

-- Elderly profiles
CREATE POLICY "Eigen elderly profiel" ON elderly_profiles FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Familie kan elderly profiel lezen" ON elderly_profiles FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = (select auth.uid()) AND elderly_id = elderly_profiles.id
    )
);
CREATE POLICY "Elderly kan eigen profiel updaten" ON elderly_profiles FOR UPDATE USING ((select auth.uid()) = id);

-- Buddy profiles: publiek leesbaar (nodig voor taakmatching op de kaart)
CREATE POLICY "Buddy profielen zijn publiek leesbaar" ON buddy_profiles FOR SELECT USING (TRUE);
CREATE POLICY "Buddy kan eigen profiel updaten" ON buddy_profiles FOR UPDATE USING ((select auth.uid()) = id);

-- Partner-koppelcodes: iedereen mag een code valideren bij aanmelden; beheer door admins.
CREATE POLICY "Iedereen kan koppelcode valideren" ON partner_codes FOR SELECT USING (TRUE);
CREATE POLICY "Admin kan koppelcodes aanmaken" ON partner_codes FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
);
CREATE POLICY "Admin kan koppelcodes beheren" ON partner_codes FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
);

-- Taken
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

-- Reviews
CREATE POLICY "Reviews zijn publiek leesbaar" ON reviews FOR SELECT USING (TRUE);
CREATE POLICY "Elderly kan review plaatsen" ON reviews FOR INSERT WITH CHECK (reviewer_id = (select auth.uid()));

-- SOS
CREATE POLICY "SOS events voor betrokkenen" ON sos_events FOR SELECT USING (
    elderly_id = (select auth.uid())
    OR EXISTS (
        SELECT 1 FROM family_elderly_links
        WHERE family_id = (select auth.uid()) AND elderly_id = sos_events.elderly_id
    )
);
CREATE POLICY "Elderly kan SOS aanmaken" ON sos_events FOR INSERT WITH CHECK (elderly_id = (select auth.uid()));

-- Linking codes (familie ↔ oudere)
CREATE POLICY "Elderly kan eigen codes lezen" ON linking_codes FOR SELECT USING (elderly_id = (select auth.uid()));
CREATE POLICY "Iedereen kan code valideren" ON linking_codes FOR SELECT USING (TRUE);

-- Device tokens: een gebruiker beheert uitsluitend zijn eigen tokens.
CREATE POLICY "Eigen device token toevoegen"  ON device_tokens FOR INSERT WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY "Eigen device tokens lezen"      ON device_tokens FOR SELECT USING (user_id = (select auth.uid()));
CREATE POLICY "Eigen device token updaten"     ON device_tokens FOR UPDATE USING (user_id = (select auth.uid()));
CREATE POLICY "Eigen device token verwijderen" ON device_tokens FOR DELETE USING (user_id = (select auth.uid()));

-- ============================================================
-- REALTIME — live updates op tasks (buddy ziet nieuwe verzoeken verschijnen)
-- ============================================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
