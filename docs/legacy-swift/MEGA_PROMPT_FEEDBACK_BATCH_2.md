# MEGA PROMPT — Feedback Bente, batch 2 (punten 9 t/m 14)

Dit is de tweede batch feedback voor de Thuisverzorgd-app (vervolg op batch 1). Je gaat 5 punten echt goed implementeren. Neem er de tijd voor, werk grondig en netjes, en lever werkende code op. Kwaliteit gaat boven snelheid.

Deze batch bevat de volgende 5 punten (in volgorde van het feedbackdocument, waarbij de twee losse feedbackregels over profiel-zichtbaarheid als 1 punt zijn samengevoegd):

1. **Punt 9** — "Hoe het werkt"-carrousel met pijltjes na registratie
2. **Punt 10** — Meldingen en berichten klikbaar maken naar de relevante pagina
3. **Punt 11** — Kaart-rondjes: competitie en teams samenvoegen tot 1 rondje, alles aan 1 kant
4. **Punt 12** — Teams: duidelijke 2-deling (punten-teams zoals nu + nieuwe zorg-teams rond 1 ouder)
5. **Punt 13** — Profielgegevens: per veld tonen (en regelen) wat wel/niet zichtbaar is

---

## 0. Lees dit eerst (verplicht startpunt)

1. **Lees het feedbackdocument met screenshots**: `Feedback bente Thuisverzorgd.pdf` in de repo-root. Deze batch gaat over de feedback vanaf "Ik mis vtv een soort stappenplan carrousel ..." tot en met "Ik zou bij 'Mijn gegevens' aangeven wat hiervan wel en niet op je openbare profiel zichtbaar is." (dat zijn pagina 2 en 3 van de PDF).
2. **Verken de codebase** voordat je iets wijzigt. Lees per punt de genoemde bestanden en de omliggende code, zodat je de bestaande conventies en bouwstenen kent.
3. **Maak een kort implementatieplan** en werk dan punt voor punt.

## Context / stack (zelfde app als batch 1)

- **Native iOS-app in SwiftUI.** Xcode-project `Buddy Care.xcodeproj`, productnaam **Thuisverzorgd**.
- **Rollen** met eigen mappen: `Buddy/`, `Elderly/` (ouderen), `Family/`, `Admin/`. Gedeelde app-laag in `App/` (o.a. `AppState*`), modellen in `Models/`, data/netwerk in `Services/`.
- **Backend: Supabase** (`supabase/migrations/`, o.a. `fase14_competitions_teams.sql`, `fase18_team_join_and_inbox.sql`, `fase19_team_prize.sql`). Wijzig je het datamodel, voeg dan een nieuwe migratie toe.
- **Design system** in `DesignSystem/` (`BCColors` thema-tokens + white-label, `BCTypography` = Montserrat koppen + Open Sans tekst, plus `BCButtons`, `BCCards`, `BCBadges`, `BCComponents`, `BCProfileComponents`, ...). Gebruik altijd deze tokens/componenten.

## Spelregels (voor alle punten)

- **Branch**: werk op een nieuwe branch, bijv. `feedback/batch-2`. Check eerst `git status` en zorg dat je schoon afsplitst van de huidige staat (in batch 1 is mogelijk al een branch gemaakt; bouw daar netjes op voort of splits opnieuw af).
- **Commit per punt** met een duidelijke Nederlandse commit-message, bijv. `Punt 11: kaart-rondjes samengevoegd en uitgelijnd`.
- **Gebruik altijd de bestaande DesignSystem-tokens** (`BCColors`, `BCTypography`, `BCRadius`, `BCSpacing`, `BCShadow` en de BC-componenten). Geen losse fonts of hardcoded kleuren.
- **Breek de white-label thema-engine niet.**
- **Alle gebruikersgerichte copy in het Nederlands.**
- **Vermijd em-dashes (—)** in alle teksten en copy (expliciete wens uit de feedback). Gebruik gewone komma's, een dubbele punt, of haakjes.
- **Bouw/compileer na elke wijziging** (`xcodebuild -list` voor de scheme, dan bijv. `xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator' build`). Los fouten en relevante warnings op.
- **Blijf binnen scope**: raak alleen deze 5 punten aan. De rest van het feedbackdocument (o.a. em-dash-opschoning, fontgebruik, "Nieuw"-kleur, 3 iconen uitlijnen, VOG-zin design, "2 open", berichten verwijderen) komt in een latere batch.

## Aanbevolen volgorde

11 (klein, kaart) → 10 (navigatie) → 13 (profiel-zichtbaarheid) → 9 (onboarding-carrousel) → 12 (zorg-teams, grootst, als laatste).

---

## Punt 9 — "Hoe het werkt"-carrousel met pijltjes (na registratie, per rol)

**Bestanden:** `Buddy/BuddyOnboardingFlow.swift` (bestaat al), plus nieuwe component(en). De ouderen- (`Elderly/`) en familie-rol (`Family/`) hebben nog geen walkthrough.

**Huidige situatie:** `BuddyOnboardingFlow` is een `TabView` in `.page`-stijl met 5 stappen (welcome, profiel, intake, VOG, done). Dit is de **registratie/setup**, niet een uitleg van hoe de app werkt. Er is nog geen "hoe het werkt"-rondleiding met pijltjes naar knoppen.

**Gewenst:** Na de registratie (de eerste keer dat iemand in de app komt) een korte **"hoe het werkt"-carrousel** die de werking van de rol uitlegt: een paar schermen ("stalen") waarbij **pijltjes naar de bedoelde knoppen wijzen** met een korte omschrijving van wat die knop doet. Maak een variant **per rol** (buddy, ouderen, familie), want de werking verschilt. Toon de rondleiding 1 keer (markeer als "gezien", bijv. op het profiel/DB of via een lokale vlag), met een "Overslaan"- en een "Klaar"-knop.

**Aanpak:** De feedback beschrijft geannoteerde schermen met pijl-callouts. Bouw een herbruikbare component (bijv. `RoleWalkthroughView` met een lijst stappen; elke stap = een afbeelding of mockup van het scherm plus een pijl die naar de relevante knop wijst plus een korte tekst). Respecteer `accessibilityReduceMotion`.

**Acceptatiecriteria:**
- Bij de eerste keer na registratie verschijnt de juiste walkthrough voor de rol.
- Pijltjes wijzen naar de bedoelde knoppen met een korte, duidelijke uitleg.
- "Overslaan" werkt en de rondleiding wordt daarna niet meer automatisch getoond (wel eventueel opnieuw op te roepen vanuit het profiel).
- In huisstijl (tokens/componenten), Nederlandse copy, geen em-dashes.

---

## Punt 10 — Meldingen en berichten klikbaar maken naar de relevante pagina

**Bestanden:** `Buddy/InboxView.swift` (de rij-`onTapGesture` markeert nu alleen als gelezen, rond r.110), `Models/InboxMessage.swift` (de `Kind`-enum met alle bericht-types), `Buddy/BuddyMapView.swift` (bevat de sheets `showCompetition`, `showTeams`, `showAchievements`, `showInbox` en opent `BuddyPoolView(initialTab:)`), en de navigatie/`AppState`.

**Huidige situatie:** Als je op een melding of bericht tikt, opent alleen het berichtencentrum en wordt het als gelezen gemarkeerd. Je kunt van daaruit **nergens heen**, wat intuïtief niet klopt. De `InboxMessage.Kind`-types zijn onder andere: `teamJoinRequest`, `teamJoinApproved`, `teamJoinRejected`, `newTaskNearby`, `neighborhoodNeedsYou`, `teamMilestone75`, `teamMilestone100`, `competitionEndingSoon`, `competitionResult`, `competitionRankChange`, `helpReminder`, `elderlyMessage`, `generic`.

**Gewenst:** Tikken op een bericht **navigeert naar de relevante pagina**, afhankelijk van het type:
- `teamJoinRequest` / `teamJoinApproved` / `teamJoinRejected` / `teamMilestone75` / `teamMilestone100` → de teams-pagina (`BuddyPoolView` teams-tab), zo mogelijk het betreffende team.
- `competitionEndingSoon` / `competitionResult` / `competitionRankChange` → de competitie-pagina (`BuddyPoolView` competitie-tab).
- `newTaskNearby` / `neighborhoodNeedsYou` / `helpReminder` → de kaart of het betreffende hulpverzoek.
- `elderlyMessage` → een **gesprekspagina** waar de buddy en de ouder berichten kunnen uitwisselen.

**Let op:** er is nog **geen aparte chat/gesprek-pagina** in de app. Voor `elderlyMessage` moet die berichten-pagina (buddy ↔ ouder) er komen. Bouw een nette, minimale v1 (berichtenlijst plus invoerveld, gepersisteerd in Supabase). Is dat binnen deze batch te groot, zet dan in elk geval de volledige navigatie/routing op en scaffold de pagina, en documenteer wat nog af moet. Controleer eerst of er echt nog niets bestaat.

**Acceptatiecriteria:**
- Elk bericht-type navigeert naar een logische bestemming; geen dood einde meer.
- `elderlyMessage` opent een gesprek met de betreffende ouder.
- Markeren-als-gelezen blijft werken.
- Consistent en in huisstijl.

---

## Punt 11 — Kaart-rondjes: competitie en teams samenvoegen, alles aan 1 kant

**Bestand:** `Buddy/BuddyMapView.swift` (de zwevende `GameMapButton`-rondjes, rond r.89 t/m 110).

**Huidige situatie:** Er zijn 3 zwevende rondjes op de kaart:
- **Rechts** (twee gestapeld): `tv-beker` → Competitie (`showCompetition` → `BuddyPoolView(initialTab: 0)`) en `tv-team` → Teams (`showTeams` → `BuddyPoolView(initialTab: 1)`).
- **Links** (één): `tv-medaille` → medailles/persoonlijke prestaties (`showAchievements` → `AchievementsView`).

Belangrijk: Competitie en Teams openen **al dezelfde** `BuddyPoolView`, alleen met een andere begin-tab.

**Gewenst:**
- Voeg de twee rechter-rondjes (Competitie en Teams) samen tot **1 rondje** dat `BuddyPoolView` opent (met beide tabs erin, de gebruiker kan binnen de pagina wisselen). Kies een passend icoon/label.
- **Behoud** het medailles/prestaties-rondje als apart rondje (zie de aanname over "Renards" onderaan).
- Zet **alle rondjes aan 1 kant** van de pagina (bijv. beide netjes onder elkaar rechts), niet 1 links en 1 rechts.

**Acceptatiecriteria:**
- Nog maar 1 rondje voor competitie/teams, dat de gecombineerde pagina opent.
- Het medailles-rondje blijft bestaan.
- Alle rondjes staan aan dezelfde kant en zijn netjes uitgelijnd.
- In huisstijl.

---

## Punt 12 — Teams: duidelijke 2-deling (punten-teams + zorg-teams rond 1 ouder)

**Bestanden:** `Buddy/BuddyPoolView.swift` (de `teamsTab`, rond r.164; `competitieTab` rond r.108), `Models/GamificationModels.swift` (`Team` rond r.111, een punten-team met `members`, `outingTarget`, `prizeTitle`), `App/AppStateLive+Teams.swift` (`loadTeams` e.d.), `Buddy/BuddyTeamSheets.swift`, de `TeamService` in `Services/`, en Supabase (`supabase/migrations/fase14_competitions_teams.sql`, `fase18_team_join_and_inbox.sql`).

**Huidige situatie:** "Teams" is nu 1 soort team: een **punten-team** ("met je maatjes samen punten, teamranglijst en een team-uitje").

**Gewenst:** Een **duidelijke 2-deling** binnen Teams:
1. **Punten-teams**: precies zoals het nu is (behouden).
2. **Zorg-teams (nieuw)**: je stapt met een aantal vrienden in een team dat voor **1 specifieke ouder** zorgt. Er komt een **schema** waarin de aangevraagde hulpbezoeken van die ouder door de teamleden kunnen worden ingevuld (teamleden claimen bezoeken). Het moet er mooi uitzien.
   - **Regel 1 (voorrang):** wordt een hulpverzoek niet binnen 1 dag door een teamlid opgepakt, dan wordt via de normale manier een willekeurige buddy gevraagd.
   - **Regel 2 (deadline):** een aanvraag van de ouder komt alleen in aanmerking voor het team als hij **2 dagen of meer vooruit** is ingepland; anders is het te kort dag voor het team en gaat hij direct via de normale buddy-pool.

**Aanpak:** Voeg een team-type toe (bijv. `TeamKind.points` en `.care`), koppel een zorg-team aan een `elderlyId`, en bouw het bezoek-schema (welke aangevraagde bezoeken zijn er, wie claimt wat). Breid het datamodel en Supabase uit met een nieuwe migratie (bijv. `fase20_care_teams.sql`). Pas de toewijzingslogica van hulpverzoeken aan zodat regel 1 en regel 2 kloppen.

**Acceptatiecriteria:**
- De Teams-tab toont een heldere 2-deling (punten-teams versus zorg-teams).
- Je kunt een zorg-team rond een ouder aanmaken of joinen.
- Het bezoek-schema toont de aangevraagde bezoeken; teamleden kunnen ze claimen; het ziet er verzorgd uit.
- De 1-dag-voorrang en de 2-dagen-regel werken aantoonbaar.
- Alles gepersisteerd in Supabase. Dit is het grootste punt: lever een werkende, nette v1 en documenteer je aannames en keuzes.

---

## Punt 13 — Profielgegevens: per veld tonen (en regelen) wat zichtbaar is

Dit punt combineert twee feedbackregels die over hetzelfde gaan: "bij persoonlijke gegevens telkens super klein aangeven of iets wel of niet zichtbaar is voor anderen" en "bij 'Mijn gegevens' aangeven wat wel en niet op je openbare profiel zichtbaar is (postcode wil niet iedereen delen)".

**Bestanden:** `Buddy/BuddyProfileView.swift` (sectie "Mijn gegevens" rond r.148 t/m 159: Over mij, Mijn buurt, Geboortedatum), `Elderly/ElderlyProfileView.swift` (o.a. rond r.106), `DesignSystem/BCProfileComponents.swift` (`BCProfileInfoRow` rond r.119, plus `BCProfileNavRow`), het profielmodel (voor zichtbaarheids-vlaggen), en de bestaande `PrivacyConsentSheet`.

**Huidige situatie:** In "Mijn gegevens" staan rijen (Over mij, Mijn buurt, Geboortedatum, ...) **zonder enige indicatie** of een veld zichtbaar is voor anderen of op je openbare profiel. Er is wel een aparte "Privacy & gegevens"-sheet, maar niet per veld.

**Gewenst:**
- Toon **per persoonlijk gegeven subtiel (klein)** of het wel of niet zichtbaar is voor anderen / op je openbare profiel.
- Maak bij "Mijn gegevens" duidelijk wat wel en niet openbaar is (bijv. postcode wil niet iedereen delen), en laat de gebruiker dit **regelen** (aan/uit) waar dat zinvol is (in elk geval postcode/buurt).

**Aanpak:** Breid `BCProfileInfoRow` (en waar nodig andere profielrijen) uit met een optionele kleine **zichtbaarheids-indicator** (bijv. een oog / oog-met-streep plus label "Zichtbaar" of "Privé"). Voeg per-veld zichtbaarheids-instellingen toe aan het profielmodel en Supabase voor de velden die de gebruiker mag regelen. Houd het subtiel en in huisstijl.

**Acceptatiecriteria:**
- Elk relevant veld in "Mijn gegevens" toont klein of het zichtbaar of privé is.
- De gebruiker kan de zichtbaarheid regelen waar zinvol (onder andere postcode/buurt).
- Consistent op zowel het buddy- als het ouderen-profiel.
- Gepersisteerd in Supabase, in huisstijl, geen em-dashes.

---

## Aanname die je even moet checken bij de opdrachtgever

- **Punt 11, "de Renards"**: in de feedback staat "de Renards mogen blijven als rondje". De term "Renards" komt nergens in de codebase voor. Op de kaart zijn de rondjes: Competitie, Teams en Medailles/prestaties. Ik ga ervan uit dat met "Renards" het **medailles/prestaties-rondje** (de persoonlijke rewards) wordt bedoeld, en dat dat als apart rondje moet blijven bestaan. Klopt deze aanname niet, pas het gedrag dan aan op wat wel bedoeld is.

## Oplevering (afsluiten met dit overzicht)

- **Per punt** een korte samenvatting: wat je hebt gewijzigd, welke bestanden, en eventuele aannames of gemaakte keuzes (vooral bij punt 10 en 12).
- **Lijst van gewijzigde en nieuwe bestanden** (en nieuwe Supabase-migraties).
- **Bevestig dat de app bouwt** (noem het `xcodebuild`-commando en dat het slaagt).
- **Noem expliciet** wat je hebt uitgesteld of waar je een ontwerpkeuze hebt gemaakt.
- **Raak geen punten buiten deze 5 aan**; de rest van het feedbackdocument volgt in een latere batch.
