# REFACTOR_PLAN.md — Schone herstructurering (zonder functieverlies)

> Branch: `refactor/clean-architecture` · Scheme: **Buddy Care** · Baseline build: **SUCCEEDED** (groen vóór wijzigingen).
> Doel: code overzichtelijk en modulair maken (monster-bestanden opsplitsen, dode code weg, duplicatie consolideren) **zonder enige gedrags-, UI- of netwerkwijziging**.

---

## 1. Bevindingen huidige structuur

60 Swift-bestanden, ~21.979 regels. Mappen: `App/`, `Buddy/`, `Elderly/`, `Family/`, `Admin/`, `Shared/`, `Services/`, `Models/`, `DesignSystem/` + root (`ContentView.swift`, `Buddie_CareApp.swift`).

**Twee draaimodi** (ongemoeid laten):
- **Demo**: `isDemoMode == true` → `loadDemoData()` vult `MockData`/`GameData`.
- **Live**: `isLive` = `!isDemoMode && realUserId != nil` → echte Supabase via `AppStateLive`.
- Schakelpunten o.a. `handleAuthSuccess`, `signOut`, `activateCordaanDemo`. **Niet aanraken.**

**Monster-bestanden (geverifieerd via wc -l):**

| Bestand | Regels |
|---|---|
| `Buddy/BuddyPoolView.swift` | 1882 |
| `App/AppState.swift` | 1520 |
| `DesignSystem/BCComponents.swift` | 1477 |
| `App/AppStateLive.swift` | 1217 |
| `Elderly/ElderlyHomeView.swift` | 999 |
| `Admin/AdminTabView.swift` | 865 |
| `Buddy/CheckInFlow.swift` | 849 |
| `Elderly/RequestHelpFlow.swift` | 790 |
| `Models/Models.swift` | 644 |
| `App/LoginView.swift` | 597 |

**Structurele observatie:** `BuddyPoolView.swift` bevat náást de view ook gedeelde **model-/util-types** die niet in een view-bestand horen: `AvatarStore` (gebruikt door `AppState.resetUserScopedState`), `MemberAvatar`, `PointRule(s)`, `GameStats(Provider)`, `PoolMember`, `CompetitionPrize`, `Competition`, `Team`, `Palette`, `GameData`, `MedalTier`/`Medal`/`AchievementCategory`/`AchievementData`. Die verhuizen naar `Models/` (pure move).

## 2. Afhankelijkheids-/gebruiksbeeld (kort)

- `AppState` (@Observable, opslag + gedrag) ← gebruikt door alle views via `@Environment`. `AppStateLive.swift` is één grote `extension AppState` voor de live-laag.
- `Models/` = pure datatypes + enums (Swift↔Postgres mapping in `AppStateLive`).
- `Services/` = dunne Supabase-wrappers (`ProfileService`, `TaskService`, `AuthService`, `MatchingService`, `PushManager`, `AnalyticsService`, `TeamService`, …) + `MockServices` (demo) + `SupabaseManager` (DB-DTO's).
- `DesignSystem/` = `BCColors`, `BCTypography`, `BCComponents` (38+ `BC*`-componenten), thema's.

## 3. Dode code (grep-bewezen — elk symbool 1× gedeclareerd, 0× gebruikt)

| Symbool | Bestand:regel | Bewijs |
|---|---|---|
| `BCBigTile` (struct View) | `DesignSystem/BCComponents.swift:287` | `grep -rn BCBigTile` → alleen declaratie |
| `BCDangerButton` (struct View) | `DesignSystem/BCComponents.swift:185` | idem |
| `BCIllustrationCard` (struct View) | `DesignSystem/BCComponents.swift:556` | alleen declaratie + MARK |
| `BCFontFamily` (enum) | `DesignSystem/BCTypography.swift:11` | alleen declaratie |
| `ConsentSettingsCard` (struct View) | `App/RootView.swift:191` | alleen declaratie |
| `DBReview` (struct Codable) | `Services/SupabaseManager.swift:160` | alleen declaratie |
| `VOGService` (protocol) + `MockVOGService` | `Services/MockServices.swift:33,39` | protocol enkel geïmplementeerd door de ongebruikte mock; nergens gebruikt |

**Behouden (géén dode code):** `MockSMSService`, `MockPushService` (gebruikt in demo-paden van `AppState`), `PrivacyConsentSheet`, `BCBuddySearchPulse`, `ContentView` (bewuste alias), `Buddie_CareApp` (`@main`).

**Nog te verifiëren tijdens Fase B:** ongebruikte assets in `Assets.xcassets` (asset-namen matchen tegen string-referenties in code) en ongebruikte `import`s (dead-code-audit vond geen overduidelijke; hercontrole per bestand).

## 4. Monster-bestanden — opsplitsing (pure code-verplaatsing)

> Nieuwe bestanden worden in het Xcode-project + target geregistreerd via het hulpscript (`xcodeproj`-gem). Na elke schil: **bouwen**.

### 4.1 `BuddyPoolView.swift` (1882)
- **Models eruit** → `Models/GamificationModels.swift` (`PointRule(s)`, `GameStats(Provider)`, `PoolMember`, `CompetitionPrize`, `Competition`, `Team`, `Palette`, `MedalTier`, `Medal`, `AchievementCategory`, `AchievementData`), `Models/GameData.swift` (demo-data), `Shared/AvatarStore.swift` (+ `MemberAvatar` → `DesignSystem/` of `Shared/`).
- **Subviews eruit** → `Buddy/Pool/` : `PointsHero.swift`, `MultiplierStrip.swift`, `TeamPointsHero.swift`, `CompetitionRow.swift`, `CompetitionDetailView.swift`, `TeamRow.swift`, `TeamDetailView.swift`, `MembersBoard.swift` (Podium+LeaderRow+ProgressRing), `CreateTeamSheet.swift`, `InviteSheet.swift`, `SpelregelsView.swift`, `AchievementsView.swift`, `GameMapButton.swift`. Hub blijft in `BuddyPoolView.swift`.

### 4.2 `ElderlyHomeView.swift` (999)
→ `Elderly/Home/`: `ActiveTaskBanner.swift`, `PastVisitSheet.swift`, `BuddyMessageComposeSheet.swift`, `ElderlyQRCodeSheet.swift`. Hub blijft.

### 4.3 `AdminTabView.swift` (865)
→ `Admin/`: `AdminIntakeCallsView.swift`, `AdminCodesView.swift`, `AdminVOGView.swift`, `AdminUsersView.swift`, `AdminOrganizationsView.swift`, `AdminSettingsView.swift` (+account/notifications/security), `AdminHelpers.swift` (`InfoRow`, `AdminRow`). Tab-container blijft.

### 4.4 `CheckInFlow.swift` (849)
→ `Buddy/CheckIn/`: `SelfieStepView.swift`, `QRScanStepView.swift` (+`DataScannerRepresentable`/`CornerBracket`), `GPSVerifyView.swift` (+`CheckInLocationManager`), `CheckOutFlow.swift` (`CheckOutFlowView`/`CheckOutSuccessView`), `CheckInSuccessView.swift`. Orchestrator blijft.

### 4.5 `RequestHelpFlow.swift` (790)
→ `Elderly/Request/`: `RequestHelpTiles.swift` (`CategoryTile`, `TimingTile`, `SummaryRow`). Stap-views via `// MARK:`/extensions als opsplitsen risico geeft. Hoofdflow blijft.

### 4.6 `BCComponents.swift` (1477)
Splitsen per soort (pure move): `BCButtons.swift`, `BCCards.swift`, `BCBadges.swift` (pill/rating/VOG/trust), `BCProfileComponents.swift` (profile-rijen/avatar/scaffold/header), `BCOverlays.swift` (toast/celebration/popicon), `BCFormFields.swift` (`BirthDateField`, `PrivacyConsentSheet`), `BCNavBar.swift`. `AppIcon` → `BCAppIcon.swift`.

### 4.7 `AppState.swift` (1520) → domein-extensions (Fase E)
Opslag (`@Observable`-properties + placeholders + enums) blijft in `AppState.swift`. Gedrag verhuist ongewijzigd naar:
`AppState+Auth.swift`, `AppState+Tasks.swift` (requestHelp/accept/arrive/complete/cancel), `AppState+Reviews.swift`, `AppState+VOGIntake.swift`, `AppState+Admin.swift` (VOG/intake/users/prijzen), `AppState+Organizations.swift` (memberships/koppelcodes), `AppState+Demo.swift` (`loadDemoData`/`clearDemoSeedData`/`activateCordaanDemo`/`defaultTeamPrizes`), `AppState+Privacy.swift` (`resetUserScopedState`/consent), `AppState+Toast.swift`.

### 4.8 `AppStateLive.swift` (1217) → domein-extensions (Fase E)
`AppStateLive+EnumMapping.swift`, `+Utilities.swift` (`isLive`, parseISO, timing-mapping, `serviceTask(from:)`), `+ProfileMapping.swift`, `+ElderlyTasks.swift`, `+BuddyTasks.swift`, `+BuddyProfile.swift`, `+BuddyLocation.swift`, `+ElderlyTaskSync.swift`, `+Teams.swift`, `+Competitions.swift`, `+Inbox.swift`, `+Admin.swift`.

## 5. Duplicatie — **conservatief** consolideren

> ⚠️ Hard principe: alléén verbatim-duplicatie samenvoegen. "Lijkt op elkaar maar niet identiek" (bijv. `StatusTag` vs `BCStatusPill`, inline knoppen vs `BC*Button`) wordt **bewust niet** aangeraakt — dat zou rendering/gedrag kunnen wijzigen. Wat ik laat staan, leg ik uit in het rapport.

Kandidaten die veilig zijn (verbatim helper, geen visuele wijziging) — pas toe **alleen na diff-bevestiging dat output identiek is**:
- Gedeelde datum-/afstandsformatters die letterlijk gekopieerd zijn → `Shared/Formatters.swift` (alleen als de implementaties teken-voor-teken gelijk zijn).
- `ProgressRing` is al `public` en wordt buiten z'n bestand gebruikt → verplaatsen naar design system (pure move, geen render-wijziging).

## 6. Naamgevings-/structuurverbeteringen

- Behoud `BC`-prefix, Nederlandse comments, `fase*`-migratienamen. Geen massale hernoeming.
- Consistente `// MARK:`-secties en member-volgorde (properties → init → body → helpers) per bestand (Fase G), zonder semantiek te wijzigen.
- Per nieuw bestand: kopregel-comment met herkomst/doel in dezelfde stijl als bestaande bestanden.

## 7. Volgorde van uitvoering (bouwen + commit per stap)

1. **Fase B** — dode code (§3) verwijderen → build → commit.
2. **Fase E** — `AppState` + `AppStateLive` opsplitsen (pure extensions) → build → commit. *(Vroeg gedaan: laagste risico, hoogste leesbaarheidswinst, raakt geen views.)*
3. **Fase D** — monster-views opsplitsen per schil: eerst models eruit (`BuddyPoolView`), dan Elderly, Buddy, Admin, Family → build per schil → commit per schil.
4. **Fase C** — veilige duplicatie (§5) → build → commit.
5. **Fase F** — services-laag opschonen (consistentie, géén API-wijziging) → build → commit.
6. **Fase G** — consistentie-pass (MARK/volgorde/opmaak) → build → commit.
7. **Fase H** — eindverificatie + `REFACTOR_REPORT.md`.

## 8. Werkwijze & waarborgen

- Na elke fase: `xcodebuild -scheme "Buddy Care" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`.
- Nieuwe bestanden registreren via `scratchpad/addfiles.rb` (xcodeproj-gem) — geen handmatige pbxproj-edits.
- Elke verplaatsing is teken-voor-teken gelijk; `git diff` controleren op onbedoelde inhoudswijzigingen.
- **Niet** naar `main` pushen/mergen. Branch blijft klaarstaan voor de gebruiker.
