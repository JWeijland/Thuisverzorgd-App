# MEGA-PROMPT — Volledige code-review & herstructurering (zónder functieverlies)

> **Voor:** een AI-coding-agent (Claude Code) die in de **vrijwilligers-repo** van Thuisverzorgd / Buddy Care werkt — een SwiftUI iOS-app (`@Observable`, iOS 17+) met een Supabase-backend. Scheme/target heet **"Buddy Care"**.
>
> **Doel:** de **héle codebase** reviewen en waar nodig herschrijven naar nette, modulaire, goed onderhoudbare code — "zoals een ervaren developer het zou opzetten", zodat je later op één plek makkelijk en overzichtelijk iets kunt aanpassen. Verwijder dode code. **Behoud exact alle functionaliteit, UI en gedrag.** Werk op een **nieuwe branch** zodat de gebruiker eerst kan testen vóór er naar `main` gaat.
>
> **Manier van werken:** schrijf **eerst** een volledig plan (`REFACTOR_PLAN.md`) en **voer dat daarna in één doorloop volledig uit**. Vraag niet tussentijds om bevestiging — de keuzes hieronder staan vast. Dit is een grote opdracht en mag uren duren; werk grondig en methodisch.

---

## 0. Lees dit eerst — vrijheid om te onderzoeken

Je hebt **volledige vrijheid en de opdracht** om de hele repo en alle documenten zelf te lezen en te doorgronden. **Vertrouw de bestandsnamen in deze prompt niet blind** — ze geven richting, maar jouw eigen audit is leidend. Begin altijd met onderzoek voordat je iets wijzigt.

Wat je tijdens de oriëntatie minimaal vaststelt:

1. `git log --oneline -30` — wat is recent gebeurd, en is de werkmap schoon? Commit of stash eerst eventuele losse wijzigingen.
2. Lees alle `*.md`-docs (setup, TestFlight, privacy, bestaande mega-prompts, Supabase-setup).
3. Breng de structuur in kaart: de **rol-schillen** (`Elderly` / `Buddy` / `Family` / `Admin`), de **App-laag** (`AppState`, `AppStateLive`, `Config`, `RootView`, `LoginView`, `RoleSelectionView`, entry point), de **Services-laag** (~15 bestanden, o.a. `SupabaseManager`, `AuthService`, `ProfileService`, `TaskService`, `MatchingService`, `NotificationService`, `PushManager`, `MockServices`), het **datamodel** (`Models`, `MockData`), het **design system** (`BCColors` / `BCTypography` / `BCComponents`), en de **Supabase-laag** (`schema.sql` + `fase*`-migraties + edge functions).
4. Stel de **twee draaimodi** vast en hoe ertussen wordt geschakeld: **demo-modus** (`isDemoMode` → laadt `MockData`) en **live-modus** (`isLive` = niet-demo én `realUserId != nil` → echte Supabase). Begrijp precies hoe `AppStateLive` de UI aan Supabase koppelt (incl. de enum-mapping Swift ↔ Postgres).
5. Inventariseer de **feature flags / constanten** in `Config.swift` en hun huidige waarden.

Geef na de audit een **kort verslag** terug in `REFACTOR_PLAN.md` (zie Fase A) en ga daarna direct door met uitvoeren.

---

## 1. Gouden regels (hier mag je niet van afwijken)

1. **ZERO functionele verandering.** Dit is een pure refactor. Gedrag, schermen, navigatie, teksten, animaties, timing, data, netwerkcalls, Supabase-queries/-RPC's en edge-function-aanroepen blijven **exact identiek**. Als gebruiker en server het verschil niet kunnen merken, is het goed.
2. **Geen UI-strings aanraken.** Geen Nederlandse UI-teksten wijzigen, herformuleren of vertalen. Geen kleuren, iconen, spacing of copy veranderen.
3. **Beide modi blijven volledig werken.** Demo-modus én live-modus moeten na elke stap exact hetzelfde doen als ervoor. **`MockData` en `MockServices` NIET verwijderen** — die horen bij de demo-modus.
4. **Werk op een nieuwe branch.** Maak `refactor/clean-architecture` (of vergelijkbaar) aan en doe daar al je werk. **Push NIET naar `main`** en merge niet. De gebruiker test de branch zelf eerst.
5. **Altijd compileerbaar.** Bouw regelmatig met het **"Buddy Care"-scheme** (`xcodebuild` of Xcode, simulator-destination). Laat nooit een gebroken build achter; los compile-fouten direct op.
6. **Kleine, logische commits per fase**, met duidelijke berichten (bijv. `refactor: AppState opgesplitst in domein-extensions (geen gedragswijziging)`).
7. **Hergebruik het bestaande design system** (`BCColors`/`BCTypography`/`BCComponents`, de `BC`-prefix). Introduceer geen nieuwe visuele taal en geen nieuwe dependencies.
8. **Volg bestaande conventies.** Behoud de taal van comments (Nederlands waar dat nu zo is), de `BC`-prefix en de `fase*`-naamgeving van migraties. Geen massale herbenoeming louter naar smaak.
9. **Raak de backend niet inhoudelijk aan.** `schema.sql`, de migraties en de edge functions blijven functioneel ongemoeid. Raak secrets/keys/URL's in `Config`/`SupabaseManager` niet aan. Dit is een opschoning van de **client-side Swift**.
10. **Geen stille bugfixes of "verbeteringen".** Kom je een bug, risico of verbeterkans tegen, **verander het gedrag niet** — noteer het in het eindrapport zodat de gebruiker kan beslissen.

---

## 2. Wat "netjes, zoals echte developers" hier concreet betekent

Het probleem: na veel iteraties is er code ontstaan die niet recht-toe-recht-aan en niet gestructureerd is. Doel is dat de code **overzichtelijk en makkelijk aanpasbaar** wordt, zonder dat er iets aan de werking verandert. Concreet:

- **Splits monster-bestanden op.** Alles boven ~400 regels is verdacht. Verifieer zelf, maar verwacht o.a.: `BuddyPoolView` (~1882), `AppState` (~1520), `BCComponents` (~1477), `AppStateLive` (~1217), `ElderlyHomeView` (~999), `AdminTabView` (~865), `CheckInFlow` (~849), `RequestHelpFlow` (~790). Hak deze op in kleine, doelgerichte bestanden/`extension`s (subviews, helpers, flow-stappen elk in een eigen bestand of een duidelijke `// MARK:`-sectie).
- **Eén verantwoordelijkheid per bestand/type** waar dat logisch is. Subviews die nu inline in een groot scherm staan, krijgen een eigen bestand met een duidelijke naam.
- **Splits `AppState` op via `extension`s per domein** (bijv. Auth, Elderly, Buddy, Family, Admin, Live-polling/realtime). De opslag (`@Observable`-properties) blijft in de hoofdklasse; gedrag verhuist ongewijzigd naar logisch ingedeelde extensions, zodat je per onderdeel makkelijk wijzigt. **Geen logica veranderen, alleen verplaatsen en groeperen.**
- **Consolideer duplicatie.** Herhaalde view-blokken → één herbruikbaar component in het design system. Copy-paste-helpers → één bron van waarheid. Identieke mapping/formatting → gedeelde functie.
- **Verwijder dode code** (zie Fase B): ongebruikte types, functies, properties, bestanden, `import`s en ongebruikte assets in `Assets.xcassets`. **Alleen verwijderen ná grep-bewijs** dat het nergens wordt gebruikt — neem dat bewijs op in het plan/rapport.
- **Consistentie:** uniforme `// MARK:`-secties, consistente volgorde van members (properties → init → body → helpers), consistente naamgeving, geen doorgekommentarieerde dode blokken.
- **Geen architectuur-revolutie.** Geen nieuw patroon of framework dat gedrag of datastromen raakt. Dit is herindelen + opschonen, niet herontwerpen.

---

## 3. Fasering (schrijf eerst het plan, voer het daarna volledig uit)

**Fase A — Audit, branch & plan.** Doe de oriëntatie uit §0, maak de branch aan, en schrijf `REFACTOR_PLAN.md` met: (1) bevindingen over de huidige structuur, (2) een afhankelijkheids-/gebruiksbeeld (wat gebruikt wat), (3) een onderbouwde lijst van **dode code** met bewijs, (4) de **monster-bestanden** en hoe je elk opsplitst, (5) duplicatie die je consolideert, (6) naamgevings-/structuurverbeteringen, (7) de volgorde van uitvoering. Voer daarna door zonder te wachten.

**Fase B — Dode code & ruis weg.** Ongebruikte types/functies/properties/bestanden, ongebruikte `import`s, ongebruikte assets — verwijderen na grep-bewijs. Bouwen.

**Fase C — Duplicatie consolideren.** Herhaalde componenten/helpers samenvoegen in het design system / gedeelde helpers. Bouwen.

**Fase D — Monster-views opsplitsen** per rol-schil (Elderly, Buddy, Family, Admin), gedrag identiek. Bouwen na elke schil.

**Fase E — `AppState` / `AppStateLive` opsplitsen** in domein-`extension`s. Bouwen.

**Fase F — Services-laag opschonen** en consistent maken (naamgeving, structuur, dubbele logica), zonder API-/gedragswijziging. Bouwen.

**Fase G — Consistentie-pass.** `// MARK:`-secties, member-volgorde, naamgeving, opmaak. Bouwen.

**Fase H — Eindverificatie** (zie §5).

Werk per fase volgens deze lus: **kies een samenhangend gebied → refactor met behoud van gedrag → bouw met het "Buddy Care"-scheme → commit met duidelijk bericht → noteer kort de voortgang.**

---

## 4. Verificatie-aanpak tijdens het werk

- Na **elke** fase: volledige build met het **"Buddy Care"-scheme**. Geen nieuwe warnings die jij introduceert.
- Controleer per wijziging dat het een **pure verplaatsing/hernoeming** is: de logica die je verplaatst moet teken-voor-teken hetzelfde blijven (op naamgeving van scope na). Gebruik `git diff` om te bevestigen dat er geen onbedoelde inhoudelijke wijzigingen in geslopen zijn.
- Houd `REFACTOR_PLAN.md` bij als levend logboek (afgevinkt per stap).

---

## 5. Eindverificatie (verplicht vóór je klaar bent)

1. **Build slaagt** volledig met het "Buddy Care"-scheme, zonder nieuwe warnings.
2. **Gedrag-pariteit-checklist** — loop expliciet, per rol én per modus (demo + live), de belangrijkste paden langs en bevestig dat het code-pad ongewijzigd is:
   - Splash → rol-keuze → login; demo-knoppen.
   - **Oudere:** hulpvraag aanmaken (`RequestHelpFlow`), spraak-invoer, buddy gevonden/live-volgen, review, SOS, mijn buddies, profiel.
   - **Buddy:** buddy-pool/open verzoeken, taak aannemen, check-in/uitcheck (`CheckInFlow`), route/kaart, inbox, onboarding/VOG-intake, profiel.
   - **Familie:** koppelen, dashboard, activiteiten-tijdlijn, profiel.
   - **Admin:** gebruikers/lidmaatschappen, telefoonaanvragen, prijzen, intake-controle.
   - Push-signalen/flags (`Config.enableRealPushNotifications`), polling/realtime in live-modus.
3. **Diff-overzicht:** `git diff --stat main...refactor/clean-architecture`. Bevestig dat wijzigingen verplaatsingen/splitsingen/verwijderde dode code zijn — geen string- of logicawijzigingen daarbuiten.
4. **Lever `REFACTOR_REPORT.md`** met: wat is gesplitst/verplaatst (voor→na), wat is verwijderd als dode code (met bewijs), regels-per-bestand voor/na, eventuele gevonden bugs/risico's (níet gefixt), en de expliciete verklaring **"geen functionele wijzigingen — alleen structuur, dode code en consistentie."**
5. **Laat de branch klaarstaan** zodat de gebruiker hem kan uitchecken en testen. **Push niet naar `main`.**

---

## 6. Expliciet NIET doen

- Geen UI-tekst, kleuren, iconen of copy wijzigen.
- `MockData`/`MockServices`/demo-modus niet verwijderen of uitschakelen.
- `schema.sql`, migraties of edge functions niet inhoudelijk wijzigen; secrets/keys/URL's met rust laten.
- Geen nieuwe features, geen gedragsveranderingen, geen stille bugfixes (apart noteren).
- Geen nieuwe dependencies of nieuw architectuurpatroon dat datastromen raakt.
- Niet naar `main` pushen en niet mergen. Niet om bevestiging vragen — schrijf het plan en voer het volledig uit.

Succes — werk grondig, bouw vaak, en houd de app op elk moment compileerbaar.
