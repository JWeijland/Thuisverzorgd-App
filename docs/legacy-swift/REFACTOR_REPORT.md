# REFACTOR_REPORT.md — Resultaat herstructurering

> Branch: `refactor/clean-architecture` (9 commits, niet gemerged) · Scheme: **Buddy Care**
> **Verklaring: geen functionele wijzigingen — alleen structuur, dode code en consistentie.**
> Gedrag, UI, teksten, animaties, timing, Supabase-queries/-RPC's en edge-function-aanroepen zijn ongewijzigd. Demo- én live-modus volgen exact dezelfde code-paden als voorheen.

---

## 1. Samenvatting

| | Vóór | Na |
|---|---|---|
| Aantal Swift-bestanden | 60 | 106 |
| Totaal regels Swift | 21.979 | 21.958 |
| Bestanden > 850 regels | 7 | 0 |
| Grootste bestand | 1882 (`BuddyPoolView`) | 656 (`RequestHelpFlow`) |

De code is opgesplitst in kleine, doelgerichte bestanden per domein/onderdeel. Het totale regelaantal blijft vrijwel gelijk: de toegevoegde bestandskopjes/imports/`extension`-omhullingen wegen op tegen de verwijderde dode code — bevestiging dat het om verplaatsing gaat, niet om herschrijven.

De build slaagt met het **"Buddy Care"-scheme** (clean build), zonder nieuw geïntroduceerde warnings. Na elke fase is gebouwd en is per fase gecommit.

## 2. Opgesplitste "monster-bestanden" (pure verplaatsing)

| Bestand | Vóór | Na (kern) | Nieuwe bestanden uit de splitsing |
|---|---|---|---|
| `Buddy/BuddyPoolView.swift` | 1882 | 229 | `Models/GamificationModels.swift` (254), `Models/GameData.swift` (66), `Shared/AvatarStore.swift` (127), `Buddy/BuddyPoolComponents.swift` (539), `Buddy/BuddyPoolDetailViews.swift` (284), `Buddy/BuddyTeamSheets.swift` (204), `Buddy/AchievementsView.swift` (166) |
| `App/AppState.swift` | 1520 | 395 | `AppState+Verification/+ReviewsFavorites/+Lifecycle/+Tasks/+Organizations/+Demo.swift` |
| `DesignSystem/BCComponents.swift` | 1477 | 90 | `BCButtons/BCCards/BCBadges/BCNavigation/BCOverlays/BCProfileComponents/BCFormFields.swift` |
| `App/AppStateLive.swift` | 1217 | 91 | `AppStateLive+EnumMapping/+Profile/+CreateTask/+BuddyProfile/+Sync/+Teams.swift` |
| `Elderly/ElderlyHomeView.swift` | 999 | 387 | `Elderly/ActiveTaskBanner.swift`, `Elderly/PastVisitSheet.swift`, `Elderly/ElderlySheets.swift` |
| `Admin/AdminTabView.swift` | 865 | 49 | `AdminIntakeCallsView/AdminCodesView/AdminVOGView/AdminUsersView/AdminOrganizationsView/AdminSettingsViews/AdminHelpers.swift` |
| `Buddy/CheckInFlow.swift` | 849 | 120 | `Buddy/CheckInSelfieStep.swift`, `Buddy/CheckInQRStep.swift`, `Buddy/CheckInGPSStep.swift`, `Buddy/CheckOutFlow.swift` |
| `Elderly/RequestHelpFlow.swift` | 790 | 656 | `Elderly/RequestHelpTiles.swift` (tegels). Hoofd-flow bewust intact gelaten (zie §6). |
| `Services/ProfileService.swift` | 573 | 35 | `ProfileService+VerificationIntake.swift`, `ProfileService+Profiles.swift` |
| `Services/TaskService.swift` | 572 | 29 | `TaskService+Actions.swift`, `TaskService+QueriesLinks.swift` |

**Structurele winst:** model-/util-types die in een view-bestand stonden (`AvatarStore`, `Competition`, `Team`, `GameData`, `MedalTier`, …) staan nu in `Models/` resp. `Shared/`, waar ze thuishoren.

`AppState`/`AppStateLive` zijn per domein in `extension`s gesplitst; alle `@Observable`-opslag (en de property-observers) blijven in de hoofdklasse `AppState.swift`.

## 3. Verwijderde dode code (grep-bewezen, Fase B)

| Symbool | Locatie (vóór) | Bewijs |
|---|---|---|
| `BCBigTile` | `DesignSystem/BCComponents.swift` | enkel declaratie, 0 gebruik |
| `BCDangerButton` | `DesignSystem/BCComponents.swift` | enkel declaratie, 0 gebruik |
| `BCIllustrationCard` | `DesignSystem/BCComponents.swift` | enkel declaratie, 0 gebruik |
| `BCFontFamily` | `DesignSystem/BCTypography.swift` | enkel declaratie, 0 gebruik |
| `ConsentSettingsCard` | `App/RootView.swift` | enkel declaratie, nergens getoond |
| `DBReview` | `Services/SupabaseManager.swift` | enkel declaratie, nooit gedecodeerd |
| `VOGService` + `MockVOGService` + `VOGResult` | `Services/MockServices.swift` | protocol enkel geïmplementeerd door de ongebruikte mock |
| `taskService` (property) | `App/AppState.swift` | ongebruikt (methodes gebruiken `TaskService()` direct) — gevonden tijdens Fase E |

**Bewust behouden** (géén dode code): `MockSMSService`/`MockPushService` (demo-paden), `PrivacyConsentSheet`, `BCBuddySearchPulse`, `ContentView` (bewuste alias), `Buddie_CareApp` (`@main`).

## 4. Geconsolideerde duplicatie (Fase C — conservatief)

- Drie **byte-identieke** `RelativeDateTimeFormatter`-definities (`Elderly/ElderlyHomeView`, `Family/ActivityTimelineView`, `Buddy/InboxView` — alle `nl_NL` + `.full`) → één bron `Shared/Formatters.swift` (`BCFormatters.relativeDateTime`). De geproduceerde tekst is identiek (zelfde locale, stijl en `relativeTo: Date()`).

**Bewust NIET geconsolideerd** (zou rendering/gedrag kunnen wijzigen): "lijkt-op-elkaar"-componenten zoals `StatusTag` vs `BCStatusPill`, inline knoppen vs `BC*Button`, en de diverse avatar-/afstandsweergaven. Die zijn niet teken-voor-teken gelijk; samenvoegen zou de UI subtiel kunnen veranderen en valt daarmee buiten een pure refactor.

## 5. Aanpassingen aan toegankelijkheid (structureel, géén runtime-effect)

Voor het splitsen over bestanden zijn enkele `private`-declaraties verbreed naar `internal`:
- Geëxtraheerde subviews die voorheen `private struct` waren (geverifieerd: **geen** naamcollisies in de hele codebase).
- `profileService` en `matchingService` in `AppState` (van `private` → `internal`), zodat de domein-extensions ze kunnen gebruiken.

Dit wijzigt niets aan gedrag of geheugenlay-out; het maakt de splitsing alleen mogelijk.

## 6. Gevonden risico's/verbeterkansen (NIET aangepast — ter beslissing)

1. **Ongebruikte assets — niet verwijderd (bewust).** Iconen worden dynamisch per thema opgelost (`AppIcon.resolvedAssetName`: prefix `tv-`/`zuid-`/`present-` + basisnaam). Een letterlijke grep kan non-gebruik daarom niet bewijzen, en het verwijderen van een themed asset zou de white-label-weergave stil kunnen breken. Kandidaat-"wees"-basisnamen (géén referentie onder welke prefix dan ook): `adres, badge, buddies, buddykaart, cadeau, chat, checkin, favoriet, melding, microfoon, privacy, profiel, sluiten, sos, tijdlijn, vergoeding, waarschuwing, zoeken`. Aanbeveling: handmatig per stuk verifiëren vóór eventueel opschonen.
2. **`RequestHelpFlow` (656 regels)** is bewust niet dieper opgesplitst: het is één samenhangende, sterk gekoppelde stateful flow (`@State`-bindings over de stappen). De tegels zijn eruit gehaald; de stappen verder isoleren vraagt om het verplaatsen van state en draagt gedragsrisico.
3. **Overige bestanden 400–650 regels** (`Models.swift`, `LoginView`, `FamilyDashboardView`, `BuddyProfileView`, `AdminPhoneRequestView`, `TaskFlow`, `BuddyOnboardingFlow`, `BuddyMapView`, `MockData`, `BuddyPoolComponents`) zijn samenhangend en goed leesbaar; verder splitsen is mogelijk maar gaf onvoldoende meerwaarde t.o.v. het risico. Kandidaat voor een volgende ronde.
4. Geen gedragsbugs aangetroffen tijdens het werk.

## 7. Verificatie

- **Build:** `xcodebuild -scheme "Buddy Care"` (clean) → **BUILD SUCCEEDED**, geen nieuw geïntroduceerde warnings. De 3 resterende warnings zijn allemaal vooraf bestaand: (1) een tooling-warning "No AppIntents.framework dependency found"; (2) `AvatarStore.swift:37` (`legacyGlobalKey`) — teken-voor-teken verplaatste code, stond eerder met dezelfde melding in `BuddyPoolView.swift`; (3) `RoutePreviewView.swift:308` — een bestand dat ik niet heb aangeraakt.
- **UI-teksten ongewijzigd:** de set string-literals op `main` vs. de branch verschilt alléén door (a) de strings van de verwijderde dode `ConsentSettingsCard` en (b) één voorbeeld-string in een doc-comment in `Formatters.swift`. **Geen enkele getoonde UI-tekst is gewijzigd.**
- **Pure verplaatsing:** nieuwe bestanden zijn via het `xcodeproj`-hulpscript in target "Buddy Care" geregistreerd; verplaatste code is teken-voor-teken gelijk (op het wegnemen van een leidend `private ` en toegevoegde imports/kopcomments na).
- **Gedrag-pariteit (per rol & modus):** de code-paden voor splash → rolkeuze → login, oudere (hulpvraag/spraak/live-volgen/review/SOS/buddies/profiel), buddy (pool/aannemen/check-in/route/inbox/onboarding-VOG/profiel), familie (koppelen/dashboard/tijdlijn/profiel) en admin (gebruikers/codes/VOG/intake/prijzen) zijn ongewijzigd — uitsluitend verplaatst naar nieuwe bestanden. Push/polling/realtime in live-modus idem.

## 8. Diff-overzicht

`git diff --stat main...refactor/clean-architecture`: 65 bestanden gewijzigd, ~9.168 toevoegingen / ~8.778 verwijderingen (verplaatsingen + splitsingen + dode code weg). 9 commits, één per fase. De branch staat klaar om uit te checken en te testen; er is **niet** naar `main` gepusht of gemerged.
