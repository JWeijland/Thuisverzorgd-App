import SwiftUI
import CoreImage

struct ElderlyHomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    @ObservedObject private var avatars = AvatarStore.shared
    @State private var showRequestFlow = false
    @State private var showBuddyMap = false
    @State private var showReview = false
    @State private var selectedHistoryTask: ServiceTask? = nil
    @State private var showQRCode = false
    @State private var showMessageCompose = false
    @State private var showBuddyRoute = false
    @State private var showCancelConfirm = false

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    /// Er loopt al een hulpvraag (open, onderweg of bezoek bezig). Pas als de
    /// buddy is uitgecheckt (taak afgerond/geannuleerd) mag er een nieuwe komen.
    private var hasOpenRequest: Bool {
        guard let t = appState.activeTaskForElderly else { return false }
        return t.status != .completed && t.status != .cancelled
    }

    /// Rustige melding die de "Nieuwe hulp vragen"-knop vervangt zolang er een
    /// hulpvraag loopt, zodat de oudere niet per ongeluk dubbel aanvraagt.
    private var newRequestBlockedCard: some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: "hourglass")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BCColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(BCColors.surfaceMuted))
                VStack(alignment: .leading, spacing: 2) {
                    Text("U heeft al een hulpvraag lopen")
                        .font(et.heading)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("U kunt pas een nieuwe hulpvraag doen nadat dit bezoek is afgerond.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.md)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                greetingHeader

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        // Zorgkring: klein statuskaartje zolang het team nog
                        // niet live is (werving loopt of wacht op akkoord).
                        if let team = appState.careTeam(for: appState.elderlyUser),
                           team.status == .forming || team.status == .review,
                           appState.elderlyTeamMode != "random_only" {
                            teamStatusCard(team: team)
                                .padding(.horizontal, BCSpacing.lg)
                                .padding(.top, BCSpacing.md)
                        }

                        if let active = appState.activeTaskForElderly, active.status != .completed {
                            ActiveTaskBanner(
                                task: active,
                                routeProgress: appState.buddyRouteProgress,
                                onCall: callBuddy,
                                onMessage: sendMessage,
                                onShowQR: { showQRCode = true },
                                onCancel: { showCancelConfirm = true },
                                onShowBuddyLocation: { showBuddyRoute = true }
                            )
                            // ServiceTask vergelijkt alleen op id; deze id dwingt een
                            // verse hertekening af zodra status of buddy verandert.
                            .id("\(active.id)-\(active.status.rawValue)-\(active.assignedBuddyName ?? "none")")
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)
                            .animation(.easeInOut(duration: 0.25), value: active.status)
                            .animation(.easeInOut(duration: 0.25), value: active.assignedBuddyName)
                        }

                        // Belangrijkste actie — wit & rustig (variant C).
                        // Zolang er een hulpvraag loopt (open → onderweg → bezoek)
                        // kan de oudere géén nieuwe aanvraag doen; dat mag pas weer
                        // nadat de buddy is uitgecheckt en het bezoek is afgerond.
                        if hasOpenRequest {
                            newRequestBlockedCard
                        } else {
                            BCHelpHeroCard(
                                title: "Hulp vragen",
                                subtitle: "Een vertrouwde buddy uit de buurt komt u helpen."
                            ) {
                                showRequestFlow = true
                            }
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)
                        }

                        // Ook handig
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Text("Ook handig")
                                .font(et.heading)
                                .foregroundStyle(BCColors.textPrimary)
                                .padding(.horizontal, BCSpacing.lg)

                            HStack(alignment: .top, spacing: BCSpacing.md) {
                                BCQuickTile(
                                    title: "Buddies in de buurt",
                                    subtitle: "Bekijk wie er nu beschikbaar is",
                                    icon: "tv-kaart",
                                    color: BCColors.primary
                                ) {
                                    showBuddyMap = true
                                }
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }

                        // Vaste buddies verdienen een vaste plek op de hulppagina:
                        // vertrouwde gezichten maken hulp vragen laagdrempeliger.
                        if !appState.favoriteBuddyNames.isEmpty {
                            favoriteBuddiesCard
                                .padding(.horizontal, BCSpacing.lg)
                        }

                        upcomingSection

                        // Spacer for SOS floating button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.bottom, BCSpacing.lg)
                }
            }

            sosFloatingButton
                .padding(.trailing, BCSpacing.lg)
                .padding(.bottom, BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showMessageCompose) {
            BuddyMessageComposeSheet(
                buddyName: appState.activeTaskForElderly?.assignedBuddyName
            ) { text in
                appState.elderlySendsMessageToBuddy(text)
            }
        }
        .sheet(isPresented: $showRequestFlow) {
            RequestHelpFlow()
        }
        .fullScreenCover(isPresented: $showBuddyMap) {
            ElderlyBuddyMapView()
        }
        .sheet(isPresented: $showQRCode) {
            ElderlyQRCodeSheet()
        }
        .confirmationDialog("Hulpvraag intrekken?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Ja, hulpvraag intrekken", role: .destructive) {
                appState.elderlyCancelsTask()
            }
            Button("Nee, laat staan", role: .cancel) { }
        } message: {
            Text("De hulpvraag wordt geannuleerd en verdwijnt voor buddies in de buurt.")
        }
        .sheet(item: $selectedHistoryTask) { task in
            PastVisitSheet(task: task)
        }
        .fullScreenCover(isPresented: $showReview) {
            if !appState.isCordaanElderly,
               let task = appState.taskHistory.first,
               let buddyName = task.assignedBuddyName {
                ReviewView(
                    revieweeName: buddyName,
                    onDismiss: { showReview = false },
                    onMakeFavorite: {
                        appState.addFavoriteBuddy(name: buddyName, buddyId: task.assignedBuddyId)
                    }
                )
            }
        }
        .onChange(of: appState.activeTaskForElderly?.status) { _, newStatus in
            // Zodra de buddy scant (inchecken) of het bezoek afrondt (uitchecken),
            // verandert de status. De QR-code is dan niet meer nodig → sluit 'm en
            // laat de hulppagina vanzelf weer zien. Ook de live-route sluit bij een
            // afgerond/geannuleerd bezoek.
            if showQRCode { showQRCode = false }
            if newStatus == .completed || newStatus == .cancelled || newStatus == nil {
                if showBuddyRoute { showBuddyRoute = false }
            }
            if newStatus == .completed && !appState.isCordaanElderly {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showReview = true
                }
            }
        }
        .fullScreenCover(isPresented: $showBuddyRoute) {
            if let active = appState.activeTaskForElderly {
                ElderlyBuddyRouteView(task: active)
            }
        }
        .task {
            // Live: houd de actieve hulpvraag up-to-date met wat de buddy doet
            // (aannemen, inchecken, uitchecken). In demo-modus doet dit niets.
            appState.startElderlyTaskSync()
            // Volg de positie van de buddy die onderweg is (voortgangsbalk + kaart).
            appState.startBuddyLiveLocationSync()
            // Zorgkring: teamstatus vers ophalen voor het statuskaartje.
            await appState.loadCareTeams()
        }
    }

    // MARK: - Zorgkring-status

    /// Klein statuskaartje zolang het team nog niet live is. Bij "wacht op
    /// akkoord" opent een tik het Buddies-tabblad met de review.
    private func teamStatusCard(team: CareTeam) -> some View {
        Button {
            appState.elderlyTabSelection = 2
        } label: {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: team.status == .review
                            ? "checkmark.seal.fill"
                            : "person.2.wave.2.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.status == .review
                            ? "Uw team wacht op uw akkoord"
                            : "We zoeken buddies voor uw team…")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(team.status == .review
                            ? "Bekijk uw buddies en geef uw akkoord."
                            : "\(team.memberCount) van minimaal \(team.minSize) gevonden. U krijgt bericht zodra uw team er staat.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Greeting header

    /// Kaart met de vaste buddies van deze cliënt — tikken opent het
    /// Buddies-tabblad. Vaste buddies staan zo altijd binnen handbereik.
    private var favoriteBuddiesCard: some View {
        Button {
            appState.elderlyTabSelection = 2
        } label: {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.danger.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BCColors.danger)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.favoriteBuddyNames.count == 1
                            ? "Uw vaste buddy"
                            : "Uw vaste buddies")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(appState.favoriteBuddyNames.sorted().joined(separator: " en "))
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Goedemorgen"
        case 12..<18: return "Goedemiddag"
        default:      return "Goedenavond"
        }
    }

    private var greetingHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            HStack(spacing: BCSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting + ",")
                        .font(BCTypography.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    // Merktaal v2.1: de herokop eindigt op de Hulpgroene punt
                    // (één stijlmiddel, één keer per scherm).
                    BCHeroKop(text: appState.elderlyUser.firstName,
                              font: BCTypography.titleEmphasized,
                              color: .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                ZStack {
                    if let image = avatars.image {
                        // Eigen profielfoto van de hulpvrager.
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle().fill(.white)
                        Text(String(appState.elderlyUser.firstName.prefix(1)))
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.navy700)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 2))
                .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .frame(height: 76)
    }

    /// Belt de toegewezen buddy van de actieve hulpvraag (niet het support-nummer).
    /// Is er (nog) geen nummer bekend, dan tonen we een nette melding.
    private func callBuddy() {
        guard let phone = appState.activeTaskForElderly?.assignedBuddyPhone,
              !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appState.showToast(text: "We hebben nog geen telefoonnummer van je buddy.",
                               icon: "phone.badge.plus")
            return
        }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            appState.showToast(text: "Bellen lukt niet op dit apparaat.", icon: "phone.down.fill")
        }
    }

    private func sendMessage() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showMessageCompose = true
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Eerder geholpen")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Tik op een bezoek om te beoordelen")
                    .font(et.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.horizontal, BCSpacing.lg)

            if appState.taskHistory.isEmpty {
                BCCard {
                    Text("Nog geen eerdere bezoeken.")
                        .font(et.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(.horizontal, BCSpacing.lg)
            } else {
                let limit = largeText ? 2 : 5
                let tasks = Array(appState.taskHistory.prefix(limit))
                VStack(spacing: BCSpacing.sm) {
                    ForEach(tasks) { task in
                        let rated = appState.taskRatings[task.id]
                        let needsReview = rated == nil && !appState.skippedReviews.contains(task.id)
                        Button { selectedHistoryTask = task } label: {
                            BCCard {
                                HStack(spacing: BCSpacing.md) {
                                    let iconSize: CGFloat = largeText ? 52 : 44
                                    AppIcon(name: task.category.brandIcon, size: largeText ? 30 : 24)
                                        .frame(width: iconSize, height: iconSize)
                                        .background(Circle().fill(BCColors.primary.opacity(0.10)))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.category.displayName)
                                            .font(et.body)
                                            .foregroundStyle(BCColors.textPrimary)
                                        if let buddy = task.assignedBuddyName {
                                            HStack(spacing: BCSpacing.xs) {
                                                Text("Met \(buddy)")
                                                    .font(et.caption)
                                                    .foregroundStyle(BCColors.textSecondary)
                                                if !appState.isCordaanElderly,
                                                   appState.favoriteBuddyNames.contains(buddy) {
                                                    Image(systemName: "heart.fill")
                                                        .font(.system(size: largeText ? 13 : 10))
                                                        .foregroundStyle(BCColors.danger)
                                                }
                                            }
                                        }
                                        if let date = task.completedAt {
                                            Text(BCFormatters.relativeDateTime.localizedString(for: date, relativeTo: Date()))
                                                .font(et.caption)
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                        if !appState.isCordaanElderly {
                                            HStack(spacing: 3) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Image(systemName: star <= (rated ?? 0) ? "star.fill" : "star")
                                                        .font(.system(size: 10, weight: .regular))
                                                        .foregroundStyle(star <= (rated ?? 0) ? BCColors.warning : BCColors.border)
                                                }
                                            }
                                            .padding(.top, 1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: largeText ? 18 : 13, weight: .semibold))
                                        .foregroundStyle(BCColors.textTertiary)
                                }
                            }
                            .overlay(alignment: .leading) {
                                if needsReview && !appState.isCordaanElderly {
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: BCRadius.lg,
                                        bottomLeadingRadius: BCRadius.lg,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 0,
                                        style: .continuous
                                    )
                                    .fill(BCColors.accent)
                                    .frame(width: 4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
            }
        }
    }

    private var sosFloatingButton: some View {
        Button {
            appState.showSOS = true
        } label: {
            VStack(spacing: 0) {
                Image(systemName: "phone.fill.arrow.up.right")
                    .font(.system(size: 22, weight: .heavy))
                Text("SOS")
                    .font(BCTypography.captionEmphasized)
            }
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(
                Circle().fill(BCColors.danger)
            )
            .shadow(color: BCColors.danger.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("SOS knop, alarmeer hulp")
        .buttonStyle(.plain)
    }
}

