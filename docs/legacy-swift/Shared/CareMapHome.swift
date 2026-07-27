import SwiftUI
import MapKit
import CoreLocation

// ============================================================
// CareMapHome — de kaart als voorpagina voor de hulpvrager en familie
// (fase36, customer journey JW11: "de kaart als voorpagina geeft de indruk
// dat de app leeft, denk aan Uber").
//
// Op de kaart:
//   • Teamgenoten — prominente druppels (variant 1A: navy + Hulpgroene ring,
//     hart-badge, naam-pil) met de profielfoto van de vrijwilliger.
//   • Losse buddies in de buurt — kleinere, zachtgroene druppels.
//   • Andere zorgkringen — subtiel hartje op de benaderde locatie (~1 km).
//
// Onderaan prominent de eigen zorgkring: status, gezichten, eerstvolgend
// bezoek en een groene gloed zodra het hele rooster is ingevuld. Tikken
// opent het teamoverzicht (rooster, leden) of de teamchat. De bestaande
// opties (hulp vragen, buddies, profiel) blijven bereikbaar via de tabs
// en de knoppenrij op de kaart.
// ============================================================

/// Kaart-home van de hulpvrager (versimpeld, grote knoppen).
struct ElderlyMapHomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        CareMapHomeView(context: .elderly, tabSelection: $state.elderlyTabSelection)
    }
}

/// Kaart-home van het familielid (beheert namens de naaste).
struct FamilyMapHomeView: View {
    @Binding var tabSelection: Int

    var body: some View {
        CareMapHomeView(context: .family, tabSelection: $tabSelection)
    }
}

enum CareMapContext {
    case elderly
    case family

    /// Tab-index van het teambeheer (ouder: Buddies-tab, familie: Overzicht).
    var teamTab: Int {
        switch self {
        case .elderly: return 2
        case .family:  return 1
        }
    }
}

struct CareMapHomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    let context: CareMapContext
    @Binding var tabSelection: Int

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: MockData.amsterdamCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    ))
    @State private var showRequestFlow = false
    @State private var showInbox = false
    @State private var showTeamChat = false
    @State private var conversationTarget: ConversationTarget? = nil
    @State private var centeredOnce = false

    private var et: BCElderlyType { BCElderlyType(large: largeText && context == .elderly) }

    // MARK: Gegevens

    /// Voor wie deze kaart is: de hulpvrager zelf of de beheerde naaste.
    private var targetElderly: ElderlyUser {
        context == .elderly ? appState.elderlyUser : appState.activeFamilyElderly
    }

    private var myTeam: CareTeam? {
        if context == .elderly, appState.elderlyTeamMode == "random_only" { return nil }
        return appState.careTeam(for: targetElderly)
    }

    private var teamMemberIds: Set<UUID> {
        Set((myTeam?.members ?? []).compactMap(\.buddyId))
    }

    /// Druppels van teamgenoten: leden van de eigen kring met bekende locatie.
    private var teamMatePins: [MapBuddyPin] {
        guard myTeam?.status == .live || myTeam?.status == .review else { return [] }
        return appState.mapBuddyPins.filter { teamMemberIds.contains($0.id) }
    }

    /// Losse buddies in de buurt (beschikbaar, geen teamgenoot), dichtstbij
    /// eerst en begrensd zodat de kaart rustig blijft.
    private var looseBuddyPins: [MapBuddyPin] {
        let home = CLLocation(latitude: targetElderly.coordinate.latitude,
                              longitude: targetElderly.coordinate.longitude)
        return appState.mapBuddyPins
            .filter { $0.isAvailable && !teamMemberIds.contains($0.id) }
            .sorted {
                home.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude))
                < home.distance(from: CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude))
            }
            .prefix(30)
            .map { $0 }
    }

    /// Andere zorgkringen in de buurt, op hun benaderde (~1 km) locatie.
    private var otherTeams: [CareTeam] {
        appState.careTeams
            .filter { $0.id != myTeam?.id && $0.approxCoordinate != nil }
            .prefix(15)
            .map { $0 }
    }

    /// Er loopt al een hulpvraag voor deze hulpvrager.
    private var hasOpenRequest: Bool {
        guard context == .elderly, let t = appState.activeTaskForElderly else { return false }
        return t.status != .completed && t.status != .cancelled
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            map

            VStack(spacing: BCSpacing.sm) {
                topBar
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.top, BCSpacing.sm)

            // Onderaan: zorgkring prominent + de hulp-knop.
            VStack(spacing: BCSpacing.sm) {
                Spacer()
                careTeamCard
                ctaRow
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.bottom, BCSpacing.md)

            if context == .elderly {
                sosFloatingButton
            }
        }
        .sheet(isPresented: $showRequestFlow) {
            if context == .family {
                RequestHelpFlow(onBehalfOf: targetElderly)
            } else {
                RequestHelpFlow()
            }
        }
        .sheet(isPresented: $showInbox) {
            InboxView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTeamChat) {
            if let team = myTeam {
                TeamChatView(teamId: team.id, teamName: team.name, channels: [.all])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $conversationTarget) { target in
            ConversationView(partnerId: target.partnerId, partnerName: target.partnerName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // Inbox-bericht aangetikt → relevante plek openen (patroon punt 10).
        .onChange(of: appState.inboxDestination) { _, dest in
            guard let dest else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                switch dest {
                case .careTeam, .teams:
                    tabSelection = context.teamTab
                case .conversation(let id, let name):
                    conversationTarget = ConversationTarget(partnerId: id, partnerName: name)
                default:
                    break
                }
                appState.inboxDestination = nil
            }
        }
        .task {
            appState.startInboxSync()
            await appState.loadCareTeams()
            await appState.loadCareJoinRequests()
            await appState.loadBuddyMapPins()
            centerOnHome()
        }
        .onChange(of: targetElderly.id) { _, _ in
            centeredOnce = false
            centerOnHome()
        }
    }

    private func centerOnHome() {
        guard !centeredOnce else { return }
        centeredOnce = true
        cameraPosition = .region(MKCoordinateRegion(
            center: targetElderly.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        ))
    }

    // MARK: Kaart

    private var map: some View {
        Map(position: $cameraPosition) {
            // Eigen huis.
            Annotation(context == .elderly ? "Thuis" : targetElderly.firstName,
                       coordinate: targetElderly.coordinate) {
                homePin
            }
            // Teamgenoten: prominente druppels met foto, ring en hart (1A).
            ForEach(teamMatePins) { pin in
                Annotation(pin.firstName, coordinate: pin.coordinate) {
                    BCTeamMatePin(name: pin.firstName, buddyId: pin.id, hasAvatar: pin.hasAvatar)
                }
                .annotationTitles(.hidden)
            }
            // Losse buddies: kleinere zachtgroene druppels.
            ForEach(looseBuddyPins) { pin in
                Annotation(pin.firstName, coordinate: pin.coordinate) {
                    BCBuddyDropPin(name: pin.firstName, buddyId: pin.id, hasAvatar: pin.hasAvatar)
                }
                .annotationTitles(.hidden)
            }
            // Andere kringen in de buurt (benaderde plek): de app leeft.
            ForEach(otherTeams) { team in
                if let coord = team.approxCoordinate {
                    Annotation("Zorgkring", coordinate: coord) {
                        otherTeamPin
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapControlVisibility(.hidden)
        .ignoresSafeArea()
    }

    private var homePin: some View {
        ZStack {
            Circle().fill(BCColors.surface).frame(width: 34, height: 34)
                .overlay(Circle().stroke(BCColors.primary, lineWidth: 2))
                .bcSoftShadow(.raised)
            Image(systemName: "house.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BCColors.primary)
        }
    }

    /// Subtiel hartje voor een andere zorgkring in de buurt.
    private var otherTeamPin: some View {
        ZStack {
            Circle().fill(BCColors.primary.opacity(0.14)).frame(width: 26, height: 26)
            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(BCColors.primary.opacity(0.65))
        }
    }

    // MARK: Topbalk

    private var topBar: some View {
        HStack(spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                Text(greeting)
                    .font(BCFont.heading(15, .bold))
                    .foregroundStyle(BCColors.navy900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: BCSpacing.xs)
                let count = looseBuddyPins.count + teamMatePins.count
                BCStatusPill(label: count == 1 ? "1 buddy in de buurt" : "\(count) buddies in de buurt",
                             color: count == 0 ? BCColors.textTertiary : BCColors.success)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Capsule(style: .continuous).fill(BCColors.surface))
            .bcSoftShadow(.raised)

            inboxButton
        }
    }

    private var greeting: String {
        let name = context == .elderly ? appState.elderlyUser.firstName : appState.familyUser.firstName
        return name.isEmpty ? "Thuisverzorgd" : "Hallo \(name)"
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

    // MARK: Zorgkring-kaart (prominent, klikbaar)

    @ViewBuilder
    private var careTeamCard: some View {
        if let team = myTeam {
            teamCard(team)
        } else if context == .elderly && appState.elderlyTeamMode == "random_only" {
            noTeamCard(title: "U werkt met losse buddies",
                       subtitle: "Liever toch een vast team om u heen? Dat regelt u bij Buddies.",
                       buttonTitle: "Bekijk mijn buddies")
        } else {
            noTeamCard(title: context == .elderly ? "Nog geen zorgkring" : "Nog geen zorgkring voor \(targetElderly.firstName)",
                       subtitle: "Een vast team van buddies dat de bezoeken samen verdeelt.",
                       buttonTitle: "Start een team")
        }
    }

    private func noTeamCard(title: String, subtitle: String, buttonTitle: String) -> some View {
        Button {
            tabSelection = context.teamTab
        } label: {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(BCSpacing.md)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
    }

    private func teamCard(_ team: CareTeam) -> some View {
        let filled = team.scheduleFilled()
        return VStack(spacing: 0) {
            Button {
                tabSelection = context.teamTab
            } label: {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    HStack(spacing: BCSpacing.sm) {
                        Text(context == .elderly ? "Uw zorgkring" : "Zorgkring van \(team.elderlyName)")
                            .font(BCFont.heading(15, .bold))
                            .foregroundStyle(BCColors.navy900)
                        Spacer(minLength: 0)
                        if filled {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Rooster rond")
                                    .font(BCTypography.captionEmphasized)
                            }
                            .foregroundStyle(BCColors.accentDark)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(BCColors.accent.opacity(0.22)))
                        } else {
                            BCStatusPill(label: statusLabel(team), color: statusColor(team), showDot: true)
                        }
                    }

                    HStack(spacing: BCSpacing.sm) {
                        // Gezichten van het team.
                        HStack(spacing: -10) {
                            ForEach(Array(team.members.prefix(5).enumerated()), id: \.offset) { _, member in
                                TeamMemberFace(member: member, size: 36)
                                    .overlay(Circle().stroke(BCColors.surface, lineWidth: 2))
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(memberLine(team))
                                .font(et.caption)
                                .foregroundStyle(BCColors.textPrimary)
                                .lineLimit(1)
                            Text(nextVisitLine(team))
                                .font(et.caption)
                                .foregroundStyle(BCColors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BCColors.textTertiary)
                    }
                }
                .padding(BCSpacing.md)
            }
            .buttonStyle(.plain)

            if team.status == .live {
                Divider().padding(.horizontal, BCSpacing.md)
                HStack(spacing: 0) {
                    teamCardAction(icon: "calendar", label: "Rooster & team") {
                        tabSelection = context.teamTab
                    }
                    Divider().frame(height: 28)
                    teamCardAction(icon: "bubble.left.and.bubble.right.fill", label: "Berichten") {
                        showTeamChat = true
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .overlay(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .stroke(filled ? BCColors.accent : .clear, lineWidth: 2)
        )
        // De groene gloed: het rooster is helemaal ingevuld, het zit goed.
        .shadow(color: filled ? BCColors.accent.opacity(0.55) : BCColors.primaryDark.opacity(0.12),
                radius: filled ? 14 : 8, x: 0, y: filled ? 0 : 3)
        .animation(.easeInOut(duration: 0.4), value: filled)
    }

    private func teamCardAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(BCTypography.captionEmphasized)
            }
            .foregroundStyle(BCColors.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func statusLabel(_ team: CareTeam) -> String {
        switch team.status {
        case .forming: return "We zoeken buddies"
        case .review:  return "Wacht op akkoord"
        case .live:    return team.openVisits().isEmpty ? "Actief" : "\(team.openVisits().count) moment(en) open"
        case .paused:  return "Gepauzeerd"
        }
    }

    private func statusColor(_ team: CareTeam) -> Color {
        switch team.status {
        case .forming: return BCColors.warning
        case .review:  return BCColors.primary
        case .live:    return team.openVisits().isEmpty ? BCColors.success : BCColors.warning
        case .paused:  return BCColors.textTertiary
        }
    }

    private func memberLine(_ team: CareTeam) -> String {
        switch team.status {
        case .forming: return "\(team.memberCount) van minimaal \(team.minSize) buddies gevonden"
        case .review:  return "Beoordeel uw nieuwe team"
        default:       return team.memberCount == 1 ? "1 vaste buddy" : "\(team.memberCount) vaste buddies"
        }
    }

    private func nextVisitLine(_ team: CareTeam) -> String {
        guard team.status == .live else { return "Tik voor de status" }
        guard let next = team.schedule.first(where: { $0.date > Date() }) else {
            return "Nog geen bezoek ingepland"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEE d MMM HH:mm"
        let when = f.string(from: next.date).capitalized
        if let name = next.claimedByName {
            return "\(when) · \(name) komt langs"
        }
        return "\(when) · nog niemand ingepland"
    }

    // MARK: Hulp-knop + snelkoppelingen

    private var ctaRow: some View {
        Button {
            if hasOpenRequest {
                // Er loopt al een hulpvraag: toon die op de Hulp-pagina.
                tabSelection = 1
            } else {
                showRequestFlow = true
            }
        } label: {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: hasOpenRequest ? "hourglass" : "hand.raised.fill")
                    .font(.system(size: 19, weight: .bold))
                Text(hasOpenRequest ? "Bekijk uw lopende hulpvraag"
                     : (context == .elderly ? "Hulp vragen" : "Hulp aanvragen voor \(targetElderly.firstName)"))
                    .font(BCFont.heading(context == .elderly && largeText ? 20 : 17, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(BCColors.navy900)
            .frame(maxWidth: .infinity, minHeight: context == .elderly ? 58 : 52)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.accent)
            )
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
    }

    // MARK: SOS (alleen hulpvrager)

    private var sosFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    appState.showSOS = true
                } label: {
                    Text("SOS")
                        .font(BCFont.heading(17, .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(Circle().fill(BCColors.danger))
                        .bcSoftShadow(.raised)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("SOS, direct hulp")
            }
            .padding(.trailing, BCSpacing.md)
            .padding(.bottom, 190)
        }
    }
}

/// Gezicht van een teamlid: profielfoto (signed URL) of initiaal.
struct TeamMemberFace: View {
    let member: PoolMember
    var size: CGFloat = 36

    @ObservedObject private var photos = BuddyPhotoCache.shared
    @ObservedObject private var avatars = AvatarStore.shared

    var body: some View {
        Group {
            if member.isCurrentUser, let img = avatars.image {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let id = member.buddyId, let url = photos.url(for: id) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { initial }
                }
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            if let id = member.buddyId, !member.isCurrentUser { photos.ensure(id) }
        }
    }

    private var initial: some View {
        ZStack {
            Circle().fill(BCColors.primary.opacity(0.12))
            Text(String(member.name.prefix(1)).uppercased())
                .font(BCFont.heading(size * 0.42, .bold))
                .foregroundStyle(BCColors.primary)
        }
    }
}

#Preview {
    ElderlyMapHomeView().environment(AppState())
}
