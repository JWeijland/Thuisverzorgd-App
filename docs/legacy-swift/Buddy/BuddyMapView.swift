import SwiftUI
import MapKit

struct BuddyMapView: View {
    @Environment(AppState.self) private var appState
    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: MockData.amsterdamCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        ))
    )
    @State private var selectedTask: ServiceTask? = nil
    @State private var showActiveTask = false
    /// Gecombineerde ingang naar Competitie én Teams (1 rondje, tabs binnenin).
    @State private var showPool = false
    /// Begin-tab van de pool-pagina (0 = competitie, 1 = teams). Vanuit een
    /// inbox-bericht kunnen we hiermee direct de juiste tab openen.
    @State private var poolTab = 0
    /// Deep-link vanuit een inbox-bericht: open direct dit team, of de eigen competitie.
    @State private var poolTeamId: UUID? = nil
    @State private var poolOpenCompetition = false
    @State private var showAchievements = false
    @State private var showInbox = false
    /// Actief 1-op-1 gesprek (geopend vanuit een bericht in de inbox).
    @State private var conversationTarget: ConversationTarget? = nil
    /// Zorgkring die als detail-sheet openstaat (fase35).
    @State private var detailTeam: CareTeam? = nil
    /// Team-uitnodiging die als kaart openstaat (fase35, ring-dispatch).
    @State private var inviteToShow: TeamInvite? = nil
    /// Invaller → teamlid (fase35 §4.1): voorstel om vast lid te worden.
    @State private var teamProposal: CareTeam? = nil
    /// Huidig zichtbaar kaartbeeld — voedt de "open"-teller (punt 21).
    @State private var visibleRegion: MKCoordinateRegion? = nil
    /// Lijst met open hulpvragen (geopend door op de "open"-pil te tikken).
    @State private var showOpenList = false

    private var gameStats: GameStats { GameStatsProvider.make(for: appState.buddyUser) }
    private var medalsUnlocked: Int { AchievementData.totalUnlocked(for: appState.buddyUser, stats: gameStats) }

    /// Teampunten op de kaart-badge: de échte punten van jouw team (uit
    /// appState.teams). Zolang er nog niets geladen is, val terug op de
    /// voorbeeld-stats. 0 als je (nog) in geen team zit.
    private var teamPointsBadge: Int {
        guard !appState.teams.isEmpty else { return gameStats.teamPoints }
        return appState.teams.first(where: { $0.isMyTeam })?.totalPoints ?? 0
    }

    /// Competitiepunten op de kaart-badge: je punten in je actieve competitie.
    /// Terugval op de voorbeeld-stats zolang er nog niets geladen is.
    private var competitionPointsBadge: Int {
        guard !appState.competitions.isEmpty else { return gameStats.competitionPoints }
        let active = appState.competitions.first { $0.isRegistered && $0.status != .afgelopen }
        return active?.members.first(where: { $0.isCurrentUser })?.points ?? 0
    }

    var visibleTasks: [ServiceTask] {
        guard appState.isAvailableNow else { return [] }
        // Toon alleen écht openstaande hulpvragen. Zodra een taak is aangenomen of
        // afgerond verdwijnt het pinnetje meteen van de kaart. Team-exclusieve
        // vragen (fase35) zijn alleen zichtbaar voor leden van die zorgkring;
        // de open-pil telt dus alleen wat deze buddy mag zien.
        return appState.openTasks.filter { task in
            guard task.status == .open else { return false }
            if task.visibility == "pool" { return true }
            return appState.careTeams.contains {
                $0.isMyTeam && $0.elderlyId != nil && $0.elderlyId == task.elderlyId
            }
        }
    }

    /// De zorgkringen waar deze buddy in zit — de centrale ingang op de kaart.
    private var myCareTeams: [CareTeam] { appState.careTeams.filter { $0.isMyTeam } }

    /// Referentiepunt voor "dichtstbij": de live-locatie als die bekend is, anders
    /// het opgeslagen adres van de buddy.
    private var userCoordinate: CLLocationCoordinate2D {
        if let lat = appState.buddyLiveLatitude, let lon = appState.buddyLiveLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return appState.buddyUser.coordinate
    }

    /// Open hulpvragen binnen het huidige kaartbeeld (punt 21). Zolang er nog geen
    /// region bekend is, tellen alle open hulpvragen mee.
    private var tasksInView: [ServiceTask] {
        guard let region = visibleRegion else { return visibleTasks }
        return visibleTasks.filter { Self.region(region, contains: $0.coordinate) }
    }

    /// Open hulpvragen in beeld, dichtstbij eerst.
    private var openTasksSorted: [ServiceTask] {
        let me = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        return tasksInView.sorted {
            me.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude))
            < me.distance(from: CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude))
        }
    }

    /// Valt de coördinaat binnen het zichtbare kaartbeeld?
    private static func region(_ r: MKCoordinateRegion, contains c: CLLocationCoordinate2D) -> Bool {
        abs(c.latitude - r.center.latitude) <= r.span.latitudeDelta / 2 &&
        abs(c.longitude - r.center.longitude) <= r.span.longitudeDelta / 2
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: Binding(
                get: { selectedTask?.id },
                set: { id in
                    if let id, let task = appState.openTasks.first(where: { $0.id == id }) {
                        selectedTask = task
                    } else {
                        selectedTask = nil
                    }
                })) {
                ForEach(visibleTasks) { task in
                    Annotation(task.category.displayName, coordinate: task.coordinate) {
                        MapPin(task: task,
                               isSelected: selectedTask?.id == task.id,
                               shouldPulse: visibleTasks.count >= 2 && selectedTask?.id != task.id)
                    }
                    .tag(task.id)
                }
                UserAnnotation()
            }
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .continuous) { context in
                visibleRegion = context.region
            }

            VStack(spacing: BCSpacing.sm) {
                topBar
                HStack(spacing: BCSpacing.sm) {
                    openCountPill
                    Spacer()
                    inboxButton
                }
                if !appState.isAvailableNow {
                    offlineBanner
                }
                // Loopt er nog een aangenomen hulpvraag terwijl het scherm dicht is?
                // Toon een duidelijke terugkeer-knop, zodat de buddy 'm niet per
                // ongeluk laat hangen (de oudere wacht anders voor niets).
                if let active = appState.activeTaskForBuddy, !showActiveTask {
                    activeTaskResumeBanner(active)
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.top, BCSpacing.sm)

            // Alle spel-rondjes netjes onder elkaar aan 1 kant (rechts):
            //  1) Competitie & Teams samengevoegd tot 1 rondje (tabs binnenin).
            //  2) Persoonlijke prestaties/medailles blijft een apart rondje.
            VStack(spacing: BCSpacing.md) {
                GameMapButton(icon: "tv-beker", tint: Palette.purple, value: "\(competitionPointsBadge + teamPointsBadge)") {
                    poolTab = 0
                    poolTeamId = nil
                    poolOpenCompetition = false
                    showPool = true
                }
                GameMapButton(icon: "tv-medaille", tint: [Color(red: 0.95, green: 0.72, blue: 0.20), Color(red: 0.83, green: 0.48, blue: 0.15)],
                              value: "\(medalsUnlocked)") {
                    showAchievements = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, BCSpacing.md)
            .padding(.bottom, BCSpacing.xxl)

            // Fase35: de zorgkring is de centrale ingang. Onderaan de kaart een
            // rij kaartjes met je eigen kringen; daarboven een opvallende banner
            // zodra een hulpvrager in de buurt een team zoekt.
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                if let invite = appState.openTeamInvites.first {
                    inviteBanner(invite)
                }
                if !myCareTeams.isEmpty {
                    careTeamsStrip
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, BCSpacing.md)
            .padding(.bottom, BCSpacing.lg)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPool) {
            BuddyPoolView(initialTab: poolTab, initialTeamId: poolTeamId,
                          openActiveCompetition: poolOpenCompetition)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInbox) {
            InboxView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $conversationTarget) { target in
            ConversationView(partnerId: target.partnerId, partnerName: target.partnerName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $detailTeam) { team in
            NavigationStack { CareTeamDetailView(teamId: team.id) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $inviteToShow) { invite in
            TeamInviteSheet(invite: invite)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // Invaller → teamlid (fase35 §4.1): voorstel-sheet na een afgeronde
        // hulpvraag bij een hulpvrager met een zorgkring waar je niet in zit.
        .sheet(item: $teamProposal, onDismiss: { appState.pendingTeamProposal = nil }) { team in
            TeamProposalSheet(team: team)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOpenList) {
            OpenTasksListView(tasks: openTasksSorted, userCoordinate: userCoordinate) { task in
                showOpenList = false
                // Even wachten tot de lijst dicht is, dan het detail openen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    selectedTask = task
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Punt 10: een aangetikt inbox-bericht kiest een bestemming. De inbox sluit
        // zichzelf; hier openen we (na het sluiten) de juiste pagina.
        .onChange(of: appState.inboxDestination) { _, dest in
            guard let dest else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                switch dest {
                case .teams(let teamId):
                    poolTab = 1
                    poolTeamId = teamId
                    poolOpenCompetition = false
                    showPool = true
                case .competition:
                    poolTab = 0
                    poolTeamId = nil
                    poolOpenCompetition = true
                    showPool = true
                case .map:
                    break   // we zijn al op de kaart
                case .task(let id):
                    // Open het specifieke hulpverzoek om aan te nemen. Is het niet (meer)
                    // te vinden (al aangenomen of geen id), val dan terug op de lijst.
                    if let id, let task = appState.openTasks.first(where: { $0.id == id }) {
                        selectedTask = task
                    } else {
                        showOpenList = true
                    }
                case .conversation(let id, let name):
                    conversationTarget = ConversationTarget(partnerId: id, partnerName: name)
                case .careTeam(let careTeamId):
                    // Open de specifieke zorgkring; niet (meer) te vinden → val
                    // terug op het zorgkring-overzicht in de Teams-tab.
                    if let id = careTeamId, let team = appState.careTeams.first(where: { $0.id == id }) {
                        detailTeam = team
                    } else {
                        poolTab = 1
                        poolTeamId = nil
                        poolOpenCompetition = false
                        showPool = true
                    }
                case .teamInvite(let careTeamId):
                    // Open de uitnodigingskaart voor dat team; anders de eerste
                    // openstaande uitnodiging.
                    if let invite = appState.openTeamInvites.first(where: { $0.careTeamId == careTeamId })
                        ?? appState.openTeamInvites.first {
                        inviteToShow = invite
                    }
                }
                appState.inboxDestination = nil
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task) {
                appState.buddyAcceptsTask(task)
                selectedTask = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showActiveTask) {
            if let task = appState.activeTaskForBuddy {
                TaskInProgressView(task: task)
            }
        }
        .onChange(of: appState.activeTaskForBuddy) { _, newValue in
            // Nieuwe taak → toon de flow; weggevallen (bv. ingetrokken) → sluit 'm.
            showActiveTask = (newValue != nil)
        }
        // Het team-voorstel (gezet in TaskFlow bij het afronden) pas tonen zodra
        // de taak-flow gesloten is, anders botsen de presentaties.
        .onChange(of: appState.pendingTeamProposal) { _, team in
            guard let team, !showActiveTask else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { teamProposal = team }
        }
        .onChange(of: showActiveTask) { _, isShown in
            guard !isShown, let team = appState.pendingTeamProposal else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { teamProposal = team }
        }
        .overlay {
            if let review = appState.pendingNewReview {
                BCCelebrationOverlay(
                    icon: "star.fill",
                    title: "Nieuwe beoordeling!",
                    subtitle: "\(review.stars) sterren · \u{201C}\(review.body)\u{201D} van \(review.authorName)",
                    accent: BCColors.warning,
                    autoDismissAfter: 3.0,
                    onDone: { appState.pendingNewReview = nil }
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .task {
            // Live-modus: haal open hulpvragen uit Supabase (poll). In demo-modus
            // gebeurt niets en blijft de mock-lijst staan.
            appState.startBuddyTaskSync()
            // Een eventueel nog lopende, aangenomen hulpvraag terughalen (bv. na
            // herstart) zodat de buddy 'm kan hervatten i.p.v. de oudere te laten
            // wachten.
            await appState.refreshBuddyActiveTask()
            // Teams + berichten-inbox live synchroniseren (fase18). In demo-modus
            // doet dit niets; de inbox is daar lokaal geseed.
            appState.startInboxSync()
            // Fase35: openstaande team-uitnodigingen en eigen join-verzoeken
            // ophalen (voedt de banner en de "Verzoek gestuurd"-status).
            await appState.loadTeamInvites()
            await appState.loadCareJoinRequests()
            // Even wachten tot reviews geladen zijn, dan een eventuele nieuwe tonen.
            try? await Task.sleep(nanoseconds: 600_000_000)
            appState.checkForNewReviews()
        }
    }

    private var topBar: some View {
        HStack(spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                Text("Thuisverzorgd")
                    .font(BCFont.heading(15, .bold))
                    .foregroundStyle(BCColors.navy900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: BCSpacing.xs)
            availabilityPill
        }
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.sm)
        .background(
            Capsule(style: .continuous).fill(BCColors.surface)
        )
        .bcSoftShadow(.raised)
    }

    /// Aantal open hulpvragen binnen het huidige kaartbeeld (telt mee bij zoomen/
    /// pannen). Tikken opent de lijst, dichtstbij bovenaan (punt 21).
    private var openCountPill: some View {
        Button {
            showOpenList = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                Text("\(tasksInView.count) open")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.navy900)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(BCColors.surface))
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
        .disabled(tasksInView.isEmpty)
        .opacity(tasksInView.isEmpty ? 0.6 : 1)
    }

    private var inboxButton: some View {
        Button {
            showInbox = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BCColors.navy900)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(BCColors.surface))
                    .bcSoftShadow(.raised)
                if appState.unreadInboxCount > 0 {
                    Text("\(min(appState.unreadInboxCount, 9))\(appState.unreadInboxCount > 9 ? "+" : "")")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Circle().fill(BCColors.danger))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var availabilityPill: some View {
        Button {
            appState.isAvailableNow.toggle()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isAvailableNow ? BCColors.navy900 : BCColors.textTertiary)
                    .frame(width: 8, height: 8)
                Text(appState.isAvailableNow ? "Beschikbaar" : "Uit")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(appState.isAvailableNow ? BCColors.navy900 : BCColors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous).fill(
                    appState.isAvailableNow
                        ? BCColors.accent
                        : BCColors.surfaceMuted
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var offlineBanner: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Je staat op niet-beschikbaar")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Zet \u{201C}Aan\u{201D} om hulpaanvragen in de buurt te ontvangen")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
            Spacer()
            Button("Aanzetten") {
                appState.isAvailableNow = true
            }
            .font(BCTypography.captionEmphasized)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(BCColors.accent))
            .foregroundStyle(BCColors.navy900)
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.raised)
    }

    // MARK: Zorgkringen op de kaart (fase35)

    /// Opvallende banner zodra een hulpvrager in de buurt een team zoekt.
    /// Tikken opent de uitnodigingskaart.
    private func inviteBanner(_ invite: TeamInvite) -> some View {
        Button {
            inviteToShow = invite
        } label: {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.18)))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(invite.elderlyName) zoekt een team aan buddies. Doe jij mee?")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tik voor de uitnodiging")
                        .font(BCTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.primary)
            )
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
    }

    /// Horizontale rij kaartjes met je eigen zorgkringen: naam + aantal open
    /// momenten. Tikken opent het teamdetail (schema, leden, punten).
    private var careTeamsStrip: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            Text("Mijn zorgkringen")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.navy900)
                .padding(.horizontal, BCSpacing.sm)
                .padding(.vertical, 4)
                .background(Capsule(style: .continuous).fill(BCColors.surface.opacity(0.92)))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BCSpacing.sm) {
                    ForEach(myCareTeams) { team in
                        careTeamChip(team)
                    }
                }
            }
        }
    }

    private func careTeamChip(_ team: CareTeam) -> some View {
        // Fase36: groene gloed zodra het rooster van deze kring helemaal is
        // ingevuld — in één oogopslag "het zit goed".
        let filled = team.scheduleFilled()
        let swaps = team.visits.filter { $0.date > Date() && $0.swapRequested }.count
        return Button {
            detailTeam = team
        } label: {
            HStack(spacing: BCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(team.name)
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                        .lineLimit(1)
                    let open = team.openVisits().count
                    if filled {
                        Label("Rooster rond", systemImage: "checkmark.seal.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.accentDark)
                    } else if swaps > 0 {
                        Text(swaps == 1 ? "1 x vervanging gezocht" : "\(swaps) x vervanging gezocht")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.warning)
                    } else {
                        Text(open == 0 ? "Alles opgepakt"
                             : open == 1 ? "1 open moment" : "\(open) open momenten")
                            .font(BCTypography.caption)
                            .foregroundStyle(open == 0 ? BCColors.textSecondary : BCColors.warning)
                    }
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(BCColors.surface))
            .overlay(Capsule(style: .continuous).stroke(filled ? BCColors.accent : .clear, lineWidth: 2))
            .shadow(color: filled ? BCColors.accent.opacity(0.55) : BCColors.primaryDark.opacity(0.12),
                    radius: filled ? 10 : 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    /// Terugkeer-knop naar een lopende, aangenomen hulpvraag (na "Sluiten").
    private func activeTaskResumeBanner(_ task: ServiceTask) -> some View {
        Button {
            showActiveTask = true
        } label: {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.18)))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Je hebt een actieve hulpvraag")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                    Text("Bij \(task.elderlyName), tik om te hervatten of te annuleren")
                        .font(BCTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.primary)
            )
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
    }

}

private struct MapPin: View {
    let task: ServiceTask
    let isSelected: Bool
    var shouldPulse: Bool = false

    @State private var pulse = false

    private var diameter: CGFloat { isSelected ? 52 : 44 }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Zachte aandacht-halo die meeademt wanneer er meerdere
                // aanvragen in de buurt zijn — trekt de blik naar een makkelijke klus.
                if shouldPulse {
                    Circle()
                        .fill(BCColors.accent.opacity(0.35))
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(pulse ? 1.9 : 1.0)
                        .opacity(pulse ? 0 : 0.6)
                }
                Circle()
                    .fill(shouldPulse ? BCColors.accentDark : BCColors.primary)
                    .frame(width: diameter, height: diameter)
                    .shadow(color: BCColors.primaryDark.opacity(0.25), radius: 6, x: 0, y: 3)
                    .scaleEffect(shouldPulse && pulse ? 1.12 : 1.0)
                Image(systemName: task.category.icon)
                    .font(.system(size: isSelected ? 22 : 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(shouldPulse ? BCColors.accentDark : BCColors.primary)
                .frame(width: 12, height: 8)
        }
        .onAppear {
            guard shouldPulse else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: shouldPulse) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Lijst met open hulpvragen (dichtstbij eerst) — punt 21

private struct OpenTasksListView: View {
    let tasks: [ServiceTask]
    let userCoordinate: CLLocationCoordinate2D
    let onSelect: (ServiceTask) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    VStack(spacing: BCSpacing.md) {
                        BCPillenPaar()
                        Text("Geen open hulpvragen in beeld")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Zoom uit of verplaats de kaart om meer hulpvragen te zien.")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, BCSpacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(tasks) { task in
                            Button { onSelect(task) } label: { row(task) }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: BCSpacing.xs, leading: BCSpacing.lg,
                                                          bottom: BCSpacing.xs, trailing: BCSpacing.lg))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(BCColors.background)
            .navigationTitle("Open hulpvragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluit") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private func row(_ task: ServiceTask) -> some View {
        HStack(spacing: BCSpacing.md) {
            ZStack {
                Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: task.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.category.displayName)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Bij \(task.elderlyName) · \(task.timing.displayName)")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(distanceText(task.coordinate))
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.accentDark)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BCColors.textTertiary)
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }

    private func distanceText(_ c: CLLocationCoordinate2D) -> String {
        let meters = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            .distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
        if meters < 1000 { return "± \(Int((meters / 50).rounded() * 50)) m" }
        return "± " + String(format: "%.1f km", meters / 1000).replacingOccurrences(of: ".", with: ",")
    }
}

#Preview {
    BuddyMapView().environment(AppState())
}
