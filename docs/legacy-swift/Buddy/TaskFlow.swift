import SwiftUI
import MapKit
import CoreLocation

// MARK: - Maps routing

/// Opent Apple Maps met een looproute naar het adres van de oudere.
func openRouteInMaps(to task: ServiceTask) {
    let placemark = MKPlacemark(coordinate: task.coordinate)
    let item = MKMapItem(placemark: placemark)
    item.name = "\(task.elderlyName), \(task.elderlyAddress)"
    item.openInMaps(launchOptions: [
        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
    ])
}

// MARK: - Task detail sheet (tapped from map)

struct TaskDetailSheet: View {
    @Environment(AppState.self) private var appState
    let task: ServiceTask
    let onAccept: () -> Void

    @State private var elderlyReviews: [Review] = []
    @State private var reviewsLoaded = false

    private var ratingAverage: Double {
        guard !elderlyReviews.isEmpty else { return 0 }
        return Double(elderlyReviews.map(\.stars).reduce(0, +)) / Double(elderlyReviews.count)
    }

    private var canAccept: Bool {
        // Een buddy mag taken aannemen zodra VOG rond is én de intake akkoord is.
        appState.buddyUser.canAcceptTasks
    }

    /// Echte hemelsbrede afstand tussen het thuisadres van de buddy en het adres
    /// van de hulpvraag (i.p.v. een vaste waarde). Geeft "—" als de buddy nog
    /// geen adres heeft ingevuld (coördinaat staat dan nog op het default-punt).
    private var distanceText: String {
        let from = appState.buddyUser.coordinate
        guard AppState.isResolvedCoordinate(from) else { return "—" }
        let meters = CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: task.coordinate.latitude, longitude: task.coordinate.longitude))
        if meters < 1000 {
            return "± \(Int((meters / 100).rounded() * 100)) m"
        }
        return String(format: "± %.1f km", meters / 1000).replacingOccurrences(of: ".", with: ",")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(BCColors.primary))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.category.displayName)
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Bij \(task.elderlyName), \(task.elderlyAddress)")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                }

                HStack(spacing: BCSpacing.sm) {
                    BCStatusPill(label: "Nieuw · dichtbij", color: BCColors.accentDark, showDot: true)
                    BCStatusPill(label: task.timing.displayName, color: BCColors.primary)
                    Spacer()
                }

                BCCard {
                    // Boven uitlijnen zodat "Afstand" en "Wanneer" (en hun waarden) op
                    // dezelfde hoogte beginnen, ook als "Wanneer" over 2 regels loopt (punt 19).
                    HStack(alignment: .top, spacing: BCSpacing.sm) {
                        statBox(label: "Afstand", value: distanceText, color: BCColors.textPrimary)
                        Divider().frame(height: 44)
                        statBox(label: "Wanneer", value: task.timing.displayName, color: BCColors.primary)
                    }
                }

                if !task.note.isEmpty {
                    BCCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Bericht van \(task.elderlyName)", systemImage: "text.bubble.fill")
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(BCColors.textSecondary)
                            Text(task.note)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                    }
                }

                elderlyReviewsCard

                if canAccept {
                    BCCTAButton(title: "Taak aannemen", icon: "checkmark", iconLeading: true) {
                        onAccept()
                    }
                } else {
                    VStack(spacing: BCSpacing.xs) {
                        BCPrimaryButton(title: "Nog niet beschikbaar", icon: "lock.fill") { }
                            .opacity(0.45)
                            .disabled(true)
                        if vogNotValid {
                            // Punt 22: aparte, duidelijke reden bij een verlopen/ingetrokken of afgewezen VOG.
                            Label(blockedReason, systemImage: "exclamationmark.triangle.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.danger)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(blockedReason)
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                BCSecondaryButton(title: "Naar route bekijken", icon: "map.fill") {
                    openRouteInMaps(to: task)
                }
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
        .task {
            // Beoordelingen van eerdere buddies over deze hulpvrager — alléén hier
            // op het hulpverzoek zichtbaar (de hulpvrager ziet ze zelf nooit).
            if let elderlyId = task.elderlyId {
                elderlyReviews = await appState.fetchElderlyReviewsForRequest(elderlyId: elderlyId)
            }
            reviewsLoaded = true
        }
    }

    /// Wat eerdere buddies over deze hulpvrager schreven (sterren + tekst).
    @ViewBuilder
    private var elderlyReviewsCard: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.sm) {
                    Label("Over \(task.elderlyName)", systemImage: "star.bubble.fill")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textSecondary)
                    Spacer()
                    if !elderlyReviews.isEmpty {
                        HStack(spacing: 4) {
                            BCRatingStars(value: ratingAverage, size: 13)
                            Text(String(format: "%.1f", ratingAverage))
                                .font(BCTypography.captionEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            Text("· \(elderlyReviews.count)")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                        }
                    }
                }

                if !reviewsLoaded {
                    Text("Beoordelingen laden…")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                } else if elderlyReviews.isEmpty {
                    Text("Nog geen beoordelingen van eerdere buddies.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                } else {
                    ForEach(Array(elderlyReviews.prefix(5).enumerated()), id: \.element.id) { index, review in
                        VStack(alignment: .leading, spacing: 3) {
                            BCRatingStars(value: Double(review.stars), size: 12)
                            if !review.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(review.body)
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text("van \(review.authorName)")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if index < min(elderlyReviews.count, 5) - 1 {
                            BCHairline(leading: 0)
                        }
                    }
                }
            }
        }
    }

    /// VOG niet (meer) geldig: verlopen/ingetrokken of afgewezen (punt 22).
    private var vogNotValid: Bool {
        appState.buddyUser.vogStatus == .verlopen || appState.buddyUser.vogStatus == .afgewezen
    }

    /// Reden waarom er (nog) geen hulp kan worden aangenomen, afhankelijk van de VOG-status.
    private var blockedReason: String {
        switch appState.buddyUser.vogStatus {
        case .verlopen:
            return "Je VOG is verlopen of ingetrokken. Vraag op je profiel een nieuwe VOG aan om weer hulp te kunnen aannemen."
        case .afgewezen:
            return "Je VOG is afgewezen. Vraag op je profiel een nieuwe VOG aan om weer hulp te kunnen aannemen."
        default:
            return "Je kunt hulpvragen aannemen zodra je VOG rond is en je korte intake is afgerond."
        }
    }

    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            Text(value)
                .font(BCTypography.title3)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Active task — full screen flow

struct TaskInProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    @State private var stage: Stage = .onTheWay
    @State private var checklist: [ChecklistItem] = [
        ChecklistItem(text: "Aangebeld en welkom geheten", done: false),
        ChecklistItem(text: "Bezoek gestart en kort gepraat", done: false),
        ChecklistItem(text: "Hoofdtaak uitgevoerd", done: false),
        ChecklistItem(text: "Ruimte netjes achtergelaten", done: false)
    ]
    @State private var note: String = ""
    @State private var showCheckIn = false
    @State private var showCheckOut = false
    @State private var showCancelConfirm = false
    @State private var showReview = false    // buddy beoordeelt de hulpvrager na afloop
    @State private var showAccepted = true   // feestelijke bevestiging bij aannemen
    @State private var showChat = false      // gesprek met de hulpvrager (punt 10)

    enum Stage { case onTheWay, atDoor, inProgress, done }

    var body: some View {
        NavigationStack {
            ZStack {
                BCColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Group {
                        switch stage {
                        case .onTheWay: onTheWayContent
                        case .atDoor: atDoorContent
                        case .inProgress: inProgressContent
                        case .done: doneContent
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomBar
                }
            }
            .navigationTitle("Actieve taak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showChat = true } label: {
                        Image(systemName: "message.fill")
                    }
                    .tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }
                        .tint(BCColors.primary)
                }
            }
            .sheet(isPresented: $showChat) {
                ConversationView(partnerId: task.elderlyId, partnerName: task.elderlyName)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInFlowView(task: task) { checkInRecord in
                    showCheckIn = false
                    appState.buddyArrives(checkIn: checkInRecord)
                    stage = .inProgress
                }
            }
            .sheet(isPresented: $showCheckOut) {
                CheckOutFlowView(task: task) {
                    showCheckOut = false
                    appState.buddyCompletes(notes: note)
                    proposeTeamMembershipIfEligible()
                    stage = .done
                    // Vraag de buddy om de hulpvrager te beoordelen (beide kanten).
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showReview = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showReview, onDismiss: { dismiss() }) {
                ReviewView(
                    revieweeName: task.elderlyName,
                    onDismiss: { showReview = false },
                    onSubmit: { stars, body in
                        appState.buddySubmitsReview(for: task, stars: stars, body: body)
                    },
                    question: "Hoe was uw bezoek bij \(task.elderlyName)?",
                    thankYouMessage: "Bedankt voor je inzet! Je beoordeling helpt andere buddies."
                )
            }
            .confirmationDialog(
                "Taak annuleren?",
                isPresented: $showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button("Ja, annuleer deze taak", role: .destructive) {
                    appState.buddyCancelsAcceptedTask()
                    dismiss()
                }
                Button("Nee, ga door", role: .cancel) { }
            } message: {
                Text("De aanvraag wordt direct opnieuw aangeboden aan andere buddies in de buurt. \(task.elderlyName) krijgt hiervan bericht.")
            }
        }
        .overlay {
            if showAccepted {
                BCCelebrationOverlay(
                    icon: "hand.thumbsup.fill",
                    title: "Hulpvraag aangenomen!",
                    subtitle: "Je gaat op weg naar \(task.elderlyName). Bedankt voor je inzet!",
                    autoDismissAfter: 1.9,
                    onDone: { withAnimation { showAccepted = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    /// Invaller → teamlid (fase35 §4.1): heeft deze hulpvrager een zorgkring
    /// waar jij nog niet in zit (en is er plek), stel dan na afloop voor om
    /// vast teamlid te worden. BuddyMapView toont het voorstel-sheet zodra
    /// deze flow gesloten is.
    private func proposeTeamMembershipIfEligible() {
        guard let elderlyId = task.elderlyId else { return }
        guard let team = appState.careTeams.first(where: {
            $0.elderlyId == elderlyId && !$0.isMyTeam && $0.openSpots > 0 && !$0.pendingJoin
        }) else { return }
        // Loopt er al een join-verzoek voor deze kring, dan niet nóg eens vragen.
        guard !appState.careJoinRequests.contains(where: {
            $0.careTeamId == team.id && $0.status == "pending"
        }) else { return }
        appState.pendingTeamProposal = team
    }

    // MARK: stages

    private var onTheWayContent: some View {
        ScrollView {
            VStack(spacing: BCSpacing.md) {
                taskHeader

                BCCard {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                        Text("U bent onderweg naar \(task.elderlyName). Volg de route hieronder.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }

                RoutePreviewView(task: task)
            }
            .padding(BCSpacing.lg)
        }
    }

    private var atDoorContent: some View {
        VStack(spacing: BCSpacing.md) {
            taskHeader
            BCCard {
                VStack(spacing: BCSpacing.md) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(BCColors.primary)
                    Text("Klaar om in te checken?")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Maak een selfie, scan de QR-code op de telefoon van \(task.elderlyName) en bevestig je locatie.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        CheckInStepLabel(icon: "faceid", text: "Selfie (elk bezoek)")
                        CheckInStepLabel(icon: "qrcode.viewfinder", text: "QR-code scannen")
                        CheckInStepLabel(icon: "location.fill", text: "GPS-locatie bevestigen")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(BCSpacing.md)
            }
            Spacer()
        }
        .padding(BCSpacing.lg)
    }

    private var inProgressContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                taskHeader

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        Label("Checklist", systemImage: "checklist")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        ForEach($checklist) { $item in
                            Button {
                                item.done.toggle()
                            } label: {
                                HStack(spacing: BCSpacing.sm) {
                                    Image(systemName: item.done ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(item.done ? BCColors.success : BCColors.textTertiary)
                                    Text(item.text)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                        .strikethrough(item.done, color: BCColors.textTertiary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Label("Bericht naar familie (optioneel)", systemImage: "text.bubble.fill")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textSecondary)
                        TextField("Bijvoorbeeld: Riet was vrolijk vandaag", text: $note, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(BCTypography.body)
                    }
                }
            }
            .padding(BCSpacing.lg)
        }
    }

    private var doneContent: some View {
        VStack(spacing: BCSpacing.md) {
            Spacer()
            BCPopIcon(systemName: "party.popper.fill", color: BCColors.accent, size: 64)
            Text("Goed gedaan!")
                .font(BCTypography.title2)
                .foregroundStyle(BCColors.textPrimary)
            Text(appState.isCordaanBuddy
                 ? "Het bezoek is geregistreerd bij de zorginstelling."
                 : "Bedankt voor je inzet als vrijwilliger!")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(BCSpacing.lg)
    }

    // MARK: shared

    private var taskHeader: some View {
        BCCard {
            HStack {
                Image(systemName: task.category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(BCColors.primary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.category.displayName)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Bij \(task.elderlyName), \(task.elderlyAddress)")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
                BCStatusPill(label: task.status.label, color: task.status.color)
            }
        }
    }

    // MARK: bottom bar

    private var bottomBar: some View {
        VStack {
            Divider()
            switch stage {
            case .onTheWay:
                VStack(spacing: BCSpacing.sm) {
                    BCCTAButton(title: "Ik ben aangekomen", icon: "qrcode", iconLeading: true) {
                        stage = .atDoor
                    }
                    cancelTaskButton
                }
                .padding(BCSpacing.lg)
            case .atDoor:
                VStack(spacing: BCSpacing.sm) {
                    BCCTAButton(title: "Inchecken", icon: "qrcode.viewfinder", iconLeading: true) {
                        showCheckIn = true
                    }
                    cancelTaskButton
                }
                .padding(BCSpacing.lg)
            case .inProgress:
                BCCTAButton(title: "Afronden: scan QR", icon: "qrcode.viewfinder", iconLeading: true) {
                    showCheckOut = true
                }
                .padding(BCSpacing.lg)
            case .done:
                BCPrimaryButton(title: "Sluiten", icon: "checkmark") {
                    dismiss()
                }
                .padding(BCSpacing.lg)
            }
        }
        .background(BCColors.background)
    }

    private var cancelTaskButton: some View {
        Button(role: .destructive) {
            showCancelConfirm = true
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "xmark.circle")
                Text("Taak annuleren")
            }
            .font(BCTypography.bodyEmphasized)
            .foregroundStyle(BCColors.danger)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

private struct ChecklistItem: Identifiable {
    let id = UUID()
    let text: String
    var done: Bool
}

// MARK: - Helper: check-in stap label

private struct CheckInStepLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 20)
            Text(text)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
    }
}
