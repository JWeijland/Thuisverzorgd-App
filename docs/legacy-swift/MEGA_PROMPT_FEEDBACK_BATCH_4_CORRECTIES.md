# MEGA PROMPT — Feedback Bente, batch 4 (correcties en nieuwe bugs uit het testen)

Dit zijn correcties en aanvullingen die tijdens het testen naar boven kwamen. Drie onderwerpen:

1. **Inbox-berichten klikbaar maken naar het juiste scherm** (incl. een echt gesprek-scherm tussen buddy en ouder). Dit is dezelfde wens als batch 2, punt 10; deze beschrijving is leidend.
2. **Bug: als de ouder op "Bellen" drukt, wordt het verkeerde nummer gebeld** (nu 085, niet het nummer van de buddy).
3. **Correcties op de hulp-aanvraag en periodiek-flow** (het vaste 16:00-blok moet weg, "hoe vaak" moet een vrij in te vullen aantal dagen of weken worden, en "tot wanneer" moet alleen via de kalender). **Dit vervangt de eerdere aanpak in batch 1, punt 4 en 5.**

Werk grondig en netjes, en lever werkende code op.

---

## 0. Lees dit eerst

- Verken per onderwerp de genoemde bestanden voordat je iets wijzigt.
- **Context/stack** (zelfde app als eerdere batches): SwiftUI iOS-app `Buddy Care.xcodeproj` (productnaam Thuisverzorgd), rollen in `Buddy/`, `Elderly/`, `Family/`, `Admin/`, app-laag `App/`, modellen `Models/`, data `Services/`, backend Supabase (`supabase/migrations/`). Design system in `DesignSystem/` (`BCColors`, `BCTypography`, `BCButtons`, `BCCards`, ...). Gebruik altijd de tokens/componenten.

## Spelregels

- Nieuwe branch, bijv. `feedback/batch-4`. Commit per onderwerp, Nederlandse commit-messages.
- Gebruik de bestaande DesignSystem-tokens, breek de white-label thema-engine niet.
- Nederlandse copy, geen em-dashes (—).
- Bouw/compileer na elke wijziging (`xcodebuild -scheme "Buddy Care" -destination 'generic/platform=iOS Simulator' build`).
- Wijzig je het datamodel, voeg dan een Supabase-migratie toe.

## Aanbevolen volgorde

3 (hulp/periodiek, concreet) → 2 (bel-bug) → 1 (inbox plus gesprek-scherm, grootst).

---

## 1. Inbox-berichten klikbaar maken naar het juiste scherm (incl. gesprek-scherm)

**Bestanden:** `Buddy/InboxView.swift` (de rij heeft nu alleen `.onTapGesture` die markeert als gelezen, rond r.110), `Models/InboxMessage.swift` (de `Kind`-enum), `Buddy/BuddyMapView.swift` (sheets `showCompetition` / `showTeams` / `showAchievements` die `BuddyPoolView(initialTab:)` openen), en de navigatie/`AppState`.

**Huidige situatie:** Tikken op een bericht in de inbox markeert het alleen als gelezen. Je kunt van daaruit nergens heen; dat klopt intuïtief niet.

**Gewenst:** Tikken op een bericht **navigeert naar het relevante scherm**, afhankelijk van het type (`InboxMessage.Kind`):
- `teamJoinRequest` / `teamJoinApproved` / `teamJoinRejected` / `teamMilestone75` / `teamMilestone100` → teams-pagina (`BuddyPoolView` teams-tab), zo mogelijk het betreffende team.
- `competitionEndingSoon` / `competitionResult` / `competitionRankChange` → competitie-pagina (`BuddyPoolView` competitie-tab).
- `newTaskNearby` / `neighborhoodNeedsYou` / `helpReminder` → de kaart of het betreffende hulpverzoek.
- `elderlyMessage` → een **gesprek-scherm** waarin buddy en ouder berichten kunnen uitwisselen.

**Belangrijk (het gesprek-scherm bestaat nog niet):** Voor `elderlyMessage` is het concrete voorbeeld: de ouder stuurt een bericht naar de buddy, de buddy tikt in de inbox op dat bericht en komt op een **berichten-/gesprek-scherm** waarin ze heen en weer berichten uitwisselen. Zo'n threaded gesprek-scherm bestaat nog niet (er is wel een losse "snel bericht"-compose aan de ouderen-kant). Bouw daarom:
- Een **gesprek-scherm** (berichtenlijst plus invoerveld) tussen een specifieke buddy en een specifieke ouder.
- Een Supabase-tabel voor de berichten (bijv. `messages`: `id`, `sender_id`, `buddy_id`, `elderly_id`, `text`, `created_at`, `read`), met een nieuwe migratie.
- Bereikbaar vanuit de inbox (buddy-kant) via het `elderlyMessage`-bericht, en waar logisch ook vanaf de ouderen-kant (zodat het echt tweerichtings is).

Is het volledige gesprek-scherm te groot voor deze batch, zet dan minimaal de volledige navigatie/routing op, scaffold het scherm en documenteer wat nog af moet. Controleer eerst wat er al bestaat.

**Acceptatiecriteria:**
- Elk bericht-type navigeert naar een logische bestemming; geen dood einde meer.
- Een bericht van de ouder opent een gesprek-scherm waarin buddy en ouder berichten kunnen uitwisselen.
- Markeren-als-gelezen blijft werken; berichten worden gepersisteerd in Supabase.

---

## 2. Bug: "Bellen" door de ouder belt het verkeerde nummer (085 in plaats van de buddy)

**Bestanden:** `Elderly/ElderlyHomeView.swift` (`callBuddy()`, rond r.252), `App/Config.swift` (`supportPhoneNumber = "085-XXX XXXX"`, r.18), `Elderly/ActiveTaskBanner.swift` (de "Bellen"-knop met `onCall`, r.139), het taakmodel in `Models/Models.swift` (rond r.258: `assignedBuddyName`, `assignedBuddyRating`, `assignedBuddyEtaMinutes`, `assignedBuddyId`, maar **geen buddy-telefoonnummer**), en `App/AppState+Tasks.swift` (waar bij aannemen `assignedBuddyName` e.d. wordt gezet, rond r.95).

**Huidige situatie:** Als de ouder tijdens een actieve hulpvraag (buddy onderweg) op "Bellen" drukt, roept `callBuddy()` dit aan:
```swift
let digits = Config.supportPhoneNumber.filter { $0.isNumber || $0 == "+" }
```
Dat is het **support-nummer (085)**, niet het nummer van de toegewezen buddy. Het taakmodel bevat momenteel ook helemaal geen buddy-telefoonnummer, dus de ouder kán de buddy nu niet direct bellen.

**Gewenst:** De ouder belt bij "Bellen" het **telefoonnummer van de toegewezen buddy**.

**Aanpak:**
1. Voeg een veld `assignedBuddyPhone: String?` toe aan het taakmodel (bij de andere `assignedBuddy*`-velden).
2. Vul dit bij het aannemen van de taak met `buddyUser.phoneNumber` (in `App/AppState+Tasks.swift`, waar `assignedBuddyName = buddyUser.firstName` wordt gezet), en zorg dat het ook via de live/Supabase-sync bij de ouder terechtkomt (zodat de ouder het nummer van de toegewezen buddy kent zolang de taak actief is).
3. Pas `callBuddy()` aan zodat het `assignedBuddyPhone` van de actieve taak gebruikt in plaats van `Config.supportPhoneNumber`. Val netjes terug als het nummer onbekend is (bijvoorbeeld knop uitschakelen of een duidelijke melding), maar het doel is de buddy te bellen.

**Privacy:** het buddy-nummer alleen beschikbaar maken zolang er een actieve, aangenomen hulpvraag loopt (niet daarbuiten). Documenteer deze keuze.

**Acceptatiecriteria:**
- "Bellen" belt het nummer van de toegewezen buddy, niet 085.
- Werkt tijdens een actieve hulpvraag; nette fallback als het nummer ontbreekt.
- Het buddy-nummer lekt niet buiten de actieve taak om.

---

## 3. Correcties op de hulp-aanvraag en periodiek-flow (vervangt batch 1, punt 4 en 5)

**Bestanden:** `Elderly/RequestHelpFlow.swift` (de timing-tegels rond r.300 t/m 312, de `recurringSection` en `endDatePresets` rond r.352 t/m 415, de helper `afternoonSlot` rond r.419), `Admin/AdminPhoneRequestView.swift` (dezelfde tegels aan de admin-kant, rond r.198 en r.394 t/m 404), en `Models/Models.swift` (`RecurringFrequency` rond r.122 en het `RecurringRequest`-model rond r.149). Werk waar nodig ook `App/AppStateLive+CreateTask.swift` en een Supabase-migratie bij.

### 3a. Het vaste 16:00-blok moet helemaal weg (en het staat er nog)

**Huidige situatie:** De vaste tegel voor 16:00 (`afternoonSlot`, die "Vandaag om 16:00" of "Morgen om 16:00" toont) staat er nog, zowel bij een gewone hulp-aanvraag als bij periodiek. Ook "Morgen om 10:00" hoort weg (zie batch 1, punt 4).

**Gewenst:** Verwijder de vaste 16:00-tegel (`afternoonSlot`) **volledig**, en ook de "Morgen om 10:00"-tegel, zowel bij de gewone aanvraag als bij periodiek, en in de admin-variant. Houd alleen over:
- "Zo snel mogelijk" (alleen bij een eenmalige aanvraag).
- "Zelf kiezen" met de kalender (datum en tijd).

Ruim de dode helpers op (`afternoonSlot`, `tomorrowAt10`, `tomorrowAt16` e.d.).

### 3b. "Hoe vaak": vrij aantal dagen of weken invullen, geen vaste vakjes

**Huidige situatie:** Onder "Hoe vaak?" staan vaste tegels uit `RecurringFrequency` (Dagelijks, Om de dag, Wekelijks).

**Gewenst:** Vervang die vaste tegels door een **vrije invoer**: de gebruiker vult zelf een **aantal** in en kiest de **eenheid** (dagen of weken). Dus bijvoorbeeld "Elke [ 2 ] [ weken ]" of "Elke [ 3 ] [ dagen ]", via een stepper of invoerveld plus een dagen/weken-keuze. Geen standaard vakjes meer.

**Aanpak:** Pas `RecurringFrequency` / het `RecurringRequest`-model aan naar een `intervalCount` (getal) plus een `unit` (dagen of weken), en werk de herhaal-generatie bij zodat het gekozen interval echt wordt toegepast. Persisteer naar Supabase (migratie indien nodig). Dit vervangt de "dropdown elke X weken" uit batch 1, punt 5.

### 3c. "Tot wanneer": alleen zelf kiezen met de kalender

**Huidige situatie:** Onder "Tot wanneer?" staan vaste presets ("1 week", "2 weken", "1 maand") plus "Zelf kiezen".

**Gewenst:** Verwijder de vaste presets. Laat "Tot wanneer" **alleen** via de kalender (de grafische `DatePicker`) kiezen. Ruim `endDatePresets` op.

**Acceptatiecriteria (voor heel punt 3):**
- Nergens nog een vaste 16:00- of "Morgen om 10:00"-tegel, niet bij aanvraag, niet bij periodiek, niet bij admin.
- "Hoe vaak" is een vrij in te vullen aantal dagen of weken (geen vaste vakjes) en wordt correct opgeslagen en toegepast.
- "Tot wanneer" kan alleen via de kalender.
- Flow blijft logisch en werkend; dode code opgeruimd; in huisstijl.

---

## Oplevering (afsluiten met dit overzicht)

- **Per onderwerp** een korte samenvatting: wat gewijzigd, welke bestanden, eventuele aannames (vooral bij het gesprek-scherm en de privacy-keuze rond het buddy-nummer).
- **Lijst van gewijzigde en nieuwe bestanden** en eventuele nieuwe Supabase-migraties.
- **Bevestig dat de app bouwt.**
- Let op: punt 3 vervangt bewust de eerdere aanpak uit batch 1 (punt 4 en 5). Als batch 1 al is uitgevoerd, corrigeer je met dit punt de timing- en periodiek-flow naar de nieuwe wens.
