# MEGA PROMPT — Feedback Bente, batch 1 (punten 1 t/m 8)

Je gaat 8 concrete feedbackpunten voor de Thuisverzorgd-app echt goed implementeren. Neem er de tijd voor, werk grondig en netjes, en lever werkende code op. Kwaliteit gaat boven snelheid.

---

## 0. Lees dit eerst (verplicht startpunt)

1. **Lees het feedbackdocument met screenshots**: `Feedback bente Thuisverzorgd.pdf` in de repo-root. Bekijk vooral de screenshots, want een deel van de feedback verwijst naar de afbeeldingen. (De foto bij punt 2 is in de PDF wat onscherp; een uitgebreide tekstbeschrijving staat hieronder onder "Foto bij punt 2".)
2. **Verken de codebase** voordat je iets wijzigt. Lees in elk geval de bestanden die per punt genoemd worden, plus de hele `DesignSystem/`-map, zodat je de bestaande bouwstenen en conventies kent.
3. **Maak een kort implementatieplan** (welke bestanden, welke aanpak per punt), en werk dan punt voor punt.

## Context / stack (zodat je snel thuis bent)

- **Native iOS-app in SwiftUI.** Xcode-project heet `Buddy Care.xcodeproj`, productnaam is **Thuisverzorgd**.
- **Rollen** met eigen mappen: `Buddy/`, `Elderly/` (ouderen), `Family/`, `Admin/`. Gedeelde app-laag in `App/` (o.a. `AppState*`), modellen in `Models/`, netwerk/data in `Services/`.
- **Backend: Supabase** (`supabase/` met migraties). Als je datamodel wijzigt, voeg dan een migratie toe.
- **Video-bellen: Daily SDK** (`Shared/IntakeVideoCall.swift`, o.a. `DailyCallModel`, `Daily.VideoView`).
- **Design system bestaat al** in `DesignSystem/`:
  - `BCColors.swift` — een white-label thema-engine (`BCTheme`) met design-tokens (`BCColors.primary`, `.accent`, `.textPrimary`, ...), plus `BCRadius`, `BCShadow`, `BCSpacing`.
  - `BCTypography.swift` — `BCFont`/`BCTypography` met **Montserrat** (koppen) + **Open Sans** (tekst) en systeem-fallback.
  - Verder `BCButtons`, `BCCards`, `BCBadges`, `BCComponents`, `BCProfileComponents`, `BCFormFields`, `BCNavigation`, `BCOverlays`.
  - Fonts in `Fonts/`: Montserrat (Regular/Medium/SemiBold/Bold/ExtraBold) + Open Sans (Regular/SemiBold/Bold). **Er zitten nog geen italic/cursieve varianten in.**

## Spelregels (voor alle 8 punten)

- **Branch**: werk op een nieuwe branch, bijv. `feedback/batch-1`. Let op: de huidige branch is `refactor/clean-architecture` en er staan nog **ongecommitte wijzigingen** (o.a. `Elderly/ElderlyProfileView.swift`). Check `git status` eerst en commit of stash die netjes voordat je begint, zodat jouw werk schoon afgesplitst is.
- **Commit per punt** met een duidelijke Nederlandse commit-message, bijv. `Punt 4: onlogische "Morgen om"-tijden verwijderd`.
- **Gebruik altijd de bestaande DesignSystem-tokens** (`BCColors`, `BCTypography`, `BCRadius`, `BCSpacing`, `BCShadow` en de BC-componenten). Introduceer **geen** losse fonts of hardcoded kleuren.
- **Breek de white-label thema-engine niet**: alles moet via de tokens blijven lopen.
- **Alle gebruikersgerichte copy in het Nederlands.**
- **Vermijd em-dashes (—)** in alle teksten en copy. Dit is een expliciete wens uit de feedback (em dash komt over als "door een bot gebouwd"). Gebruik gewone komma's, een dubbele punt, of haakjes.
- **Bouw/compileer na elke wijziging.** Zoek eerst de scheme met `xcodebuild -list`, bouw daarna bijv. met `xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator' build`. Los fouten en relevante warnings op.
- **Blijf binnen scope**: raak alleen de 8 punten hieronder aan. De rest van het feedbackdocument komt in een volgende batch, dus laat dat met rust.

## Aanbevolen volgorde

3 (huisstijl fundament) → 1 en 2 (visueel, gebruiken de tokens) → 4 en 5 (hulp aanvragen) → 6 (status) → 8 (camera, klein) → 7 (grootst, als laatste).

---

## Punt 1 — Mooiere, leukere openingsanimatie (splash met logo + naam)

**Bestand:** `Shared/SplashView.swift`

**Huidige situatie:** De splash toont een `LinearGradient` (primary → primaryDark), een generiek `house.fill` SF Symbol (dus niet het echte logo), een spring scale-in, het woordmerk "Thuisverzorgd" met een losse `.system(size: 38, weight: .heavy, design: .rounded)`, een tagline en 1 pulse. Auto-advance na 2,4s, tap slaat over.

**Gewenst:** Een mooiere, leukere en verfijndere openingsanimatie waarin het **echte Thuisverzorgd-logo en de naam** zitten. Denk aan: het echte merk-icoon uit `Assets.xcassets` (let op de per-thema `iconPrefix`, bijv. "tv"), een gestaffelde reveal, subtiele beweging (bijv. het roze swoosh-motief dat in-veegt/in-tekent, letters die invallen, zachte shimmer of parallax op de gradient). Behoud tap-to-skip en de auto-advance. Respecteer `accessibilityReduceMotion` (val terug op een rustige fade). Vervang de `.system(...)`-fonts door `BCTypography`-tokens (zie punt 3).

**Acceptatiecriteria:**
- Gebruikt het echte logo en de naam, niet het generieke `house.fill` symbool.
- Voelt duidelijk leuker/verfijnder dan nu, maar blijft kort (± 2 tot 2,5s) en overslaanbaar met een tap.
- Werkt netjes met reduce-motion aan.
- Gebruikt huisstijl-fonts en -kleuren via de tokens.

---

## Punt 2 — Header wordt vervormd ("verkaot") bij naar beneden slepen

**Bestanden:** `DesignSystem/BCProfileComponents.swift` (`BCProfileHeader`, `BCProfileScaffold`), `Elderly/ElderlyProfileView.swift`, `Buddy/BuddyProfileView.swift`. Zoek ook waar de **roze swoosh-decoratie** bovenaan vandaan komt (waarschijnlijk een Image-asset of Shape achter/boven de navy-balk).

**Huidige situatie:** `BCProfileHeader` is een vaste balk (`height: 128`) met een `LinearGradient(navy700 → navy900)` en `.clipShape(.rect(bottomLeadingRadius: xl, bottomTrailingRadius: xl))`. Er is **geen stretchy/overscroll-gedrag**. Bij naar beneden slepen (overscroll) rekt de roze decoratie uit en laat de header los van zijn ronde onderrand, waardoor de bovenkant er uitgerekt en niet-rond uitziet (de gebruiker noemt dit "verkaot"). Vooral zichtbaar op de profielpagina.

**Gewenst:** Een nette **stretchy header**. Bij overscroll (pull-down) moet de volledige header-achtergrond (navy-gradient **plus** roze decoratie) als één geheel mee-uitrekken naar boven om het gat te vullen, met **behoud van de ronde onderhoeken**. Nooit een losse, uitgerekte roze sliert of een platte/afgekapte onderrand.

**Hints:** Gebruik het standaard SwiftUI stretchy-header patroon: een `GeometryReader` die de scroll-offset (`minY`) leest; bij `minY > 0` de header-hoogte vergroten met die offset en met `.offset(y: -minY)` bovenaan verankeren; de `clipShape` met ronde onderhoeken op de volledige uitrekkende achtergrond houden. Doe dit **centraal** in `BCProfileHeader`/`BCProfileScaffold`, zodat zowel het ouderen- als het buddy-profiel er meteen baat bij hebben. Controleer of dezelfde header elders wordt gebruikt en fix het daar in één keer mee.

**Acceptatiecriteria:**
- Op zowel het ouderen- als het buddy-profiel: hard naar beneden trekken houdt de header één geheel, ronde onderrand blijft intact, geen naad en geen uitgerekte roze sliert.
- Zie ook "Foto bij punt 2" onderaan.

---

## Punt 3 — Huisstijl vastleggen en consequent maken (2 fonts + kleuren)

**Bestanden:** `DesignSystem/BCColors.swift`, `DesignSystem/BCTypography.swift`, `Fonts/`, en alle views.

**Huidige situatie:** Er is al een design system (thema-tokens + Montserrat/Open Sans), maar in de views wordt nog **inconsistent** `.font(.system(...))`, losse `Font.custom(...)` en hardcoded kleuren gebruikt (bijv. in `SplashView`). Er zijn **geen italic/cursieve** font-varianten. De feedback: "veel verschillende fonts door elkaar", "kies voor 2 fonts met nog cursieve opties", en "leg de lettertypes en kleuren ergens in de repo vast zodat het altijd consequent gebruikt wordt".

**Gewenst:**
1. **Documenteer de huisstijl als single source of truth**: maak `DesignSystem/HUISSTIJL.md`. Beschrijf de 2 fonts (Montserrat = koppen, Open Sans = tekst), alle kleur-tokens (semantische naam + hex), radii, schaduwen, spacing, en gebruiksregels met do's en don'ts. Verwijs naar de tokens, niet naar losse waarden.
2. **Voeg cursief/italic toe** aan de type-schaal: voeg Montserrat-Italic en OpenSans-Italic TTF's toe aan `Fonts/` en registreer ze, en breid `BCFont`/`BCTypography` uit met een italic-optie (met nette `.italic()`-fallback als de TTF ontbreekt).
3. **Audit en vervang**: zoek in de views naar `.font(.system(`, `Font.system(`, `Font.custom(` en hardcoded `Color(...)`/hex, en vervang door `BCTypography`- en `BCColors`-tokens. Begin met `SplashView` en de profiel- en intake-schermen.
4. **Breek de white-label thema-engine niet**: alles blijft via de tokens lopen.

**Acceptatiecriteria:**
- Een `grep` naar `.system(` / `Font.custom(` in de views levert (vrijwel) niets meer op buiten de `DesignSystem/`-laag.
- Cursief is beschikbaar via een token en werkt zichtbaar.
- `HUISSTIJL.md` bestaat, klopt en is bruikbaar als referentie.
- De app oogt consistent qua font en kleur; thema-engine blijft werken.

---

## Punt 4 — Onlogische "Morgen om 16:00" en "Morgen om 10:00" weghalen

**Bestanden:** `Elderly/RequestHelpFlow.swift` (tegel "Morgen om 10:00" rond r.305; `afternoonSlot`-fallback "Morgen om 16:00" rond r.419 t/m 431) en `Admin/AdminPhoneRequestView.swift` (r.198 "Morgen om 10:00"; r.394 t/m 404 "Morgen om 16:00"). Ook in de periodiek-flow.

**Huidige situatie:** Er zijn vaste tegels "Morgen om 10:00" en een `afternoonSlot` die terugvalt op "Morgen om 16:00" zodra 16:00 vandaag voorbij is. De feedback vindt dit onlogisch bij het aanvragen van hulp (ook bij periodiek).

**Gewenst:** Verwijder de vaste "Morgen om 10:00"-tegel en de "Morgen om 16:00"-fallback. Behoud "Zo snel mogelijk", "Vandaag om 16:00" (alleen tonen als 16:00 vandaag nog niet voorbij is) en "Zelf kiezen". Als er vandaag geen logische vaste middag-optie meer is, laat de gebruiker via "Zelf kiezen" plannen. Pas dit consistent toe in de ouderen-flow, de admin-variant en de periodiek-flow.

**Acceptatiecriteria:**
- Nergens nog "Morgen om 10:00" of "Morgen om 16:00" als vaste suggestie.
- De flow blijft logisch en werkend.
- Dode variabelen/helpers (bijv. `tomorrowAt10`) opgeruimd.

---

## Punt 5 — Periodiek: dropdown voor herhaal-interval (elke X weken)

**Bestanden:** `Elderly/RequestHelpFlow.swift` (`recurringSection`), `Models/Models.swift` (`RecurringFrequency` r.122 en het `RecurringRequest`-model rond r.149), `App/AppStateLive+CreateTask.swift`, en het Supabase-schema (`supabase/migrations`).

**Huidige situatie:** `RecurringFrequency` kent alleen `daily` ("Dagelijks"), `everyOtherDay` ("Om de dag") en `weekly` ("Wekelijks"). Je kunt dus niet bijvoorbeeld 2-wekelijks kiezen. De feedback wil een dropdown voor "hoeveel weken je het wil herhalen" (bijv. elke 2 weken).

**Gewenst:** Voeg een interval-keuze toe: "Elke [1 t/m N] weken" via een dropdown of stepper, zodat 2-wekelijks, 3-wekelijks enzovoort mogelijk is. Behoud dagelijks/om-de-dag waar logisch, maar maak het weken-interval flexibel in plaats van alleen "wekelijks". Sla het interval op in het model (bijv. `intervalWeeks` of een `intervalCount` + `unit`) en persisteer naar Supabase (migratie toevoegen indien nodig). Werk de herhaal-generatie bij (de `calendarComponent`/`stepValue`-logica) zodat het gekozen interval echt wordt toegepast.

**Acceptatiecriteria:**
- Gebruiker kan "elke 2 weken" (en 1/3/4 ...) kiezen via een dropdown.
- Het interval wordt correct opgeslagen en toegepast bij het genereren van de herhalingen.
- UI blijft netjes en in huisstijl; migratie toegevoegd als het datamodel wijzigt.

---

## Punt 6 — "Korte intake / wacht op" als consistent 2-stappenplan

**Bestanden:** `Buddy/BuddyProfileView.swift` (verificatie-sectie: Verificatie-rij r.170, `canAcceptTasks ? "Geverifieerd" : "Actie nodig"` r.261, "Korte intake" met `intakeCompleted ? "Geverifieerd" : "Wacht op"` r.338 t/m 340, "VOG geverifieerd" r.349), `App/AppState+Verification.swift` (`VOGStatus`: o.a. `.geldig`, `.inBehandeling`, `.aangevraagd`, `.afgewezen`, `.nietAangevraagd`, `.nietGeregeld`). Zie ook de screenshot op pagina 6 van de PDF (Verificatie / Korte intake / VOG geverifieerd).

**Huidige situatie:** De twee stappen tonen inconsistent. "Korte intake" gebruikt een boolean en toont "Wacht op" of "Geverifieerd"; "VOG geverifieerd" gebruikt `VOGStatus` en toont onder andere "Nog niet geregeld". "Wacht op" is willekeurige copy en de stappen staan los van elkaar. De feedback wil dat beide stappen (intake en VOG) dezelfde status-weergave krijgen en samen als één duidelijk stappenplan worden getoond.

**Gewenst:** Maak er een helder **2-stappenplan** van (Stap 1: Korte intake, Stap 2: VOG) met **één gedeelde status-weergave**: dezelfde badge/pill-component (`BCBadges`) en hetzelfde statusvocabulaire voor beide stappen. Kies consistente labels, bijvoorbeeld "Nog te doen" / "In behandeling" / "Goedgekeurd" (en eventueel "Afgewezen"), en map zowel `intakeCompleted` als `VOGStatus` daarop. Vervang "Wacht op" en "Nog niet geregeld". Zet de twee stappen visueel bij elkaar als een genummerd plan (1 → 2).

**Acceptatiecriteria:**
- Intake- en VOG-status gebruiken exact dezelfde badge-component en hetzelfde statusvocabulaire.
- "Wacht op" is verdwenen.
- Het geheel oogt als één helder, consistent 2-stappenplan met correcte status per stap.

---

## Punt 7 — Intake: zelf een (video)call inplannen + agenda + admin-planning

**Bestanden:** `Shared/IntakeVideoCall.swift` (Daily SDK; wachtrij via `fetchQueueStatus`, positie/aantal wachtenden), `Admin/AdminIntakeCallsView.swift` (toont nu alleen de wachtrij), de verificatie-flow (`App/AppState+Verification.swift`), en de Supabase `intake_calls`-tabel (`supabase/migrations`).

**Huidige situatie:** Een buddy kan nu alleen in een **wachtrij** komen en moet gokken of hij aan de beurt komt. Er is geen zelf-inplannen en geen agenda-koppeling. De admin ziet alleen de wachtrij.

**Gewenst:** Dit is het grootste punt. Lever een werkende, nette v1:
1. **Buddy-kant:** naast de wachtrij een optie om **zelf een gesprek in te plannen** op een gekozen moment (kies uit beschikbare slots of een datum/tijd). Toon een bevestiging met datum/tijd en de videocall-link.
2. **Agenda:** een knop "Zet in agenda" die het gesprek als event met de videocall-link toevoegt. Apple: EventKit (`EKEventStore`; voeg `NSCalendarsUsageDescription` toe aan `Info.plist`) of een `.ics`-bestand. Google: een Google Calendar template-URL. Kies de meest onderhoudsvriendelijke aanpak (EventKit plus `.ics` dekt in de praktijk beide).
3. **Admin-kant:** `AdminIntakeCallsView` krijgt naast de wachtrij een **planning/agenda** met de ingeplande gesprekken (datum/tijd, buddy, link), zodat de admin de intake-planning ziet en beheert.
4. **Persistentie:** sla geplande gesprekken op in Supabase (`intake_calls`: bijv. `scheduled_at`, `status` "scheduled" versus "queued", `link`). Voeg een migratie toe indien nodig.

**Acceptatiecriteria:**
- Een buddy kan zelf een moment kiezen in plaats van te gokken in de wachtrij.
- De agenda-knop werkt voor zowel Apple als Google.
- De admin ziet de ingeplande gesprekken in de intake-pagina.
- Alles wordt gepersisteerd in Supabase.
- Documenteer je aannames en eventuele keuzes expliciet in de oplevering.

---

## Punt 8 — Camera in spiegelbeeld bij videobellen (intake)

**Bestand:** `Shared/IntakeVideoCall.swift` (`DailyVideoView: UIViewRepresentable` r.114 t/m 131 wrapt `Daily.VideoView`; `IntakeVideoView` r.132).

**Huidige situatie:** De eigen (lokale, front-camera) preview is **niet gespiegeld**, waardoor je jezelf "verkeerd om" ziet vergeleken met een normale selfie-camera.

**Gewenst:** Spiegel **alleen de eigen lokale preview** horizontaal, net als een normale selfie. De preview van de andere deelnemer NIET spiegelen.

**Hints:** Check eerst of Daily's `VideoView` een mirror-/scale-optie voor de lokale participant biedt. Zo niet, pas dan een horizontale flip toe op alléén de lokale view (bijv. `view.transform = CGAffineTransform(scaleX: -1, y: 1)` in `DailyVideoView`), en zorg dat je duidelijk onderscheid maakt tussen de lokale en de remote view zodat je niet per ongeluk beide (of de verkeerde) spiegelt.

**Acceptatiecriteria:**
- Tijdens de intake-videocall zie je jezelf gespiegeld (selfie-gevoel).
- De andere deelnemer wordt normaal weergegeven.
- Geen dubbele spiegeling.

---

## Foto bij punt 2 (de opnieuw gestuurde, scherpe foto)

De screenshot toont de **profielpagina** met de titel "MIJN PROFIEL". Bovenaan, boven de donkerblauwe (navy) headerbalk, staan **roze/magenta penseelstreek-krullen** (een decoratieve swoosh). Daaronder de navy balk met "MIJN PROFIEL" en de ronde profielfoto die eroverheen valt, dan de naam "Jelle 1", een stats-kaart ("Nieuw / Beoordeling", "0 / Bezoeken", "0 / Reviews"), een groene kaart "Beschikbaar voor taken" met een toggle, en de sectie "Mijn gegevens" (Over mij, Mijn buurt). Onderin een tabbar met "Kaart" en "Profiel".

**Het probleem:** zodra je de pagina **naar beneden sleept** (overscroll), rekt de roze swoosh uit en laat de header los van zijn ronde onderrand, waardoor de bovenkant er **uitgerekt en niet-rond** uitziet.

**Gewenst gedrag:** bij naar beneden slepen rekt de **hele header** (navy-balk plus roze decoratie) als één geheel mee omhoog en behoudt hij zijn **ronde onderhoeken**, zodat het er altijd strak en afgerond uitziet.

---

## Oplevering (afsluiten met dit overzicht)

- **Per punt** een korte samenvatting: wat je hebt gewijzigd, welke bestanden, en eventuele aannames of gemaakte keuzes (vooral bij punt 7).
- **Lijst van gewijzigde en nieuwe bestanden.**
- **Bevestig dat de app bouwt** (noem het gebruikte `xcodebuild`-commando en dat het slaagt).
- **Noem expliciet** wat je hebt uitgesteld of waar je een ontwerpkeuze hebt gemaakt.
- Voeg waar nuttig een korte voor/na-beschrijving of preview toe.
- **Raak geen punten buiten deze 8 aan**; de rest van het feedbackdocument volgt in een latere batch.
