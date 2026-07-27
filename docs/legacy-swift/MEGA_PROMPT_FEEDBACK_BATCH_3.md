# MEGA PROMPT — Feedback Bente, batch 3 (laatste punten, 15 t/m 23)

Dit is de derde en laatste batch feedback voor de Thuisverzorgd-app (vervolg op batch 1 en 2). Dit zijn vooral kleinere polish- en UI-punten, plus twee punten die grotendeels al in eerdere batches zijn afgedekt (die hoef je alleen te controleren/afmaken). Werk grondig en netjes, en lever werkende code op.

Deze batch bevat:

1. **Punt 15** — Em-dashes opschonen in alle copy
2. **Punt 16** — Fontgebruik: 2 fonts plus cursief consequent (overlap met batch 1, punt 3: controleren/afmaken)
3. **Punt 17** — Statistiek-band: "Nieuw" zelfde kleur als de cijfers, plus font-match label/waarde
4. **Punt 18** — Kaart-iconen aan 1 kant (overlap met batch 2, punt 11: controleren)
5. **Punt 19** — Taakkaart: "Afstand" en "Wanneer" op dezelfde hoogte en uitlijning
6. **Punt 20** — VOG-zin op de buddy-pagina herontwerpen (meer ruimte, uitlijnen)
7. **Punt 21** — "2 open"-pil: mee laten bewegen met de zichtbare kaart en klikbaar maken
8. **Punt 22** — Duidelijk maken dat de buddy geen hulp kan aannemen door VOG-onttrekking/verlopen
9. **Punt 23** — Berichten kunnen verwijderen

---

## 0. Lees dit eerst (verplicht startpunt)

1. **Lees het feedbackdocument met screenshots**: `Feedback bente Thuisverzorgd.pdf` in de repo-root. Deze batch gaat over de feedback vanaf "Algemeen copy puntje: heel veel em dash gebruik" tot en met het einde (pagina 3 onderaan tot en met pagina 7, met de foto's van de statistiek-band, de kaart-iconen, de taakkaart, de VOG-zin en "2 open").
2. **Verken per punt de genoemde bestanden** voordat je iets wijzigt.
3. Werk daarna punt voor punt.

## Context / stack (zelfde app als batch 1 en 2)

- **Native iOS-app in SwiftUI.** Xcode-project `Buddy Care.xcodeproj`, productnaam **Thuisverzorgd**. Rollen in `Buddy/`, `Elderly/`, `Family/`, `Admin/`. App-laag in `App/`, modellen in `Models/`, data in `Services/`. Backend: Supabase (`supabase/migrations/`).
- **Design system** in `DesignSystem/` (`BCColors` thema-tokens, `BCTypography` = Montserrat koppen + Open Sans tekst, plus `BCButtons`, `BCCards`, `BCBadges`, `BCProfileComponents`, ...). Gebruik altijd deze tokens/componenten.

## Spelregels

- **Branch**: werk op een nieuwe branch, bijv. `feedback/batch-3`. Check eerst `git status`.
- **Commit per punt**, Nederlandse commit-messages.
- **Gebruik de bestaande DesignSystem-tokens**, breek de white-label thema-engine niet.
- **Alle copy in het Nederlands, geen em-dashes** (dat is deze keer ook letterlijk een taak, zie punt 15).
- **Bouw/compileer na elke wijziging** (`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator' build`).
- **Blijf binnen scope**: alleen deze punten.

## Aanbevolen volgorde

Snelle wins eerst: 23 → 17 → 19 → 20 → 15 → 22 → 21, daarna de controle-punten 16 en 18.

---

## Punt 15 — Em-dashes opschonen in alle copy

**Waar:** door de hele codebase. Een `grep` naar em-dashes in string-literals levert ongeveer **51 plekken** op, vooral in toasts en subtitels, bijvoorbeeld:
- `App/AppState+Verification.swift`: "VOG geüpload — we controleren 'm even."
- `App/AppStateLive+Teams.swift`: meerdere toasts als "Aanmaken mislukt — probeer opnieuw"
- `App/AppState+Tasks.swift`, `App/AppStateLive+Sync.swift`, `App/AppStateLive+CreateTask.swift`, `DesignSystem/BCFormFields.swift`, `Elderly/ActiveTaskBanner.swift`, enzovoort.

**Gewenst:** Vervang em-dashes (—) in **gebruikersgerichte teksten** door normale interpunctie (komma, dubbele punt, punt of haakjes), zodat de copy niet "door een bot gebouwd" oogt. Bijvoorbeeld: "VOG geüpload — we controleren 'm even." wordt "VOG geüpload. We controleren 'm even." en "Aanmaken mislukt — probeer opnieuw" wordt "Aanmaken mislukt, probeer opnieuw".

**Let op / niet doen:** een aantal plekken gebruikt "—" als **lege-waarde-placeholder** (bijv. `?? "—"` voor een onbekende leeftijd of beoordeling in `ElderlyProfileView`, `FamilyDashboardView`, `RequestHelpFlow` summary-rijen). Dat is een legitieme typografische placeholder, geen zin. Laat die met rust, of vervang door een kort neutraal alternatief, maar dat is geen prioriteit. Code-commentaar hoef je niet aan te passen (alleen zichtbare copy).

**Acceptatiecriteria:**
- Geen em-dashes meer in zichtbare zinnen/copy.
- Lege-waarde-placeholders blijven werken.
- Copy leest natuurlijk in het Nederlands.

---

## Punt 16 — Fontgebruik: 2 fonts plus cursief, consequent (controleren/afmaken)

**Overlap:** dit is hetzelfde als **batch 1, punt 3** (huisstijl vastleggen: Montserrat koppen + Open Sans tekst, cursief toevoegen, en losse `.font(.system(...))`/`Font.custom` vervangen door `BCTypography`-tokens).

**Gewenst hier:** alleen **controleren en afmaken**. Verifieer dat batch 1 dit echt heeft opgeleverd:
- Een `grep` naar `.system(` en `Font.custom(` in de views levert (vrijwel) niets meer op buiten de `DesignSystem/`-laag.
- Er zijn precies 2 fontfamilies in gebruik (Montserrat en Open Sans), met een werkende cursief/italic-optie.
- Ruim eventueel resterende afwijkingen op.

Is batch 1 nog niet uitgevoerd, doe dit punt dan volledig volgens de beschrijving in `MEGA_PROMPT_FEEDBACK_BATCH_1.md`, punt 3.

**Acceptatiecriteria:** consistent gebruik van 2 fonts via `BCTypography`, cursief beschikbaar, geen losse fonts meer in de views.

---

## Punt 17 — Statistiek-band: "Nieuw" zelfde kleur als de cijfers, plus font-match

**Bestanden:** `Buddy/BuddyProfileView.swift` (`statRow`, rond r.104 t/m 115) en `DesignSystem/BCProfileComponents.swift` (`BCProfileStatRow`, rond r.221 t/m 262).

**Huidige situatie:** In `statRow` krijgt de eerste stat (Beoordeling) de waarde "Nieuw" met `tint: appState.buddyUser.ratingAverage > 0 ? BCColors.accentDark : BCColors.textSecondary`. Bij een nieuwe buddy is dat dus **grijs** (`textSecondary`), terwijl de andere stats ("0" bij Bezoeken en Reviews) de standaard `BCColors.textPrimary` (donker) gebruiken. Daardoor heeft "Nieuw" een andere kleur dan de "0". In `BCProfileStatRow` staat de waarde in `BCFont.heading(20, .bold)` en het label in `BCTypography.caption`.

**Gewenst:**
- Houd de kleur van de statwaarden **per regel gelijk**: geef "Nieuw" dezelfde kleur als de cijfers (of andersom een consistente behandeling voor de hele band).
- Bekijk de **font-combinatie** van waarde ("Nieuw") en label ("Beoordeling"): een woord op 20pt bold naast getallen kan zwaar/onlogisch ogen. Kies een nette, consistente pairing (bijvoorbeeld het woord "Nieuw" iets kleiner of in dezelfde stijl als de cijfers, zodat waarde en label goed bij elkaar passen).

**Acceptatiecriteria:**
- Alle drie de statwaarden hebben dezelfde kleur.
- De font-combinatie van waarde en label oogt consistent en verzorgd.
- In huisstijl via de tokens.

---

## Punt 18 — Kaart-iconen aan 1 kant (controleren)

**Overlap:** dit is hetzelfde onderwerp als **batch 2, punt 11** (de zwevende `GameMapButton`-rondjes op de kaart: nu 2 rechts en 1 links, moeten allemaal aan 1 kant, en Competitie plus Teams samengevoegd tot 1 rondje). Bestand: `Buddy/BuddyMapView.swift`.

**Gewenst hier:** alleen **controleren** dat na batch 2 alle kaart-iconen aan dezelfde kant staan en netjes zijn uitgelijnd. Zo niet, lijn ze alsnog uit volgens `MEGA_PROMPT_FEEDBACK_BATCH_2.md`, punt 11.

**Acceptatiecriteria:** alle kaart-rondjes staan aan 1 kant, netjes uitgelijnd, en er is nog maar 1 rondje voor competitie/teams.

---

## Punt 19 — Taakkaart: "Afstand" en "Wanneer" op dezelfde hoogte en uitlijning

**Bestand:** `Buddy/TaskFlow.swift` (de taakkaart met de twee stat-boxen, rond r.77 t/m 83; de helper `statBox` rond r.188).

**Huidige situatie:** In een `BCCard` staan twee `statBox`en naast elkaar: "Afstand" (bijv. "± 1,9 km", 1 regel) en "Wanneer" (bijv. "Vandaag om 16:00", vaak 2 regels), met een `Divider` ertussen. De `HStack` gebruikt de standaard verticale centrering, dus de kortere box (Afstand) wordt gecentreerd ten opzichte van de hogere box (Wanneer). Daardoor staan de waarden op **verschillende hoogte** en oogt de uitlijning inconsistent (zoals in de foto: "1,9 km" in het midden, "Vandaag om 16.00" links en lager).

**Gewenst:** "Afstand" en "Wanneer" moeten op **dezelfde hoogte** staan en consistent uitgelijnd zijn.

**Aanpak:** Lijn de `HStack` boven uit (`alignment: .top`), geef beide `statBox`en dezelfde tekst-uitlijning (bijvoorbeeld beide gecentreerd of beide leading, maar gelijk), en zorg dat de labels en waarden op gelijke hoogte beginnen. Voorkom dat de ene waarde wel en de andere niet afbreekt over 2 regels een verschil in hoogte veroorzaakt (bijvoorbeeld door beide boxen gelijk te behandelen en boven uit te lijnen).

**Acceptatiecriteria:**
- De labels "Afstand" en "Wanneer" staan op dezelfde hoogte, en hun waarden ook.
- Beide zijn op dezelfde manier uitgelijnd.
- Blijft netjes bij zowel korte als langere waarden.

---

## Punt 20 — VOG-zin op de buddy-pagina herontwerpen

**Bestand:** `Buddy/BuddyProfileView.swift` (`vogActions`, de `Text("Heb je al een VOG? Upload 'm dan direct. Anders vragen we 'm gratis voor je aan.")` rond r.555, gevolgd door de knoppen "Ik heb al een VOG (uploaden)" en "VOG gratis aanvragen").

**Huidige situatie:** De zin staat in `BCTypography.caption` / `textSecondary`, redelijk strak tegen de omliggende elementen en de status-rijen erboven (Korte intake / VOG geverifieerd, die een icoon-kolom hebben).

**Gewenst (uit de feedback):** Deze zin anders vormgeven: **meer ruimte boven en onder**, en uitlijnen **vanaf de tekst van de status-rijen** (dus beginnen waar het woord "geverifieerd" begint, niet tegen de icoon-rand). Kortom: meer lucht en nette uitlijning met de rest van het verificatie-blok.

**Acceptatiecriteria:**
- De VOG-zin heeft duidelijk meer verticale ruimte boven en onder.
- De zin lijnt links uit met de tekst van de status-rijen (na de icoon-kolom), niet met de icoon-rand.
- Oogt rustiger en verzorgder, in huisstijl.

---

## Punt 21 — "2 open"-pil: mee laten bewegen met de kaart en klikbaar maken

**Bestand:** `Buddy/BuddyMapView.swift` (`openCountPill`, rond r.202 t/m 215; toont nu `Text("\(visibleTasks.count) open")` met een mappin-icoon, als losse pil, niet aantikbaar).

**Huidige situatie:** De pil toont een aantal open hulpvragen, maar voegt weinig toe: het reageert niet op wat je op de kaart ziet en je kunt er niet op klikken.

**Gewenst (uit de feedback):**
1. Laat het getal **meebewegen met de zichtbare kaart**: als je inzoomt of pant naar je eigen buurt, telt de pil alleen de open hulpvragen die **binnen het huidige kaartbeeld** vallen, en verandert het getal mee.
2. Maak de pil **aantikbaar**: bij een tik verschijnt een **lijst van open hulpvragen**, gesorteerd met de **dichtstbijzijnde bovenaan**.

**Aanpak:** Koppel de telling aan de huidige zichtbare map-region (filter `visibleTasks` op de coordinaten binnen de region). Maak van de pil een `Button` die een sheet/lijst opent, gesorteerd op afstand tot de gebruiker (dichtstbij eerst). Hergebruik bestaande componenten en de bestaande afstand/sorteer-logica waar mogelijk (zie o.a. `MatchingService` voor afstand).

**Acceptatiecriteria:**
- Het getal in de pil verandert mee met zoomen/pannen (telt wat zichtbaar is).
- Tikken op de pil opent een lijst van open hulpvragen, dichtstbij bovenaan.
- In huisstijl, werkt vloeiend.

---

## Punt 22 — Duidelijk maken dat de buddy niet kan aannemen door VOG-onttrekking/verlopen

**Bestanden:** `Buddy/TaskFlow.swift` (de geblokkeerde staat "Nog niet beschikbaar" met de tekst "Je kunt taken aannemen zodra je VOG rond is en je korte intake is afgerond.", rond r.100 t/m 113), `Buddy/BuddyProfileView.swift` (verificatie-status, `canAcceptTasks`), en `VOGStatus` (`Models`/`App`, met de cases `nietAangevraagd`, `aangevraagd`, `inBehandeling`, `geldig`, `afgewezen`, `verlopen`).

**Huidige situatie:** Als `canAcceptTasks` false is, toont de app overal dezelfde "onboarding"-boodschap ("zodra je VOG rond is en je korte intake is afgerond"). Dat klopt voor een nieuwe buddy, maar **niet** voor een buddy van wie de VOG is **onttrokken/verlopen/afgewezen**. Voor die buddy is nu onduidelijk waaróm hij geen hulp meer kan aannemen.

**Gewenst:** Maak expliciet en duidelijk voor de buddy dat hij geen hulpvragen kan aannemen doordat zijn VOG is verlopen/ingetrokken (onttrokken) of afgewezen. Toon een aparte, duidelijke melding (op het profiel en op de plek waar hij een taak probeert aan te nemen) met de reden en een duidelijke vervolgactie (bijvoorbeeld "Vraag een nieuwe VOG aan"). Onderscheid dit dus van de gewone "nog niet geverifieerd"-situatie.

**Aanpak:** Splits de geblokkeerde-boodschap op basis van `VOGStatus`: bij `.verlopen` / `.afgewezen` (en een eventuele onttrekking, check hoe een ingetrokken VOG in de status wordt vastgelegd) een duidelijke "je VOG is verlopen/ingetrokken, daarom kun je nu geen hulp aannemen"-tekst plus CTA; bij de onboarding-situatie de bestaande tekst.

**Acceptatiecriteria:**
- Een buddy met een verlopen/ingetrokken/afgewezen VOG ziet duidelijk dat en waarom hij geen hulp kan aannemen.
- Er is een duidelijke vervolgactie (nieuwe VOG aanvragen).
- De boodschap verschilt zichtbaar van de gewone "nog niet geverifieerd"-situatie.

---

## Punt 23 — Berichten kunnen verwijderen

**Bestanden:** `Buddy/InboxView.swift` (de berichtenlijst; de rij heeft nu alleen `.onTapGesture` voor markeren-als-gelezen, rond r.110). De verwijder-logica **bestaat al**: `deleteInboxMessage(_ id:)` in `App/AppStateLive+Teams.swift` (rond r.373) en `NotificationService().delete(id:)`.

**Huidige situatie:** Je kunt berichten niet verwijderen in de UI, terwijl de backend-functie er al is.

**Gewenst:** Maak berichten verwijderbaar in de inbox, bijvoorbeeld met een swipe-to-delete (`.swipeActions` met een destructieve knop) die `appState.deleteInboxMessage(msg.id)` aanroept. Zorg dat de lijst netjes bijwerkt.

**Acceptatiecriteria:**
- Je kunt een bericht verwijderen (swipe of duidelijke actie).
- Verwijderen werkt lokaal en in Supabase (via de bestaande functie).
- De lijst en de ongelezen-teller kloppen na verwijderen.

---

## Oplevering (afsluiten met dit overzicht)

- **Per punt** een korte samenvatting: wat gewijzigd, welke bestanden, eventuele aannames.
- Voor de controle-punten (16 en 18): meld of ze al klopten na batch 1/2 of dat je nog iets hebt bijgewerkt.
- **Lijst van gewijzigde en nieuwe bestanden.**
- **Bevestig dat de app bouwt.**
- Hiermee is het volledige feedbackdocument van Bente verwerkt (batch 1 tot en met 3).
