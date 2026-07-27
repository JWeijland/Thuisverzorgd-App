# MEGA-PROMPT — Maak "Thuisverzorgd" (vrijwilligers-versie) test-ready

> **Voor:** een AI-coding-agent (Claude) die in **deze repo** werkt.
> **Doel:** de app naar dezelfde "klaar om mee te testen"-status brengen als de Premium-versie,
> maar volgens het **vrijwilligersmodel** (géén geld, géén ZZP). Werk in kleine, controleerbare
> fases. **Bouw na elke fase** (`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator' build`)
> en houd de app altijd compileerbaar. Vraag niet om bevestiging — de keuzes hieronder staan vast.

---

## 0. Lees dit eerst — oriëntatie & vrijheid om te auditen

Je hebt **volledige vrijheid om de hele repo en alle documenten te lezen** om te bepalen wat er al
is en wat nog mist. Het kan zijn dat iets al bestaat — dat is prima, bevestig dat dan en ga door.
**Begin met een audit** voordat je iets bouwt.

**Lees in elk geval deze documenten:**
- `MEGA_PROMPT_WELZIJN_PIVOT.md` — de leidende ombouw van betaalde zorg → vrijwilligers-welzijn. **Dit is de bron van waarheid voor het model.**
- `MEGA_PROMPT_DATA_PRIVACY_LAAG.md` — de privacy-/analytics-laag.
- `TESTFLIGHT_SETUP.md` + `APP_REVIEW_NOTES.md` — wat nodig is om externe testers te laten testen.
- `supabase/SUPABASE_SETUP.md`, `supabase/REALDATA_SETUP.md`, `supabase/FASE2_PUSH_SETUP.md` — backend-setup.
- `supabase/schema.sql` + alle `supabase/migrations/fase1..fase13_*.sql` — het databaseschema, RLS, RPC's.

**Codebase-kaart (SwiftUI 6 `@Observable` + Supabase, iOS 17+):**
- `App/` — `AppState.swift` (demo-state + flows), `AppStateLive.swift` (live/Supabase-laag), `Config.swift` (feature flags), `RootView.swift`, `LoginView.swift`, `RoleSelectionView.swift`.
- `Services/` — `AuthService`, `ProfileService`, `TaskService`, `MatchingService`, `AnalyticsService`, `PushManager`, `SpeechService`, `AddressGeocoder`, `SupabaseManager` (DB-DTO's), `MockServices`.
- `Models/` — `Models.swift`, `MockData.swift`, `NotificationModels.swift`.
- `Elderly/`, `Buddy/`, `Family/`, `Admin/` — de vier rol-schillen met hun tabs/flows.
- `DesignSystem/` — `BCColors`, `BCTypography`, `BCComponents` (gebruik deze tokens/components, bouw geen nieuwe stijl).

**Belangrijk:** de app draait al in **twee modi naast elkaar**:
- **Live-modus** (`isLive == !isDemoMode && realUserId != nil`): echte Supabase-auth + Postgres.
- **Demo-modus** (`isDemoMode`): volledig op `MockData`, geen backend.

---

## 1. Harde principes (niet afwijken)

1. **Vrijwilligersmodel, géén geldstroom.** Geen betalen/verdienen/tarieven/commissie/wallet/ZZP/IBAN/KvK/BTW. (De Premium-versie heeft dat wél — dat is hier NIET de bedoeling.) Houd je aan `MEGA_PROMPT_WELZIJN_PIVOT.md`.
2. **Eén buddy-type, geen niveaus, geen medische taken.** Wel: korte intake (~5 min) + VOG verplicht voordat een buddy taken mag aannemen. Aanmelden/rondkijken mag direct.
3. **Clients (oudere/familie) hebben een koppelcode nodig** (uitgegeven via partner; admin genereert ze). Aanmelden moet verder heel makkelijk zijn.
4. **Mock-/demo-data NIET verwijderen.** De gebruiker wil de mock-data voorlopig blijven zien (verwijdert die later zelf). Zorg dat demo-modus blijft werken én dat er een duidelijke "demo: overslaan"-knop staat bij elke echte drempel (koppelcode, VOG, intake).
5. **UI in het Nederlands, code/comments in het Engels.** Geen Engelse termen die in de UI lekken. Geen medische/financiële termen.
6. **App altijd compileerbaar.** Werk per module; bouw na elke fase.
7. **Hergebruik het design system** (`BCColors`/`BCTypography`/`BCComponents`). Geen nieuwe visuele taal introduceren.

---

## 2. Wat "test-ready" concreet betekent — de opdracht

De gebruiker wil de app net zo ver hebben als de Premium-versie, maar vrijwillig. Werk de volgende
gebieden volledig af. Per gebied staat het **doel**, een **audit-checklist** (controleer eerst wat al
bestaat) en de **te leveren** wijzigingen.

### Fase A — Backend volledig kloppend (Supabase)

**Doel:** schema, RLS, migraties, RPC's en alle client-reads/writes zijn consistent en werken end-to-end.

**Audit eerst:**
- Loop `schema.sql` + alle `migrations/fase*.sql` na. Klopt elke tabel/kolom die de Swift-DTO's in `Services/SupabaseManager.swift` verwachten? (bv. `tasks.elderly_latitude/longitude`, `elderly_profiles.latitude/longitude/address`, `large_text_enabled`, `prefers_formal`, partner_codes, linking_codes, reviews, sos_events, intake_calls, vog-velden.)
- Controleer elke RLS-policy: kan elke rol precies doen wat de UI vraagt en niet meer? Let op **upsert vs update**: een `.upsert()` draait als INSERT en heeft een INSERT-policy nodig — gebruik `.update()` als de rij al door de `handle_new_user`-trigger bestaat.
- Check dat alle RPC's die de client aanroept bestaan (`ensure_my_linking_code`, `redeem_linking_code`, `my_linked_elderly`, analytics-functies, admin-functies).

**Te leveren:**
- Eén nieuwe migratie (`migrations/fase14_*.sql`) die alle ontbrekende kolommen/policies/indexen toevoegt die uit de audit komen. Idempotent schrijven (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`).
- Een kort overzicht (in de migratie-comments of een `supabase/AUDIT_FASE14.md`) van wat ontbrak en is rechtgezet.
- Verifieer dat élke schrijf-actie in de app onder live-modus echt persisteert (zie Fase F).

### Fase B — Privacy- én meldingen-toggles echt verwerken

**Doel:** de toggles doen wat ze beloven en worden opgeslagen.

**Audit eerst:**
- **Privacy/consent** is al echt gekoppeld (`ConsentService` / `ConsentSettingsCard` in `App/RootView.swift`, tabel-writes). **Verifieer** dat aan/uit direct persisteert en het verzamelen stopt/start.
- **Meldingen-toggles** zijn nu nog **cosmetisch** (`@State` in `ElderlyProfileView`, `BuddyProfileView`, `FamilyProfileView`) — ze worden **niet** opgeslagen.

**Te leveren:**
- Een `notification_preferences`-tabel (of kolommen op de bestaande profieltabellen) met RLS, plus DTO's en `ProfileService`-methodes om ze te lezen/schrijven.
- Koppel alle meldingen-toggles (elderly: reactie van buddy / herinnering; buddy: nieuwe hulpvraag in de buurt / berichten; family: per bezoek / SOS / maandrapport) aan die store, met laden bij openen en opslaan bij wijzigen (volg het patroon van `prefersFormal`/`largeTextEnabled` in `AppStateLive.applyRealProfile` + de preference-write-suppress-flag).
- Respecteer de voorkeuren in `PushManager` (registreer/deregistreer pushtoken, filter welke pushes verstuurd worden). `Config.enableRealPushNotifications` blijft de hoofd-schakelaar.
- Houd de UI consistent: alle drie de rollen gebruiken een ingeklapte `BCDisclosureSection` voor Meldingen + Privacy (niet prominent). Dit is recent al gelijkgetrokken — **verifieer en houd consistent.**

### Fase C — Adminpagina helemaal goed bouwen

**Doel:** een volwaardige beheerschil voor een vrijwilligersplatform.

**Audit eerst:** `Admin/AdminTabView.swift`, `Admin/AdminPhoneRequestView.swift`, `Admin/AdminMembershipsView.swift` + migraties `fase9_admin_hardening.sql`, `fase10_admin_user_management.sql`, `fase13_seed_partner_codes.sql`.

**Te leveren (vrijwilligersgericht — géén facturatie/fee-split):**
- **Overzicht/dashboard:** aantallen actieve buddies/ouderen/families, open/lopende/afgeronde hulpvragen, intakes te doen, VOG's in behandeling. Read-only stats (mag op de analytics-views leunen).
- **Koppelcodes (partner_codes):** lijst, aanmaken (partnernaam/type, max gebruik, vervaldatum), deactiveren, gebruiksteller. Verifieer RLS zodat alleen admin dit kan.
- **Gebruikersbeheer:** rollen bekijken/wijzigen (met de bestaande hardening dat je jezelf niet naar admin kunt escaleren — zie fase9).
- **Intakes & VOG:** lijst van buddies met intake/VOG-status; admin kan intake op "akkoord" en VOG op "geldig/afgewezen" zetten (mock-flow mag blijven, maar moet persisteren).
- **Telefonische aanvraag:** bestaande 4-staps-flow (oudere zoeken → categorie → timing → bevestigen) — afmaken en live laten schrijven via een admin-RPC (RLS staat normaal alleen de oudere zelf een insert toe; maak een `SECURITY DEFINER` RPC voor admin-namens-insert).
- **Instellingen:** account, meldingen, uitloggen — in het Nederlands.
- Alles netjes in het design system, Nederlandse labels, lege staten met `BCEmptyState`.

### Fase D — Locatie correct

**Doel:** adressen → coördinaten kloppen overal; kaarten centreren goed; permissies netjes.

**Audit eerst:** recent toegevoegd `Services/AddressGeocoder.swift` (CLGeocoder), gebruikt in `AppStateLive.createTaskLive` (geocode bij versturen + opslaan op profiel) en `ElderlyProfileView.save()` (geocode bij profiel opslaan). `ElderlyUser.coordinate` is nu `var`.

**Te leveren:**
- Verifieer dat een hulpvraag op het **echte adres van de hulpvrager** op de buddy-kaart komt (niet het default Amsterdam-centrum) en dat meerdere vragen niet meer op één punt stapelen.
- Dek de **familie-namens-flow** (`requestHelpOnBehalf`): die draait nu nog op mock; zorg dat ook daar de juiste coördinaat van de gekoppelde oudere wordt gebruikt (en, indien live mogelijk gemaakt, via admin/family-RPC).
- Controleer `Info.plist`-locatiepermissies en de tekst van de prompt (NL). Kaart centreert op de gebruiker/relevante taken.
- Optioneel: reverse-geocode voor nette adresweergave waar nu lege strings staan (`elderlyAddress: ""` in `serviceTask(from:)`).

### Fase E — Navigatie kloppend en volledig Nederlands

**Doel:** consistente, voorspelbare navigatie; geen Engelse UI-tekst.

**Te leveren:**
- Loop elke rol-schil na (tabs, sheets, `NavigationStack`, back-knoppen, titels). Consistente tab-bars en presentaties (detents, drag indicators).
- **Scan op Engelse UI-strings** die zichtbaar zijn voor de gebruiker en vertaal naar het Nederlands (code/comments mogen Engels blijven).
- Controleer dat elke flow een duidelijke afsluiting/terugweg heeft en dat diepe sheets niet "vastlopen".

### Fase F — Inloggen klaar + echte data genereren én opslaan (naast de mock-data)

**Doel:** testers kunnen een account maken, inloggen, en als ze de app gebruiken wordt hun data echt opgeslagen — terwijl de mock-/demo-data voorlopig zichtbaar blijft.

**Audit eerst:** `Services/AuthService.swift` heeft al `signUp`, `signIn`, `sendOTP/verifyOTP`, `signInWithApple`, `restoreSession`, `signOut`. `AppState.bootstrap/restoreSession` mapt de rol en roept `applyRealProfile`. `LoginView`/`RoleSelectionView` bestaan met demo-knoppen.

**Te leveren:**
- **Registratie + login werkend voor testers:** e-mail/wachtwoord (met e-mailbevestiging-flow indien aan in Supabase), wachtwoord-reset, en de OTP-/Apple-paden. Duidelijke **Nederlandse foutmeldingen** (verkeerd wachtwoord, e-mail al in gebruik, code verlopen, enz.).
- **Rol-toewijzing bij registratie** + de juiste onboarding-gating (buddy pas live na VOG+intake; client heeft koppelcode nodig, met demo-overslaan-knop).
- **Persistente data in live-modus:** controleer dat ál deze acties echt in Supabase landen en bij herstart terugkomen: hulpvraag aanmaken (`createTaskLive` ✓), taak accepteren/aankomen/afronden, review plaatsen, favorieten, voorkeuren (grote tekst / formeel), profiel (adres/telefoon/locatie), meldingsvoorkeuren (Fase B), consent. Vul ontbrekende persistentie aan.
- **Mock-data blijft zichtbaar:** demo-modus en `MockData` niet verwijderen. Zorg dat een ingelogde test-gebruiker zijn eigen echte data ziet, en dat de demo-knoppen los daarvan blijven werken.
- Werk waar nodig `TESTFLIGHT_SETUP.md`/`APP_REVIEW_NOTES.md` bij zodat externe testers kunnen starten.

### Fase G — Recent verbeterd (sinds ~gisteren) meenemen/verifiëren

Neem deze recente wijzigingen mee en controleer dat ze kloppen en consistent zijn doorgevoerd:
- **Locatie-fix via geocoding** (`AddressGeocoder`, `createTaskLive`, `ElderlyProfileView`, `ProfileService.updateElderlyLocation` — gebruik `.update()` niet `.upsert()` i.v.m. RLS).
- **Privacy/meldingen-toggles gelijkgetrokken** naar ingeklapte `BCDisclosureSection` op alle profielpagina's (niet prominent).
- **Partner-koppelcodes** geseed (`fase13_seed_partner_codes.sql`) + `partner_codes`-flow in `TaskService`.
- **Admin-gebruikersbeheer** (rollen wijzigen in-app) + **role-zelfescalatie geblokkeerd** (`fase9`).
- **Pool-/team-competitie feature** (`Buddy/BuddyPoolView.swift` + knop op `BuddyMapView`): buddies verzamelen samen punten voor prijzen (team-uitje / JBL boombox), front-end met voorbeelddata. **Te doen:** koppel later aan Supabase (`pools`, `pool_members`, punten per afgeronde taak) — voor nu mag het op voorbeelddata blijven, maar zet de datalaag klaar.
- Controleer zelf de laatste git-commits (`git log --oneline -20`) op nog meer recente verbeteringen en neem die mee.

---

## 3. Werkwijze & oplevering

1. **Eerst auditen**, dan een kort **faseplan** teruggeven (welke gaten je vond per fase A–G).
2. Werk fase voor fase. **Bouw na elke fase** en los compile-fouten direct op.
3. Nieuwe Swift-bestanden: vergeet niet ze aan `Buddy Care.xcodeproj/project.pbxproj` toe te voegen (de repo gebruikt **geen** auto-sync; voeg een `PBXBuildFile` + `PBXFileReference` + group-child + Sources-entry toe met **unieke** ID's — let op ID-botsingen).
4. Backend-wijzigingen altijd als **idempotente migratie** onder `supabase/migrations/`, plus een korte uitleg.
5. Houd je aan de harde principes (§1). Verwijder géén mock-/demo-data.
6. Lever per fase een korte changelog op (wat veranderd, welke bestanden, hoe getest).

**Definition of done:** een tester kan een account maken, inloggen in de juiste rol, de app gebruiken
met echte opslag in Supabase, terwijl demo-/mock-data blijft werken; backend/RLS kloppen; privacy- én
meldingen-toggles persisteren; admin is volwaardig; locatie en navigatie kloppen; alle UI is Nederlands;
de app compileert.
