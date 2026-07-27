# MEGA-PROMPT — Ombouw "Thuisverzorgd" van betaalde zorg-marktplaats naar vrijwilligers-welzijnsplatform

> Dit is een uitvoeringsopdracht voor een AI-coding-agent (of mensontwikkelaar). Voer het uit in
> kleine, controleerbare stappen. Bouw na elke fase en houd de app compileerbaar. Vraag het niet
> opnieuw uit — de richtinggevende keuzes staan hieronder vast.

---

## 0. Context & doel

De app is een native **iOS-app (SwiftUI 6 `@Observable` + Supabase)**, ~31k regels, 104 Swift-bestanden.
Hij is nu gebouwd als een **betaalde zorg-marktplaats**: buddies verdienen geld per taak, er zijn
uurtarieven per niveau, platform-commissie, ZZP-onboarding, verzekering, VOG/ID, een 5-niveau
cursussysteem dat medische taken ontsluit, een wallet/uitbetaling en WMO/zorg-in-natura-facturatie.

**Wij bouwen dit om naar een laagdrempelig VRIJWILLIGERS-WELZIJNSPLATFORM.** Geen zorg, geen geld,
geen niveaus, geen medische taken. Vraag (ouderen/mantelzorgers) en aanbod (vrijwilligers = "Buddies")
worden gematcht voor welzijn: gezelschap, koffie, wandelen, boodschappen, samen activiteiten,
digitale hulp, sociale ondersteuning, ontlasten van mantelzorgers.

Behoud de merknaam **Thuisverzorgd** en de term **Buddy**.

### De vier rollen blijven bestaan
- **Hulpvrager / oudere** (`.elderly`) — zoekt gezelschap/hulp.
- **Buddy / vrijwilliger** (`.buddy`) — biedt zich aan. Kern van de aanbodzijde.
- **Familie / mantelzorger** (`.family`) — regelt en kijkt mee namens een oudere.
- **Admin / organisatie** (`.admin`) — beheert koppelcodes, organisaties, intakes.

---

## 1. Harde principes (niet afwijken)

1. **Geen enkele geldstroom in de app.** Verwijder alles rond betalen, verdienen, tarieven,
   commissie, facturatie, uitbetaling, ZZP, IBAN, KvK, BTW, WMO/zorg-in-natura, gemeente-billing.
2. **Eén buddy-type, geen niveaus.** Verwijder `ServiceLevel` (0–3) als gating-mechanisme en alle
   medische taken. Iedere buddy mag elke welzijnstaak oppakken.
3. **Cursussen zijn geen kern.** Verwijder het verplichte/gating cursussysteem. (Optioneel: laat
   ruimte voor losse, niet-verplichte "verdieping" later — maar bouw die NU niet.)
4. **Laagdrempelig voor buddies, gecontroleerd voor clients.**
   - Buddy: mag **altijd** aansluiten, iedere buddy gelijk. **Korte (~5 min) intake altijd verplicht**
     + **VOG** (gratis voor vrijwilligers). Aanmelden/rondkijken mag direct; buddy kan pas **taken
     aannemen** als VOG rond is én intake akkoord. Geen org-route die de intake overslaat.
   - Client (oudere/familie): aanmelden moet **heel makkelijk** zijn, **maar vereist een koppelcode**
     (uitgegeven via zorgverzekeraar/gemeente/werkgever; door ons gegenereerd in admin).
5. **Demo-modus moet werken.** Overal waar een echte drempel zit (koppelcode, VOG, intake) moet een
   duidelijke **"demo: overslaan"-knop** zijn zodat de flow zonder backend te testen is.
6. **Taalgebruik = welzijn, niet zorg.** Vervang "zorg/cliënt/patiënt/behandeling/tarief" door
   "welzijn/hulpvrager/gezelschap/vrijwillig". Geen medische of financiële termen in de UI.
7. App blijft te allen tijde compileerbaar. Werk per module, niet alles tegelijk.

---

## 2. Wat WEG moet (verwijderen of leegmaken)

Werk deze af in deze volgorde. Verwijder code, niet alleen UI-verwijzingen — laat geen dode modellen
staan die later weer opduiken.

### 2a. Geld / verdienen / facturatie
- `Buddy/EarningsView.swift` (WalletView) — **verwijderen**. Tab "Earnings/Verdiensten" uit
  `Buddy/BuddyTabView.swift` halen.
- `Elderly/PaymentOverviewView.swift` — **verwijderen**. Tab "Payments/Betalingen" uit
  `Elderly/ElderlyTabView.swift` halen.
- `Admin/AdminBillingView.swift` — **verwijderen**. Tab uit `Admin/AdminTabView.swift` halen.
- In `Models/Models.swift`: verwijder `ServiceRecord`, `EarningEntry`, `paymentType`,
  `clientHourlyRateCents`, `buddyHourlyRateCents`, `municipality`, alle `priceCents`/profit-velden op
  `ServiceTask`, en alle bijbehorende computed properties (buddyEarnings/clientCharge/profit).
- In `App/Config.swift`: verwijder `platformCommissionPercent`, reiskosten-per-km, alle tarief-
  tabellen (Level 0–3 prijzen), `enableRealPayments`. Verwijder de Mollie-TODO's.
- `Services/MockServices.swift`: verwijder `MockPaymentService` en alle payment-stubs.
- Verwijder ZZP-stappen uit buddy-onboarding (KvK, BTW, IBAN, uurtarief, zelfstandige-vraag,
  contract/incasso). Zie §3.
- Verwijder CSV-belasting-export en "Exporteer voor belasting".

### 2b. Niveaus, cursussen, medische taken
- `Buddy/CoursesView.swift`, `Buddy/CourseModuleView.swift`, `Models/CourseContent.swift` (964 regels),
  `Buddy/CertificateView.swift`, `Buddy/LevelUnlockedPreferencesSheet.swift`,
  `Buddy/BuddyPreferencesView.swift` — **verwijderen**. Tab "Cursussen" eruit.
- In `Models/Models.swift`: verwijder `ServiceLevel`, `Course`, `CourseModuleData`, `Certification`,
  `servicePreferences[level]`, `completedTasksByCategory`, `requiresPhysicalCertification`,
  `newlyUnlockedLevel`, en het `requiredLevel`-veld op `ServiceTask`.
- In `App/AppState.swift`: verwijder course-progress state (`completedModules`), level-unlock-logica,
  en alle matching-logica die op niveau filtert.
- **Medische taakcategorieën schrappen** uit `TaskCategory`: verwijder `medication` (medicatie),
  `bedHelp` (bedhulp) en alles wat wassen/wondzorg/vitals/catheter raakt. Zie §4 voor de nieuwe set.

### 2c. Professionele verificatie die NIET past
- Verwijder KYC volledig: `MockKYCService`, `enableKYCVerification`, `kycVerified`-veld, ID-document-
  upload-stap. (VOG blijft wél — zie §3a.)
- Verwijder de verzekerings-vraag (`hasInsurance`) uit onboarding en model.
- `Shared/WMOGuideView.swift` — **verwijderen** (WMO is zorg-financiering, niet relevant).

### 2d. Organisatie-model herzien (niet volledig slopen)
- Het oude `Organization`-model is op tarief/markup gebouwd (`buddyHourlyRateCents`, `markupPercent`).
  Verwijder die financiële velden. Behoud organisatie als **partner-entiteit** (naam, type, actief),
  want we hebben 'm nodig voor koppelcodes en org-aangesloten buddies. Zie §5.
- `App/OrganizationOnboardingFlow.swift` (proof-upload + admin-approval) — **vervangen** door de
  nieuwe flows in §3. De huidige "upload bewijs van dienstverband"-stap vervalt.
- `CordaanBuddyOnboardingFlow` — generaliseren naar een algemene "via organisatie"-buddy-flow
  (niet hardcoded Cordaan).

---

## 3. Onboarding opnieuw bouwen

### 3a. Buddy-onboarding (laagdrempelig)
Vervang de 14-staps `Buddy/BuddyOnboardingFlow.swift` door een **korte** flow:

1. **Welkom / intro** — wat is een Buddy, welzijn-framing.
2. **Account** — naam, e-mail, telefoon, wachtwoord (of Apple Sign-In).
3. **Profiel** — bio, woonplaats/locatie, beschikbaarheid (dagen/dagdelen), max. reisafstand,
   welke welzijnstaken je leuk vindt (vrije multi-select uit de nieuwe categorieën — géén niveau).
4. **Korte online intake (~5 min, ALTIJD verplicht voor élke buddy)** — een paar simpele vragen
   (motivatie, ervaring, beschikbaarheid, akkoord gedragscode). Geen zwaar formulier. Iedere buddy is
   gelijk; er is GEEN org-route die de intake overslaat. Resultaat: status "intake ingediend".
5. **VOG** — leg uit dat een VOG **gratis** is voor vrijwilligers; knop "VOG aanvragen/uploaden".
   Status `vogValid` + `vogExpiresAt` (3 jaar) behouden in model. VOG blokkeert aanmelden/rondkijken
   NIET, maar de buddy kan **pas taken aannemen als VOG rond is én intake akkoord**. Markeer profiel
   als "VOG in behandeling" tot rond.
6. **Klaar** — activeren (rondkijken mag; taken aannemen pas na VOG + intake).

**Demo-knop:** in stap 4/5 een knop **"Demo: sla intake & VOG over"** die alle vereisten op
voldaan/overgeslagen zet (incl. taken-aannemen vrijgeven) en direct naar de buddy-tab gaat.

Behoud uit het oude model alleen: naam, avatar, bio, woonplaats, beschikbaarheid, maxDistanceKm,
voorkeurstaken, rating, totalTasks, vogValid/vogExpiresAt. Verwijder: level, certifications, kyc,
iban, tarief, ZZP-velden, servicePreferences-per-level.

### 3b. Client-onboarding (oudere) — koppelcode verplicht
In `App/LoginView.swift` / role-selectie + een nieuwe client-onboarding:

1. **Account** — naam + telefoon (SMS-OTP bestaat al), heel kort.
2. **Koppelcode invullen** — verplicht veld. Code is uitgegeven door een partner (zorgverzekeraar/
   gemeente/werkgever) en gegenereerd in admin (§5). Validatie tegen de codes-tabel.
   - Toon partner-naam bij geldige code ("Welkom, aangeboden via Gemeente Zeist").
   - **Demo-knop "Demo: zonder koppelcode doorgaan"** die de check omzeilt.
3. **Profiel** — naam, adres, leeftijd (optioneel), voorkeuren (grote tekst / formeel taalgebruik
   bestaat al en mag blijven). **Verwijder** allergieën/medicatie-velden (medisch).
4. Klaar → naar elderly-tab.

### 3c. Familie-onboarding
Blijft grotendeels (`Family/FamilyLinkingView.swift`): koppelen aan een oudere via 6-cijferige code.
**Maar:** als de familie een nieuwe oudere aanmeldt namens de oudere, geldt dezelfde **koppelcode-eis**
als bij clients (§3b). Familie zelf heeft geen koppelcode nodig om mee te kijken bij een reeds
aangesloten oudere.

---

## 4. Taakcategorieën — alleen welzijn

Vervang `TaskCategory` in `Models/Models.swift` door uitsluitend welzijnstaken. Voorgestelde set
(NL labels + SF Symbols naar keuze):

- `companionship` — Gezelschap / koffie drinken
- `walk` — Samen wandelen / naar buiten
- `groceries` — Boodschappen doen
- `activity` — Samen een activiteit ondernemen
- `digitalHelp` — Hulp bij digitale vragen (telefoon/computer)
- `socialSupport` — Sociale ondersteuning / een luisterend oor
- `householdLight` — Lichte hand-en-spandiensten (NIET schoonmaak-als-dienst; klein & informeel)
- `appointment` — Samen naar een afspraak
- `other` — Anders

Verwijder: `medication`, `bedHelp`, `lightCleaning` (als formele dienst), `mealPrep` (als zorgtaak —
mag eventueel onder `activity`/`companionship` "samen koken").

Pas `Elderly/RequestHelpFlow.swift` aan: stap "categorie" gebruikt de nieuwe set; verwijder de
niveau-/prijs-stappen volledig. Behoud timing (nu/vandaag/gepland/herhalend) en spraak-naar-tekst.

---

## 5. Admin — koppelcodes & organisaties

Herbouw `Admin/AdminTabView.swift` rond drie taken:

1. **Koppelcodes genereren & beheren** (NIEUW, kern):
   - Nieuwe model `LinkingCodeBatch`/`PartnerCode`: `code` (kort, bijv. 6 tekens), `partnerName`,
     `partnerType` (zorgverzekeraar/gemeente/werkgever/overig), `maxUses` (of onbeperkt),
     `usedCount`, `expiresAt`, `isActive`, `createdAt`.
   - UI: lijst met codes, knop "Genereer code", filter per partner, intrekken/deactiveren.
   - Codes worden gebruikt door clients (§3b) en eventueel als organisatie-koppelcode door buddies (§3a).
   - Sla op in Supabase (tabel `linking_codes`).
2. **Organisaties / partners beheren** — lijst van aangesloten vrijwilligersorganisaties & partners
   (naam, type, actief). Buddies die zich met een org-code aanmelden, worden hieraan gekoppeld.
3. **Intakes & aanmeldingen** — lijst van buddy-intakes die handmatige beoordeling vragen
   (vervang de oude membership-approval). Approve/afwijzen met notitie.

**Verwijder** uit admin: billing, service-records, finalisatie, CSV-export, telefoon-verzoeken-stub
(tenzij je die wilt behouden — niet financieel, mag blijven als simpele lijst).

---

## 6. Vereenvoudigen (behouden maar ontdaan van geld/zorg)

- **Check-in flow** (`Buddy/CheckInFlow.swift`, `Buddy/TaskFlow.swift`): behoud een simpele
  check-in/check-uit voor veiligheid en zodat familie kan meekijken, maar **verwijder de
  verdiensten-berekening** bij afronden. Houd: locatie/QR-bevestiging (optioneel), starttijd,
  afrond-notitie. Verwijder: net-earnings, uren×tarief.
- **SOS** (`Elderly/SOSView.swift`): behouden (veiligheid past bij welzijn).
- **Reviews** (`Elderly/ReviewView.swift`): behouden — vertrouwen via beoordelingen is expliciet
  onderdeel van de visie.
- **Familie-tijdlijn** (`Family/ActivityTimelineView.swift`): behouden, maar zonder bedragen.
- **Matching** (`Services/MatchingService.swift`): behouden, maar verwijder niveau-filter; match op
  locatie/afstand, beschikbaarheid en voorkeurstaken.

---

## 7. Datamodel / Supabase-migraties

Pas de Supabase-schema's in `Services/SupabaseManager.swift` (en bijbehorende tabellen) aan:

- Drop/negeer kolommen: alle tarief-, earnings-, iban-, kvk-, btw-, payment_type-, municipality-,
  level-, course-progress-kolommen.
- Nieuwe tabel `linking_codes` (zie §5).
- `buddies`: verwijder level/iban/kyc/tarief; behoud vog_valid, vog_expires_at, org_id (nullable),
  intake_status (`none`/`submitted`/`approved`/`skipped_org`/`demo`).
- `elderly`: verwijder allergies/meds/payment_type/municipality; voeg `linking_code_used` toe.
- `tasks`: verwijder price/level/payment-velden.
- Schrijf migraties idempotent en documenteer ze in `/supabase`.

> Omdat veel domeinlogica nu hardcoded in `App/AppState.swift` zit voor de demo, mag je mock-data en
> demo-flows behouden, maar zorg dat de mock-data óók de nieuwe (geld-loze, niveau-loze) vorm heeft.

---

## 8. Copy & branding-sweep

Loop alle zichtbare strings na (UI + `Models/MockData.swift`):
- Verwijder "tarief, uurloon, verdiensten, factuur, ZZP, WMO, zorg-in-natura, niveau, cursus, diploma,
  verzekering, commissie".
- Framing: "vrijwilliger", "welzijn", "gezelschap", "samen", "buurt", "betekenisvol", "ontlasten van
  mantelzorgers". Hulpvrager i.p.v. cliënt/patiënt.
- Splash/intro-tekst (`Shared/SplashView.swift`) updaten naar de welzijn-missie.

---

## 9. Volgorde van uitvoeren (aanbevolen)

1. **Modellen ontvlechten** (§2a/2b/2c/§4) — verwijder geld + niveaus + medische categorieën uit
   `Models/`, fix compile-fouten, stub waar nodig.
2. **Tabs & schermen verwijderen** (earnings, payments, courses, billing) en navigatie repareren.
3. **Taakcategorieën + RequestHelpFlow** omzetten.
4. **Buddy-onboarding** herschrijven (§3a) incl. demo-knop.
5. **Client-onboarding + koppelcode** (§3b) incl. demo-knop.
6. **Admin koppelcode-generatie + organisaties** (§5).
7. **Check-in/Task/Familie/Matching** ontdoen van geld/niveau (§6).
8. **Supabase-migraties** (§7).
9. **Copy-sweep** (§8) + mock-data bijwerken.
10. **Bouwen, demo-flow end-to-end testen** voor elke rol.

Commit per fase met een duidelijke boodschap. Push niet zonder toestemming.

---

## 10. Acceptatiecriteria (klaar wanneer…)

- [ ] Nergens in de app komt geld, tarief, verdienen, factuur, ZZP, IBAN, WMO of commissie voor.
- [ ] Er zijn geen niveaus, cursussen of medische taken meer; één buddy-type.
- [ ] Een buddy kan zich in <2 min aanmelden; VOG + korte intake aanwezig; org-code slaat intake over;
      demo-knop omzeilt alles.
- [ ] Een client kan zich alleen aanmelden met geldige koppelcode; demo-knop omzeilt dit.
- [ ] Admin kan koppelcodes genereren, koppelen aan een partner, en intrekken.
- [ ] Alle vier rollen hebben een werkende, geld-loze, welzijn-gerichte flow.
- [ ] App compileert en de demo-flow werkt end-to-end per rol.

---

## 11. Aannames (corrigeer indien onjuist)

1. **Alle buddies zijn gelijk.** Er is GEEN org-route die de intake overslaat; iedere buddy doet de
   korte (~5 min) intake. (Org-koppelcodes zijn er alleen voor clients/partners, niet voor buddies.)
2. **VOG blokkeert taken aannemen, niet aanmelden.** Buddy mag aanmelden en rondkijken terwijl VOG
   "in behandeling" is, maar kan pas taken aannemen als VOG rond is én intake akkoord. Hard afdwingen
   bij het accepteren van een taak (met demo-bypass).
3. **Geen reiskostenvergoeding** in de app (puur vrijwillig). Reiskosten regelen organisaties buiten
   de app.
4. **Familie** heeft zelf geen koppelcode nodig om mee te kijken bij een reeds-aangesloten oudere;
   wél bij het aanmelden van een nieuwe oudere.
5. **Telefoon-verzoeken-stub** in admin mag blijven als simpele lijst (niet financieel).
