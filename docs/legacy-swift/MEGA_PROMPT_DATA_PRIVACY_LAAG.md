# MEGA-PROMPT — Privacy-by-design datalaag voor Thuisverzorgd

> Uitvoeringsopdracht voor een AI-coding-agent (of mensontwikkelaar).
> Doel: een **legale, AVG-proof** datalaag die bruikbare (en op termijn verkoopbare)
> inzichten oplevert, zonder identificeerbare gegevens van kwetsbare ouderen te
> verhandelen. Gebouwd op de bestaande stack: Supabase (Postgres + RLS) +
> SwiftUI-client met de globale `supabase`-client.
>
> Stijl/conventies volgen het bestaande project: Nederlandse comments,
> idempotente SQL (`IF NOT EXISTS` / `DROP POLICY IF EXISTS`), enums, snake_case
> kolommen, Encodable `Insert`-structs met `CodingKeys` in Swift.

---

## 0. Juridische uitgangspunten (NIET onderhandelbaar)

Dit is een zorg-/welzijnsplatform voor kwetsbare ouderen. Houd je strikt aan:

1. **Doelbinding & dataminimalisatie.** Verzamel alleen wat een vooraf benoemd
   doel dient. Géén "alles opslaan voor later".
2. **Geen bijzondere persoonsgegevens (AVG art. 9).** Sla **nooit** gezondheids-,
   medische- of zorgbehoefte-details als analyse-event op. Categorie van een taak
   (`companionship`, `groceries`, …) mag — een diagnose of medische notitie niet.
3. **Pseudonimiseren, niet identificeren.** Events hangen aan een `user_id` (UUID),
   nooit aan naam/adres/telefoon/e-mail.
4. **Locatie altijd grof.** Sla **nooit** exacte lat/long in events op. Alleen een
   grove regio (gemeente of 4-cijferige postcode = "PC4").
5. **Verkoopbare laag = altijd geaggregeerd + k-anoniem.** Outputs die je deelt of
   verkoopt komen uitsluitend uit aggregatie-views met een **drempel van minimaal
   5** (groepen kleiner dan 5 worden onderdrukt). Verkoop nooit ruwe rijen.
6. **Toestemming is expliciet, specifiek en intrekbaar.** Opt-in (niet vooraf
   aangevinkt), per doel, met versie en tijdstempel vastgelegd. Intrekken stopt
   verzameling én verwijdert/anonimiseert lopende events.
7. **Transparantie.** Het privacybeleid (`legal/privacybeleid.html`) en de
   App Store privacy-labels beschrijven exact wat er gebeurt.

---

## 1. Architectuuroverzicht

```
   App (SwiftUI)                 Supabase (Postgres)
   ┌──────────────┐   insert     ┌────────────────────────┐
   │ ConsentMgr   │─────────────▶│ consents               │  (per gebruiker, per doel)
   │ AnalyticsSvc │─────────────▶│ analytics_events        │  (pseudonieme ruwe events, RLS)
   └──────────────┘              │      │                  │
                                 │      ▼  (SQL views)      │
                                 │ v_events_by_region_week  │  ← k-anoniem (≥5)
                                 │ v_task_demand_by_category│  ← k-anoniem (≥5)
                                 │ v_funnel_daily           │  ← k-anoniem (≥5)
                                 └────────────────────────┘
                                        │  oogsten
                                        ▼
                              Table Editor / SQL / dashboard / export
```

- **`consents`** — wie heeft waarvoor ja/nee gezegd (de juridische basis).
- **`analytics_events`** — pseudonieme ruwe events; alleen voor eigen app-gebruik,
  beschermd met RLS. Geen PII, geen exacte locatie, geen gezondheidsdetails.
- **Aggregatie-views** — de enige bron die je deelt/verkoopt; k-anoniem.

---

## 2. SQL — draai dit ÉÉN keer in Supabase → SQL Editor → New query → Run

> Volledig idempotent. Hoort bij het actieve project (zie URL/key in
> `Services/SupabaseManager.swift`). Plaats dit ook als
> `supabase/migrations/fase3_privacy_analytics.sql`.

```sql
-- ============================================================
-- Fase 3 — Privacy-by-design analytics
-- Pseudonieme events + expliciete toestemming + k-anonieme aggregatie.
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
        'help_requested',       -- ouder maakt hulpvraag (met categorie)
        'task_accepted',        -- buddy neemt aan
        'task_completed',
        'task_cancelled',
        'visit_checkin',
        'buddy_available_on',
        'buddy_available_off'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- 1. CONSENTS — de juridische basis, per gebruiker per doel
--    Append-only history: elke wijziging is een nieuwe rij.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS consents (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    purpose      consent_purpose NOT NULL,
    granted      BOOLEAN NOT NULL,
    policy_version TEXT NOT NULL DEFAULT 'v1',  -- versie van het privacybeleid
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_consents_user ON consents(user_id);

ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Eigen consent toevoegen" ON consents;
DROP POLICY IF EXISTS "Eigen consent lezen"     ON consents;
CREATE POLICY "Eigen consent toevoegen" ON consents
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Eigen consent lezen" ON consents
    FOR SELECT USING (user_id = auth.uid());

-- Huidige (laatste) keuze per gebruiker+doel.
CREATE OR REPLACE VIEW v_current_consent AS
SELECT DISTINCT ON (user_id, purpose)
       user_id, purpose, granted, policy_version, created_at
FROM consents
ORDER BY user_id, purpose, created_at DESC;

-- Helper: heeft deze gebruiker NU toestemming voor een doel?
CREATE OR REPLACE FUNCTION has_consent(p_user UUID, p_purpose consent_purpose)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        (SELECT granted FROM v_current_consent
         WHERE user_id = p_user AND purpose = p_purpose), FALSE);
$$;

-- ------------------------------------------------------------
-- 2. ANALYTICS_EVENTS — pseudonieme ruwe events
--    GEEN PII, GEEN exacte locatie, GEEN gezondheidsdetails.
--    region = grof (gemeente of PC4). props = minimale JSONB (bv. categorie).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics_events (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
    role        user_role,
    event_type  analytics_event_type NOT NULL,
    region      TEXT,            -- grove regio: gemeente of PC4, NOOIT exact adres
    category    task_category,   -- alleen bij taak-events; hergebruikt bestaande enum
    props       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- minimale, niet-identificeerbare extra's
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_events_type_time ON analytics_events(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_events_region    ON analytics_events(region);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- INSERT alleen voor jezelf, en ALLEEN als er toestemming is.
DROP POLICY IF EXISTS "Eigen event loggen met toestemming" ON analytics_events;
CREATE POLICY "Eigen event loggen met toestemming" ON analytics_events
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        AND has_consent(auth.uid(), 'product_analytics')
    );

-- Een gebruiker mag zijn eigen events lezen (transparantie / inzage-recht).
DROP POLICY IF EXISTS "Eigen events lezen" ON analytics_events;
CREATE POLICY "Eigen events lezen" ON analytics_events
    FOR SELECT USING (user_id = auth.uid());

-- Inzage-recht & recht op verwijdering (AVG): gebruiker mag eigen events wissen.
DROP POLICY IF EXISTS "Eigen events verwijderen" ON analytics_events;
CREATE POLICY "Eigen events verwijderen" ON analytics_events
    FOR DELETE USING (user_id = auth.uid());

-- ------------------------------------------------------------
-- 3. AGGREGATIE-VIEWS — de ENIGE verkoopbare/deelbare laag.
--    k-anonimiteit: groepen < 5 worden onderdrukt (HAVING COUNT(*) >= 5).
--    Geen user_id, geen herleidbaarheid.
-- ------------------------------------------------------------

-- Vraag naar hulp per regio per week.
CREATE OR REPLACE VIEW v_events_by_region_week AS
SELECT region,
       date_trunc('week', created_at)::date AS week,
       event_type,
       COUNT(*) AS aantal
FROM analytics_events
WHERE region IS NOT NULL
GROUP BY region, week, event_type
HAVING COUNT(*) >= 5;

-- Welke soorten hulp zijn het meest gevraagd, per regio.
CREATE OR REPLACE VIEW v_task_demand_by_category AS
SELECT region,
       category,
       date_trunc('month', created_at)::date AS maand,
       COUNT(*) AS aantal
FROM analytics_events
WHERE event_type = 'help_requested' AND category IS NOT NULL AND region IS NOT NULL
GROUP BY region, category, maand
HAVING COUNT(*) >= 5;

-- Funnel: hulpvraag → aangenomen → afgerond, per dag (landelijk).
CREATE OR REPLACE VIEW v_funnel_daily AS
SELECT date_trunc('day', created_at)::date AS dag,
       COUNT(*) FILTER (WHERE event_type = 'help_requested') AS hulpvragen,
       COUNT(*) FILTER (WHERE event_type = 'task_accepted')  AS aangenomen,
       COUNT(*) FILTER (WHERE event_type = 'task_completed') AS afgerond
FROM analytics_events
GROUP BY dag
HAVING COUNT(*) >= 5;

-- ============================================================
-- KLAAR. Ruwe events zie je in Table Editor → analytics_events.
-- De DEELBARE inzichten zie je via de v_*-views (SQL editor / dashboard / export).
-- ============================================================
```

---

## 3. Swift — toestemming & event-logging

### 3a. `Services/ConsentService.swift` (nieuw)

Schrijft een toestemmingskeuze weg. Append-only (elke keuze = nieuwe rij), zodat
intrekken traceerbaar is.

```swift
import Foundation
import Supabase

enum ConsentPurpose: String { case productAnalytics = "product_analytics"
                                    case researchInsights = "research_insights" }

struct ConsentService {
    static let policyVersion = "v1"

    func setConsent(userId: UUID, purpose: ConsentPurpose, granted: Bool) async throws {
        struct Insert: Encodable {
            let userId: UUID; let purpose: String; let granted: Bool; let policyVersion: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case purpose; case granted
                case policyVersion = "policy_version"
            }
        }
        try await supabase.from("consents").insert(Insert(
            userId: userId, purpose: purpose.rawValue,
            granted: granted, policyVersion: Self.policyVersion
        )).execute()
    }
}
```

### 3b. `Services/AnalyticsService.swift` (nieuw)

Eén centrale `track`. **Faalt stil** (analytics mag de app nooit blokkeren) en
verstuurt alleen grove, niet-identificeerbare velden. De RLS-policy weigert de
insert sowieso als er geen toestemming is — dubbele bescherming.

```swift
import Foundation
import Supabase

enum AnalyticsEvent: String {
    case appOpen = "app_open"
    case helpRequested = "help_requested"
    case taskAccepted = "task_accepted"
    case taskCompleted = "task_completed"
    case taskCancelled = "task_cancelled"
    case visitCheckin = "visit_checkin"
    case buddyAvailableOn = "buddy_available_on"
    case buddyAvailableOff = "buddy_available_off"
}

struct AnalyticsService {
    /// Log een event. region = grove regio (gemeente of PC4), NOOIT exact adres.
    func track(_ event: AnalyticsEvent,
               userId: UUID?,
               role: String?,
               region: String?,
               category: String? = nil) async {
        struct Insert: Encodable {
            let userId: UUID?; let role: String?; let eventType: String
            let region: String?; let category: String?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case role; case eventType = "event_type"
                case region; case category
            }
        }
        do {
            try await supabase.from("analytics_events").insert(Insert(
                userId: userId, role: role, eventType: event.rawValue,
                region: region, category: category
            )).execute()
        } catch {
            // Stil falen: nooit de UX blokkeren op analytics. Evt. lokaal loggen in DEBUG.
            #if DEBUG
            print("analytics track failed:", error)
            #endif
        }
    }
}
```

### 3c. Grove regio afleiden (helper)

**Verstuur nooit exacte coördinaten als event.** Leid een grove regio af. Simpelste
veilige variant: rond af op ~1 decimaal (≈ 11 km hokje) of gebruik gemeente/PC4 als
die al bekend is uit het profiel.

```swift
extension CLLocationCoordinate2D {
    /// Grove regiocode (~11 km), bewust onnauwkeurig voor privacy.
    var coarseRegion: String {
        String(format: "%.1f,%.1f", latitude, longitude)
    }
}
```

> Beter nog: als je later PC4 of gemeentenaam in het profiel hebt, gebruik die als
> `region`. Dat is begrijpelijker voor afnemers én niet herleidbaar.

### 3d. Toestemmingsscherm in de onboarding

Voeg in `Buddy/BuddyOnboardingFlow.swift` en de ouder-/familie-onboarding één
opt-in-stap toe (niet vooraf aangevinkt), met twee losse schakelaars:

- "Help de app verbeteren (anonieme gebruiksstatistieken)" → `product_analytics`
- "Draag bij aan anonieme inzichten over welzijn in de buurt" → `research_insights`

Met een korte uitleg + link naar het privacybeleid. Sla beide keuzes op via
`ConsentService.setConsent`. Toon dezelfde schakelaars later in het profiel zodat
men ze kan **intrekken**.

### 3e. Aanroeppunten (alleen waar het logisch is)

| Plek | Event |
|---|---|
| App-start (na login) | `appOpen` |
| `AppState` hulpvraag aangemaakt | `helpRequested` (+ `category`, `region`) |
| Buddy neemt taak aan | `taskAccepted` |
| Taak afgerond | `taskCompleted` |
| Taak geannuleerd | `taskCancelled` |
| Check-in voltooid | `visitCheckin` |
| Beschikbaarheid aan/uit | `buddyAvailableOn` / `buddyAvailableOff` |

---

## 4. Recht op intrekken / verwijderen (AVG-plicht)

- **Intrekken:** nieuwe `consents`-rij met `granted = false`. Daarna weigert de
  RLS-policy nieuwe events automatisch.
- **Verwijderen:** gebruiker kan eigen `analytics_events` wissen (policy aanwezig).
  Bouw in het profiel een knop "Verwijder mijn gebruiksgegevens".
- **Inzage:** gebruiker kan eigen events lezen (policy aanwezig) → toon evt. een
  simpel overzicht.

---

## 5. App Store & beleid

1. **Privacy-labels (App Store Connect):** declareer "Usage Data" / "Product
   Interaction", gekoppeld aan gebruiker, **niet** gebruikt voor tracking/derden-ads.
   Als je `research_insights` aan derden levert: alleen **geaggregeerd/anoniem** —
   dat is geen "tracking" in Apple's zin, mits niet herleidbaar.
2. **Privacybeleid** (`legal/privacybeleid.html`): voeg een sectie toe — welke
   events, welk doel, grove locatie, k-anonieme aggregatie, met wie gedeeld,
   bewaartermijn, en hoe in te trekken/verwijderen.
3. **Bewaartermijn:** zet een redelijke termijn op ruwe events (bv. 14 maanden) en
   plan periodieke opschoning (Supabase scheduled function) — aggregaties blijven.

---

## 6. WAT JE NIET DOET (harde grenzen)

- ❌ Ruwe rijen (row-level) verkopen of delen.
- ❌ Naam/adres/telefoon/e-mail/exacte locatie in events.
- ❌ Gezondheids- of zorgbehoefte-details als event (bijzondere persoonsgegevens).
- ❌ Aggregaties tonen over groepen < 5 personen.
- ❌ Events verzamelen zonder geldige, actuele toestemming.
- ❌ Vooraf aangevinkte toestemming of "akkoord = doorgaan zonder keuze".

---

## 7. Operationeel — hoe je er straks bij komt

- **Bouwen:** SQL hierboven één keer in de SQL Editor draaien (en als migration opslaan).
- **Vullen:** gebeurt vanzelf vanuit de app zodra gebruikers toestemming geven en de app gebruiken.
- **Oogsten:**
  - Ruwe events: Table Editor → `analytics_events` (alleen voor debugging/inzage).
  - Bruikbare/deelbare inzichten: SQL Editor → `SELECT * FROM v_task_demand_by_category;`
    (en de andere `v_*`-views). Exporteer naar CSV, of bouw er een dashboard op.

---

## 8. Acceptatiecriteria

- [ ] SQL draait idempotent zonder fouten; tabellen + views + policies bestaan.
- [ ] Zonder toestemming wordt een event-insert door RLS geweigerd.
- [ ] Na opt-in stromen events binnen; zichtbaar in `analytics_events`.
- [ ] `v_*`-views bevatten nooit groepen < 5 en geen `user_id`.
- [ ] Intrekken stopt nieuwe events; verwijderknop wist eigen events.
- [ ] Geen PII / exacte locatie / gezondheidsdetails in enige event-rij.
- [ ] Privacybeleid + App Store privacy-labels bijgewerkt.
- [ ] Demografie (geslacht/geboortejaar/PC4) staat op `profiles`, gevuld vanuit de
      registratie-metadata; de demografische views zijn k-anoniem (≥5).

---

## 9. Demografie bij registratie (extra inzicht voor gemeenten)

Bij registratie vult **iedere** gebruiker laagdrempelig drie optionele velden in:
**geslacht**, **geboortejaar** en **4-cijferige postcode (PC4)**. Dit gebeurt al in
de app (`App/LoginView.swift` → `demographicsSection`, doorgegeven via
`AuthService.signUp` als user-metadata `gender` / `birth_year` / `postcode4`).

> Dit is **gewone** persoonsdata (geen bijzondere categorie), maar nog steeds
> persoonsgegeven. Verzamelen mag met een grondslag (toestemming/uitvoering); het
> **delen/verkopen** gebeurt uitsluitend via de **geaggregeerde, k-anonieme** views
> hieronder. Geslacht/leeftijd/PC4 worden nooit per persoon gedeeld.

### 9a. Kolommen op `profiles` + trigger vanuit registratie-metadata

```sql
-- Demografie op het basis-profiel.
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender      TEXT;   -- 'vrouw'|'man'|'anders'
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS birth_year  INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS postcode4   TEXT;   -- 4 cijfers (PC4)

-- Leeftijdsband afgeleid uit geboortejaar (banden voorkomen herleidbaarheid).
CREATE OR REPLACE FUNCTION age_band(p_birth_year INTEGER)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_birth_year IS NULL THEN 'onbekend'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 30  THEN '<30'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 50  THEN '30-49'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 65  THEN '50-64'
        WHEN (EXTRACT(YEAR FROM NOW())::int - p_birth_year) < 80  THEN '65-79'
        ELSE '80+'
    END;
$$;

-- De bestaande "nieuwe gebruiker"-trigger die profiles vult uit auth-metadata
-- moet deze drie velden meenemen. Voorbeeld-functie (pas aan op je eigen trigger):
CREATE OR REPLACE FUNCTION handle_new_user_demographics()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE profiles SET
        gender     = COALESCE(NEW.raw_user_meta_data->>'gender', gender),
        birth_year = COALESCE((NEW.raw_user_meta_data->>'birth_year')::int, birth_year),
        postcode4  = COALESCE(NEW.raw_user_meta_data->>'postcode4', postcode4)
    WHERE id = NEW.id;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_new_user_demographics ON auth.users;
CREATE TRIGGER trg_new_user_demographics
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user_demographics();
```

### 9b. Demografische aggregatie-views (k-anoniem, ≥5)

```sql
-- Gebruikers per regio × leeftijdsband × geslacht (voor gemeente-rapportage).
CREATE OR REPLACE VIEW v_demographics_by_region AS
SELECT postcode4,
       age_band(birth_year) AS leeftijdsband,
       gender,
       role,
       COUNT(*) AS aantal
FROM profiles
WHERE postcode4 IS NOT NULL
GROUP BY postcode4, leeftijdsband, gender, role
HAVING COUNT(*) >= 5;

-- Hulpvraag gekoppeld aan demografie van de aanvrager (via analytics_events.region
-- = PC4 en een join op leeftijdsband/geslacht), per maand. Alleen k-anoniem.
CREATE OR REPLACE VIEW v_demand_by_demographics AS
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
```

> Dit is precies wat een gemeente/verzekeraar wil: "in PC4 1011, leeftijdsband 80+,
> stijgt de vraag naar gezelschap" — waardevol én niet herleidbaar tot een persoon.

### 9c. Grenzen specifiek voor demografie

- ❌ Nooit `birth_year`/exact geboortejaar in een gedeelde view — gebruik altijd
  `age_band(...)`.
- ❌ Nooit `profiles`-rijen (met naam) exporteren; alleen de `v_*`-views.
- ✅ Bij twijfel: verhoog de k-drempel (≥5 → ≥10) voor kleine postcodes.
