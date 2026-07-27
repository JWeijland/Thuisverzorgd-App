# MEGA-PROMPT — Maak "Thuisverzorgd Premium" test-ready

> **Voor:** een AI-coding-agent (Claude) die in de **Premium**-repo werkt (de betaalde marktplaats-versie
> met ZZP-buddies). Dit is een **andere repo** dan de vrijwilligers-versie — verwacht **niet** dezelfde
> bestandsnamen; ontdek de structuur zelf via een audit.
> **Doel:** de app naar "klaar om mee te testen" brengen, **met behoud van het betaalmodel** (betalingen
> display-only via demo, ZZP, wallet, 20% commissie — later echt via Mollie). Werk in kleine,
> controleerbare fases, **bouw na elke fase** en houd de app altijd compileerbaar. Vraag niet om
> bevestiging — de keuzes hieronder staan vast.

---

## 0. Lees dit eerst — oriëntatie & vrijheid om te auditen

Je hebt **volledige vrijheid om de hele repo en alle documenten te lezen**. **Begin met een audit**
voordat je iets bouwt. Het kan zijn dat iets al bestaat — dat is prima, bevestig dat dan en ga door.

> **Let op:** deze prompt is gemaakt op basis van een zustermap (een vrijwilligers-variant van dezelfde
> app). De *functionele doelen* hieronder kloppen, maar **bestandsnamen/paden kunnen in deze Premium-repo
> anders zijn**. Waar een concreet bestand wordt genoemd, behandel dat als "zoek het equivalent in deze
> repo". Hardcode niets blind.

**Doe als eerste deze audit en geef een kort verslag terug:**
1. `git log --oneline -25` — wat is recent gewijzigd?
2. Lees alle `*.md`-documenten in de repo (setup, testflight, privacy, eventuele mega-prompts/specs).
3. Inventariseer de codebase: de rol-schillen (oudere / buddy / familie / admin), de services-laag, het
   datamodel, het design system, en de Supabase-laag (`supabase/schema.sql` + alle migraties + RPC's).
4. Stel vast welke **feature flags** er zijn (bv. `Config.enableRealPayments`, `Config.platformCommissionPercent`,
   push/SMS-flags) en wat hun huidige waarden zijn.
5. Stel vast welke **draaimodi** bestaan (echte Supabase-modus + demo/mock-modus) en hoe daartussen wordt geschakeld.

---

## 1. Harde principes (niet afwijken)

1. **Behoud het Premium/betaalmodel.** Betalingen, uurtarieven, 20% platformcommissie, wallet/verdiensten,
   ZZP-onboarding (KvK/BTW/IBAN) blijven bestaan. **Verwijder dit NIET.**
2. **Betalingen blijven voorlopig display-only.** Houd `enableRealPayments = false`: bedragen worden
   getoond, niet geïnd. Betaalde extra's lopen via de bestaande demo-betaaldienst (slaagt altijd) — zo
   gebouwd dat Mollie er later in past **zonder UI-wijziging**. Bouw Mollie nu **niet** echt in.
3. **Mock-/demo-data NIET verwijderen.** De gebruiker wil de mock-data voorlopig blijven zien (verwijdert
   die later zelf). Demo-modus moet blijven werken, met een duidelijke "demo: overslaan"-knop bij elke
   echte drempel (account, ZZP, VOG, intake, betaling).
4. **UI in het Nederlands, code/comments in het Engels.** Geen Engelse termen die in de UI lekken.
5. **App altijd compileerbaar.** Werk per module; **bouw na elke fase** (gebruik het juiste scheme/destination
   van deze repo) en los compile-fouten direct op.
6. **Hergebruik het bestaande design system** (kleuren/typografie/componenten). Introduceer geen nieuwe
   visuele taal.
7. **Verander het verdienmodel niet** (geen WMO/PGB/gemeente/subsidie/verzekering — bewust buiten scope,
   net als nu).

---

## 2. Wat "test-ready" concreet betekent — de opdracht

Werk de volgende gebieden volledig af. Per gebied: **doel**, **audit-checklist** (controleer eerst wat al
bestaat) en **te leveren** wijzigingen. Pas alles toe op de werkelijke structuur van déze repo.

### Fase A — Backend volledig kloppend (Supabase)

**Doel:** schema, RLS, migraties, RPC's en alle client-reads/writes zijn consistent en werken end-to-end —
inclusief de betaal-/verdien-tabellen (earnings, betalingen display-only).

**Audit eerst:**
- Loop `schema.sql` + alle migraties na. Klopt elke tabel/kolom die de Swift-DB-DTO's verwachten?
  (profielen per rol, taken incl. coördinaten/adres, reviews, earnings/betalingen, sos, koppel-/linking-codes,
  intakes, VOG-velden, voorkeuren zoals grote tekst / formeel aanspreken, consent/analytics.)
- Controleer elke RLS-policy: kan elke rol precies doen wat de UI vraagt en niet meer?
  **Let op upsert vs update:** een `.upsert()` draait als INSERT en vereist een INSERT-policy — gebruik
  `.update()` wanneer de rij al door de signup-trigger (`handle_new_user`-achtig) bestaat.
- Check dat alle aangeroepen RPC's bestaan (koppelcode-flow, analytics-functies, eventuele admin-/namens-RPC's).

**Te leveren:**
- Eén nieuwe, **idempotente** migratie (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`) die alle gaten dicht
  die uit de audit komen, plus een kort `AUDIT_*.md` met wat ontbrak en is rechtgezet.
- Verifieer dat élke schrijf-actie in live-modus echt persisteert (zie Fase F), óók earnings/betaalstatus
  (display-only mag, maar de records moeten kloppen voor de wallet/facturatie).

### Fase B — Privacy- én meldingen-toggles echt verwerken

**Doel:** de toggles doen wat ze beloven en worden opgeslagen.

**Audit eerst:**
- Is **privacy/consent** al echt gekoppeld aan een service/tabel? Zo ja: verifieer dat aan/uit direct
  persisteert en het verzamelen stopt/start. Zo nee: bouw het (gepseudonimiseerd/geaggregeerd, k-anoniem).
- Zijn de **meldingen-toggles** echt opgeslagen of nog cosmetisch (`@State` zonder persistentie)?

**Te leveren:**
- Een `notification_preferences`-tabel (of kolommen op de profieltabellen) met RLS, plus DTO's en
  service-methodes om te lezen/schrijven.
- Koppel alle meldingen-toggles per rol aan die store (laden bij openen, opslaan bij wijzigen), volgens het
  bestaande patroon van andere voorkeuren (bv. grote tekst / formeel aanspreken).
- Respecteer de voorkeuren in de push-laag (registreer/deregistreer pushtoken; filter welke pushes worden
  verstuurd). De bestaande push-feature-flag blijft de hoofd-schakelaar.
- **UI-consistentie:** zet Privacy én Meldingen op alle profielpagina's in een **ingeklapte disclosure-sectie**
  (niet prominent), zodat elke rol dit identiek en rustig toont.

### Fase C — Adminpagina helemaal goed bouwen

**Doel:** een volwaardige beheerschil voor de Premium-marktplaats.

**Audit eerst:** de bestaande admin-schil (overzicht/facturatie, telefonische aanvraag, instellingen) +
bijbehorende migraties/policies.

**Te leveren (Premium — mét facturatie):**
- **Facturatie-/verdienoverzicht:** alle service-records, filter per maand, totalen (klant betaalt /
  buddy verdient / platformfee 20%), per regel de buddy→oudere-koppeling en de fee-split (display-only).
- **Dashboard-stats:** aantallen actieve buddies/ouderen/families, open/lopende/afgeronde taken,
  intakes te doen, VOG's in behandeling (read-only, mag op analytics-views leunen).
- **Telefonische aanvraag:** de meerstaps-flow (oudere zoeken → categorie → timing → bevestigen) afmaken en
  **live laten schrijven** via een `SECURITY DEFINER`-RPC voor admin-namens-insert (RLS staat normaal alleen
  de oudere zelf een insert toe).
- **Gebruikers-/koppelcodebeheer** indien van toepassing: rollen bekijken/wijzigen met hardening
  (geen zelf-escalatie naar admin), koppelcodes aanmaken/deactiveren.
- **Intakes & VOG:** lijst met status; admin kan intake op "akkoord" en VOG op "geldig/afgewezen" zetten
  (mock-flow mag blijven, maar moet persisteren).
- **Instellingen:** account, meldingen, beveiliging, uitloggen — Nederlands. Lege staten netjes met de
  empty-state-component.

### Fase D — Locatie correct

**Doel:** adressen → coördinaten kloppen overal; kaarten centreren goed; permissies netjes.

**Audit eerst:** hoe wordt nu een coördinaat bepaald bij een taak en op het profiel? Wordt het adres
**gegeocodeerd**, of valt het terug op een default (bv. stadscentrum)?

**Te leveren (overgenomen uit de zustermap — implementeer in déze repo's stijl):**
- Een **geocoder-helper** (CLGeocoder, geen API-key) die een adres → coördinaat omzet.
- Geocodeer en **persisteer** de coördinaat (a) bij het opslaan van het profiel-adres en (b) bij het
  aanmaken van een taak, zodat een hulpvraag op het **echte adres** op de buddy-kaart staat en meerdere
  vragen **niet op één punt stapelen** (bekend symptoom van een gedeeld default-coördinaat).
- Maak het user-coördinaatveld zo nodig muteerbaar (`var`) zodat het bijgewerkt kan worden.
- Dek ook de **namens-flows** (familie/admin): gebruik de coördinaat van de juiste oudere.
- Controleer `Info.plist`-locatiepermissies + NL prompt-tekst; kaart centreert op gebruiker/relevante taken.
- Optioneel: reverse-geocode voor nette adresweergave waar nu lege strings staan.

### Fase E — Navigatie kloppend en volledig Nederlands

**Doel:** consistente, voorspelbare navigatie; geen Engelse UI-tekst.

**Te leveren:**
- Loop elke rol-schil na (tabs, sheets, navigation stacks, back-knoppen, titels). Consistente tab-bars en
  presentaties (detents, drag indicators).
- **Scan op zichtbare Engelse UI-strings** en vertaal naar het Nederlands (code/comments mogen Engels blijven).
- Elke flow heeft een duidelijke afsluiting/terugweg; diepe sheets lopen niet vast.

### Fase F — Inloggen klaar + echte data genereren én opslaan (naast de mock-data)

**Doel:** testers maken een account, loggen in, en bij gebruik wordt hun data echt opgeslagen — terwijl de
mock-/demo-data voorlopig zichtbaar blijft.

**Audit eerst:** de auth-laag (e-mail/wachtwoord, SMS-OTP, Apple Sign-In, sessieherstel, uitloggen),
de rol-routing na login, en welke schrijf-acties al persisteren.

**Te leveren:**
- **Registratie + login werkend voor testers:** e-mail/wachtwoord (met e-mailbevestiging indien aan in
  Supabase), wachtwoord-reset, en de OTP-/Apple-paden. **Nederlandse foutmeldingen** (verkeerd wachtwoord,
  e-mail al in gebruik, code verlopen, enz.).
- **Rol-toewijzing bij registratie** + correcte onboarding-gating: buddy pas "live" na VOG **én** intake
  **én** de Premium-stappen (ZZP-status mag "nog niet" zijn met uitleg, maar de gating moet kloppen);
  client zoals nu (koppelcode indien vereist), met demo-overslaan-knop.
- **Persistente data in live-modus:** controleer dat deze acties echt in Supabase landen en terugkomen na
  herstart: taak aanmaken, accepteren/onderweg/aangekomen/afronden, review plaatsen, favorieten, voorkeuren,
  profiel (adres/telefoon/locatie), meldingsvoorkeuren (Fase B), consent, **en de earnings/betaalstatus
  (display-only) per afgeronde taak**. Vul ontbrekende persistentie aan.
- **Mock-data blijft zichtbaar:** demo-modus en de mock-dataset niet verwijderen. Een ingelogde tester ziet
  zijn eigen echte data; de demo-knoppen blijven los daarvan werken.
- Werk de testflight-/review-documenten bij zodat externe testers kunnen starten.

### Fase G — Recente verbeteringen overnemen/verifiëren

Deze verbeteringen zijn recent (±gisteren) in de zustermap gedaan. Implementeer/verifieer ze ook hier, in
de stijl van déze repo:
- **Locatie-fix via geocoding** (zie Fase D) — adres → coördinaat, opslaan, `.update()` i.p.v. `.upsert()`
  i.v.m. RLS.
- **Privacy/meldingen-toggles** in rustige, ingeklapte disclosure-secties op alle profielpagina's (Fase B).
- **Koppelcode-/partnercode-flow** verifiëren (aanmaken, valideren, gebruiksteller, vervaldatum) indien
  aanwezig.
- **Admin-gebruikersbeheer** + blokkade op zelf-escalatie naar admin (Fase C).
- Loop zelf `git log` na op nog meer recente verbeteringen en neem die mee.

> **Niet doen in Premium:** géén pool-/team-competitie-feature. Die hoort alleen bij de vrijwilligers-versie.

---

## 3. Werkwijze & oplevering

1. **Eerst auditen**, dan een kort **faseplan** teruggeven (welke gaten je per fase A–G vond in déze repo).
2. Werk fase voor fase. **Bouw na elke fase** en los compile-fouten direct op.
3. Nieuwe bronbestanden: voeg ze toe aan het Xcode-project zoals déze repo dat doet. Gebruikt het project
   geen auto-sync (folder-synchronized groups)? Voeg dan handmatig `PBXBuildFile` + `PBXFileReference` +
   group-child + Sources-entry toe met **unieke** ID's (let op ID-botsingen).
4. Backend-wijzigingen altijd als **idempotente migratie**, plus korte uitleg.
5. Houd je aan de harde principes (§1): betaalmodel/ZZP behouden, betalingen display-only, mock-data niet
   verwijderen.
6. Lever per fase een korte changelog op (wat veranderd, welke bestanden, hoe getest).

**Definition of done:** een tester kan een account maken, inloggen in de juiste rol, de app gebruiken met
echte opslag in Supabase (incl. correcte earnings/facturatie display-only), terwijl demo-/mock-data blijft
werken; backend/RLS kloppen; privacy- én meldingen-toggles persisteren; admin is volwaardig (mét facturatie);
locatie en navigatie kloppen; alle UI is Nederlands; betalingen blijven display-only; de app compileert.
