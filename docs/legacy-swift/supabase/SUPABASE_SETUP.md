# Buddy Care — Supabase Master Setup

Dit document bevat **alles** wat je in Supabase moet uitvoeren, in volgorde.
Elke stap geeft aan of je hem in de **SQL Editor** of via het **Dashboard** uitvoert.

---

## Situatie A — Verse database (nog nooit gerund)

Voer **Stap 1 t/m 6** uit in volgorde.

## Situatie B — Schema bestaat al (je hebt schema.sql eerder gerund)

Voer **alleen Stap 2, 3, 4, 5 en 6** uit.

---

## Stap 1 — Volledig schema aanmaken

> **Waar:** Supabase → SQL Editor → New query → plak → Run
> **Wanneer:** alleen bij verse database

Plak de volledige inhoud van `schema.sql` en klik **Run**.

Schema.sql staat in: `supabase/schema.sql`

Controleer daarna of dit slaagt (geen rode foutmeldingen). Als je een fout ziet
als `already exists`, zit je in Situatie B en sla je deze stap over.

---

## Stap 2 — Migration: check-in selfie URL kolom

> **Waar:** Supabase → SQL Editor → New query → plak → Run
> **Wanneer:** altijd uitvoeren (ook als schema al bestaat)

```sql
-- Kolom toevoegen als hij nog niet bestaat
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS check_in_selfie_url TEXT;
```

---

## Stap 3 — Storage bucket aanmaken

> **Waar:** Supabase → Storage → New bucket
> **Wanneer:** altijd uitvoeren

1. Ga naar **Storage** in het linkermenu
2. Klik **New bucket**
3. Vul in:
   - **Name:** `check-in-selfies`
   - **Public bucket:** ❌ UIT (private)
   - **File size limit:** `2097152` (= 2 MB)
   - **Allowed MIME types:** `image/jpeg`
4. Klik **Save**

---

## Stap 4 — Storage RLS policies (selfie bucket)

> **Waar:** Supabase → SQL Editor → New query → plak → Run
> **Wanneer:** direct na Stap 3

```sql
-- Buddy mag alleen uploaden naar map die begint met een task-id
-- waarvoor hij de toegewezen buddy is
CREATE POLICY "Buddy kan eigen check-in selfie uploaden"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'check-in-selfies'
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM tasks
        WHERE assigned_buddy_id = auth.uid()
    )
);

-- Buddy mag eigen selfies lezen
CREATE POLICY "Buddy kan eigen selfies lezen"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'check-in-selfies'
    AND (storage.foldername(name))[1] IN (
        SELECT id::text FROM tasks
        WHERE assigned_buddy_id = auth.uid()
           OR elderly_id = auth.uid()
    )
);

-- Service role (backoffice) mag alles lezen — voor geschilafhandeling
CREATE POLICY "Service role kan alle selfies lezen"
ON storage.objects
FOR SELECT
TO service_role
USING (bucket_id = 'check-in-selfies');
```

---

## Stap 5 — Realtime inschakelen voor taken

> **Waar:** Supabase → Database → Replication
> **Wanneer:** altijd uitvoeren (nodig voor live taakupdates op de kaart)

1. Ga naar **Database** → **Replication**
2. Klik op **0 tables** (of het huidige getal) naast `supabase_realtime`
3. Zet de toggle **AAN** voor de tabel **`tasks`**
4. Klik **Save**

Of via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
```

---

## Stap 6 — Auth instellingen

> **Waar:** Supabase → Authentication → Providers & Settings
> **Wanneer:** eenmalig configureren

### 6a. E-mail provider
1. Ga naar **Authentication** → **Providers** → **Email**
2. Zet **Enable Email provider** AAN
3. Kies: **Confirm email** → afhankelijk van je testflow:
   - Voor TestFlight intern: zet het **UIT** (makkelijker testen)
   - Voor publieke beta: zet het **AAN**
4. Klik **Save**

### 6b. Wachtwoordloze OTP (voor ouderen)
1. Ga naar **Authentication** → **Providers** → **Phone**
2. Zet **Enable Phone provider** AAN
3. Kies SMS provider: **Twilio** (maak apart Twilio account aan)
   - Account SID: `[jouw Twilio SID]`
   - Auth token: `[jouw Twilio token]`
   - Message service SID: `[jouw Twilio service SID]`
4. Klik **Save**

> **Zonder Twilio:** OTP via telefoon werkt niet. Voor de eerste TestFlight-ronde
> kun je alleen e-mail + wachtwoord gebruiken. Dat is voldoende.

### 6c. Apple Sign-In (optioneel, voor TestFlight)
1. Ga naar **Authentication** → **Providers** → **Apple**
2. Vul in:
   - **Service ID:** `[Apple Service ID uit developer portal]`
   - **Secret key:** `[gegenereerde .p8 key]`
3. Klik **Save**

---

## Stap 7 — Verificatie: alles werkt

> **Waar:** Supabase → SQL Editor
> **Wanneer:** na alle bovenstaande stappen

Voer deze queries uit om te controleren dat alles correct is ingesteld:

```sql
-- 1. Controleer dat alle tabellen bestaan
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Verwacht: buddy_profiles, certifications, course_progress, earnings,
--           elderly_profiles, family_elderly_links, family_profiles,
--           linking_codes, profiles, reviews, sos_events, tasks

-- 2. Controleer dat check_in_selfie_url bestaat in tasks
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tasks'
ORDER BY ordinal_position;

-- Verwacht: check_in_selfie_url TEXT aanwezig tussen arrived_at en completed_at

-- 3. Controleer RLS is ingeschakeld op alle tabellen
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verwacht: rowsecurity = true voor alle tabellen

-- 4. Controleer alle RLS policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 5. Controleer Storage bucket bestaat
SELECT id, name, public
FROM storage.buckets;

-- Verwacht: check-in-selfies, public = false

-- 6. Controleer triggers
SELECT trigger_name, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- Verwacht: on_auth_user_created, trg_profiles_updated_at, trg_update_buddy_rating
```

---

## Stap 8 — Eerste testgebruiker aanmaken

> **Waar:** Supabase → Authentication → Users → Add user
> **Wanneer:** voor de eerste interne TestFlight-test

Maak handmatig twee testaccounts aan:

### Testbuddy
1. Klik **Add user** → **Create new user**
2. E-mail: `testbuddy@buddycare.nl`
3. Wachtwoord: `Test1234!`
4. Klik **Create user**

Voer daarna dit SQL uit om het profiel compleet te maken:
```sql
-- Vervang [UUID] met het UUID dat je net zag bij de aangemaakte user
INSERT INTO profiles (id, role, first_name, last_name)
VALUES ('[UUID]', 'buddy', 'Test', 'Buddy');

INSERT INTO buddy_profiles (id, level, kyc_verified, vog_valid, is_onboarding_complete)
VALUES ('[UUID]', 0, true, true, true);
```

### Testoudere
1. Klik **Add user** → **Create new user**
2. E-mail: `testoudere@buddycare.nl`
3. Wachtwoord: `Test1234!`
4. Klik **Create user**

```sql
-- Vervang [UUID] met het UUID van de oudere
INSERT INTO profiles (id, role, first_name, last_name, phone_number)
VALUES ('[UUID]', 'elderly', 'Riet', 'van der Berg', '0612345678');

INSERT INTO elderly_profiles (id, address, latitude, longitude)
VALUES ('[UUID]', 'Aelbrechtskade 142, Rotterdam', 51.9183, 4.4541);
```

---

## Stap 9 — Welkomstcode aanmaken voor testoudere

> **Waar:** Supabase → SQL Editor

Zodat een familielid gekoppeld kan worden:

```sql
-- Vervang [ELDERLY_UUID] met het UUID van de testoudere
INSERT INTO linking_codes (code, elderly_id, expires_at)
VALUES ('123456', '[ELDERLY_UUID]', NOW() + INTERVAL '1 year');
```

---

## Overzicht: wat is waar te vinden in Supabase

| Onderdeel | Locatie in Supabase |
|---|---|
| Tabellen bekijken | Table Editor |
| SQL uitvoeren | SQL Editor |
| Gebruikers beheren | Authentication → Users |
| Auth providers instellen | Authentication → Providers |
| Storage buckets | Storage |
| Realtime instellingen | Database → Replication |
| API keys | Project Settings → API |
| Logs bekijken | Logs |

---

## Supabase project gegevens

- **Project URL:** `https://oopmfcymxjataisfhryq.supabase.co`
- **Publishable key:** zit in `Services/SupabaseManager.swift`
- **Service role key:** ⚠️ staat NIET in de app (terecht) — alleen gebruiken
  in de Supabase dashboard of een backend, nooit in de iOS app

---

## Nog niet geïmplementeerd (voor latere fase)

Deze tabellen ontbreken nog in het schema en zijn nu volledig mock in de app.
Niet nodig voor de eerste TestFlight.

```sql
-- Organisaties ("Takken") — nu volledig mock in de app
CREATE TABLE organizations (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                    TEXT NOT NULL,
    short_name              TEXT NOT NULL,
    logo_symbol             TEXT DEFAULT 'building.2.fill',
    buddy_hourly_rate_cents INTEGER NOT NULL,
    markup_percent          DECIMAL(5,2) DEFAULT 20.0,
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE organization_memberships (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_role       user_role NOT NULL,
    status          TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    proof_note      TEXT DEFAULT '',
    admin_note      TEXT,
    submitted_at    TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at     TIMESTAMPTZ,
    UNIQUE(user_id, organization_id)
);
```
