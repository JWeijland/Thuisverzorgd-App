import SwiftUI

// ============================================================
// Zorgkring-views (fase35, zorgkring-pivot) — de zorgkring is hét team van
// de app: een vast groepje buddies rond 1 hulpvrager. Buddies maken zelf
// geen teams meer aan; een kring ontstaat rond een hulpvrager en je doet
// mee via een uitnodiging (ring-dispatch) of een join-verzoek.
// ============================================================

// MARK: - Sectie in de Teams-tab

struct CareTeamsSection: View {
    @Environment(AppState.self) private var appState
    /// Zoektekst uit de searchbar van de Teams-tab (leeg = alles tonen).
    var query: String = ""

    private var mine: [CareTeam] {
        filtered(appState.sortedCareTeams.filter { $0.isMyTeam })
    }
    /// Teams in de buurt: kringen waar je niet in zit én die nog plek hebben.
    private var nearby: [CareTeam] {
        filtered(appState.careTeams.filter { !$0.isMyTeam && $0.openSpots > 0 })
    }

    private func filtered(_ teams: [CareTeam]) -> [CareTeam] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return teams }
        return teams.filter {
            $0.name.lowercased().contains(q)
            || $0.elderlyName.lowercased().contains(q)
            || $0.area.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.lg) {
            infoCard

            if mine.isEmpty {
                emptyMine
            } else {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    SectionLabel("Mijn zorgkringen")
                    VStack(spacing: BCSpacing.sm) {
                        ForEach(mine) { team in
                            NavigationLink(value: team) { CareTeamCard(team: team) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !nearby.isEmpty {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    SectionLabel("Teams in de buurt")
                    VStack(spacing: BCSpacing.sm) {
                        ForEach(nearby) { team in
                            NearbyTeamCard(team: team)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.md)
        .padding(.bottom, BCSpacing.xxl)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                Text("Samen voor 1 hulpvrager zorgen")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
            }
            Text("In een zorgkring pak je met een paar vaste buddies samen de hulpvragen van 1 hulpvrager op. Je verdeelt de momenten via het inzetrooster en spaart samen punten voor een uitje.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(BCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }

    /// Geen eigen kring: uitleg zonder aanmaak-knop — een kring ontstaat rond
    /// een hulpvrager, joinen kan via een uitnodiging of een verzoek.
    private var emptyMine: some View {
        VStack(spacing: BCSpacing.md) {
            BCPillenPaar()
                .padding(.bottom, BCSpacing.xs)
            Text("Nog geen zorgkring")
                .font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            Text("Een zorgkring ontstaat rond een hulpvrager. Krijg je een uitnodiging, of staat er hieronder een team in de buurt? Doe dan mee!")
                .font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(BCSpacing.lg)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }
}

// MARK: - Kaart per eigen zorgkring

struct CareTeamCard: View {
    let team: CareTeam

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            ZStack {
                Circle().fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: "heart.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(team.name).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                Text("Voor \(team.elderlyName) · \(team.memberCount) buddies")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                if team.status != .live {
                    Text(team.status.label)
                        .font(BCTypography.caption).foregroundStyle(BCColors.warning)
                }
            }
            Spacer(minLength: 0)
            let open = team.openVisits().count
            if open > 0 {
                Text("\(open) vrij")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.warning)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(BCColors.warning.opacity(0.14)))
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.textTertiary)
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }
}

// MARK: - Kaart per team in de buurt (nog niet lid)

/// Privacy vóór toetreding: alleen voornaam, wijk/plaats en soort hulp —
/// bewust geen adres of foto. Joinen kan alleen via een verzoek; wie ooit
/// een uitnodiging afwees mag hier gewoon opnieuw verzoeken.
struct NearbyTeamCard: View {
    @Environment(AppState.self) private var appState
    let team: CareTeam

    /// Loopt er al een verzoek voor deze kring?
    private var requestPending: Bool {
        team.pendingJoin || appState.careJoinRequests.contains {
            $0.careTeamId == team.id && $0.status == "pending"
        }
    }

    private var spotsLabel: String {
        team.openSpots == 1 ? "nog 1 plek" : "nog \(team.openSpots) plekken"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Zorgkring van \(team.elderlyName)")
                        .font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                    Text(team.area.isEmpty ? "In jouw buurt" : team.area)
                        .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                }
                Spacer(minLength: 0)
                Text(spotsLabel)
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.accentDark)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(BCColors.accent.opacity(0.25)))
            }
            if !team.helpSummary.isEmpty {
                Text(team.helpSummary)
                    .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if requestPending {
                Label("Verzoek gestuurd, \(team.elderlyName) beslist", systemImage: "paperplane.fill")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.success)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                        .fill(BCColors.success.opacity(0.10)))
            } else {
                Button {
                    appState.requestJoinCareTeam(team)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus").font(.system(size: 14, weight: .semibold))
                        Text("Verzoek om mee te doen").font(BCTypography.captionEmphasized)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundStyle(.white)
                    .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.primary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }
}

// MARK: - Detail: status, leden, punten + inzetrooster

struct CareTeamDetailView: View {
    @Environment(AppState.self) private var appState
    let teamId: UUID

    /// Teamchat (fase36): welk kanaal openen we?
    @State private var chatChannel: TeamChatChannel? = nil
    /// Vervanging vragen: bevestiging voor dit moment.
    @State private var visitForSwap: CareVisit? = nil

    /// Actuele versie uit appState (zodat claims meteen zichtbaar zijn).
    private var team: CareTeam? { appState.careTeams.first { $0.id == teamId } }

    /// Eigen buddy-id (live: ingelogde gebruiker, demo: mock-buddy).
    private var myBuddyId: UUID { appState.realUserId ?? appState.buddyUser.id }

    var body: some View {
        ScrollView {
            if let team {
                VStack(alignment: .leading, spacing: BCSpacing.xl) {
                    header(team)
                    if team.isMyTeam {
                        chatSection(team)
                        pointsCard(team)
                    }
                    rulesInfo
                    scheduleSection(team)
                    if !team.isMyTeam {
                        joinSection(team)
                    }
                }
                .padding(.horizontal, BCSpacing.lg).padding(.top, BCSpacing.md).padding(.bottom, BCSpacing.xxl)
            } else {
                Text("Team niet gevonden").font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
                    .padding(.top, BCSpacing.xxl)
            }
        }
        .background(BCColors.background)
        .navigationTitle(team?.name ?? "Zorgkring")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chatChannel) { channel in
            if let team {
                TeamChatView(teamId: team.id, teamName: team.name,
                             channels: [.all, .buddies], initialChannel: channel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Vervanging vragen voor dit moment?",
               isPresented: Binding(get: { visitForSwap != nil },
                                    set: { if !$0 { visitForSwap = nil } }),
               presenting: visitForSwap) { visit in
            Button("Ja, vraag vervanging") {
                if let team { appState.requestVisitSwap(teamId: team.id, visitId: visit.id) }
                visitForSwap = nil
            }
            Button("Nee, ik doe het zelf", role: .cancel) { visitForSwap = nil }
        } message: { visit in
            Text("Het hele team (ook \(team?.elderlyName ?? "de hulpvrager") en familie) krijgt bericht dat \(visit.category.displayName.lowercased()) op \(visit.date.formatted(date: .abbreviated, time: .shortened)) een nieuwe buddy zoekt.")
        }
    }

    private func statusColor(_ status: CareTeamStatus) -> Color {
        switch status {
        case .forming: return BCColors.warning
        case .review:  return BCColors.primary
        case .live:    return BCColors.success
        case .paused:  return BCColors.textTertiary
        }
    }

    private func header(_ team: CareTeam) -> some View {
        let filled = team.scheduleFilled()
        return VStack(spacing: BCSpacing.md) {
            ZStack {
                // Groene gloed zodra het rooster helemaal is ingevuld (fase36).
                if filled {
                    Circle()
                        .fill(BCColors.accent.opacity(0.35))
                        .frame(width: 96, height: 96)
                        .blur(radius: 10)
                }
                Circle().fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 76, height: 76)
                    .overlay(Circle().stroke(filled ? BCColors.accent : .clear, lineWidth: 3))
                Image(systemName: "heart.fill").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
            }
            Text("Zorgkring van \(team.elderlyName)")
                .font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
            if filled {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Rooster helemaal rond")
                        .font(BCTypography.captionEmphasized)
                }
                .foregroundStyle(BCColors.accentDark)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(BCColors.accent.opacity(0.22)))
            } else {
                BCStatusPill(label: team.status.label, color: statusColor(team.status), showDot: true)
            }
            // Buddies in de kring — met profielfoto waar die er is.
            HStack(spacing: -8) {
                ForEach(Array(team.members.prefix(6).enumerated()), id: \.offset) { _, m in
                    TeamMemberFace(member: m, size: 34)
                        .overlay(Circle().stroke(BCColors.background, lineWidth: 2))
                }
                Text("\(team.memberCount) buddies")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                    .padding(.leading, 14)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Fase36: twee duidelijk gescheiden teamchats voor teamleden.
    private func chatSection(_ team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Berichten").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            HStack(spacing: BCSpacing.sm) {
                chatButton(channel: .all,
                           title: "Teamchat",
                           subtitle: "Met \(team.elderlyName) & familie")
                chatButton(channel: .buddies,
                           title: "Buddy-chat",
                           subtitle: "Alleen vrijwilligers")
            }
        }
    }

    private func chatButton(channel: TeamChatChannel, title: String, subtitle: String) -> some View {
        Button {
            chatChannel = channel
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: channel.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(channel == .buddies ? BCColors.accentDark : BCColors.primary)
                Text(title)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(subtitle)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BCSpacing.md)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .stroke(channel == .buddies ? BCColors.accent.opacity(0.5) : BCColors.border, lineWidth: 1))
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }

    /// Gamification: de zorgkring is nu ook het punten-team. Samen sparen
    /// jullie naar het uitjes-doel.
    private func pointsCard(_ team: CareTeam) -> some View {
        let fraction = min(1, Double(team.totalPoints) / Double(max(1, team.outingTarget)))
        return VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack {
                Label("Teampunten", systemImage: "star.fill")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textSecondary)
                Spacer()
                Text("\(team.totalPoints) / \(team.outingTarget)")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BCColors.surfaceMuted)
                    Capsule()
                        .fill(LinearGradient(colors: team.tint, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geo.size.width * fraction))
                }
            }
            .frame(height: 10)
            Text("Samen sparen jullie voor een uitje: elk bezoek telt mee.")
                .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }

    private var rulesInfo: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            ruleRow(icon: "clock.badge.exclamationmark", text: "Blijft een moment vrij, dan krijgt het team 48 en 24 uur vooraf een herinnering.")
            ruleRow(icon: "bolt.fill", text: "Een half uur vooraf nog niemand? Dan mogen ook buddies buiten het team bijspringen.")
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surfaceMuted))
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(BCColors.primary).frame(width: 22)
            Text(text).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func scheduleSection(_ team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Inzetrooster").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            if team.schedule.isEmpty {
                Text("Nog geen ingeplande momenten. Zodra \(team.elderlyName) hulp inplant, verschijnt het hier.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: BCSpacing.sm) {
                    ForEach(team.schedule) { visit in
                        CareVisitRow(visit: visit, isMember: team.isMyTeam,
                                     currentBuddyId: myBuddyId,
                                     onClaim: {
                                         appState.claimCareVisit(teamId: team.id, visitId: visit.id)
                                     },
                                     onRequestSwap: { visitForSwap = visit },
                                     onWithdrawSwap: {
                                         appState.withdrawVisitSwap(teamId: team.id, visitId: visit.id)
                                     },
                                     onTakeOver: {
                                         appState.takeOverVisit(teamId: team.id, visitId: visit.id)
                                     })
                    }
                }
            }
        }
    }

    /// Geen lid: join-verzoek sturen (vervangt de oude join-knop). Ook wie ooit
    /// een uitnodiging afwees mag hier gewoon opnieuw verzoeken.
    @ViewBuilder
    private func joinSection(_ team: CareTeam) -> some View {
        let pending = team.pendingJoin || appState.careJoinRequests.contains {
            $0.careTeamId == team.id && $0.status == "pending"
        }
        if pending {
            Label("Verzoek gestuurd, \(team.elderlyName) beslist", systemImage: "paperplane.fill")
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.success)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.success.opacity(0.10)))
        } else if team.openSpots > 0 {
            BCPrimaryButton(title: "Verzoek om mee te doen", icon: "person.badge.plus") {
                appState.requestJoinCareTeam(team)
            }
        } else {
            Text("Dit team zit op dit moment vol.")
                .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Rij per moment in het rooster

struct CareVisitRow: View {
    let visit: CareVisit
    /// Zit de kijker in deze zorgkring? Leden mogen altijd claimen; bij een
    /// urgent moment (30 min vooraf) mag iedereen bijspringen.
    let isMember: Bool
    /// Eigen buddy-id: nodig om "opgepakt door jou" en de vervangingsknoppen
    /// (fase36) te tonen. nil = kijker zonder rooster-acties.
    var currentBuddyId: UUID? = nil
    let onClaim: () -> Void
    /// Fase36 — vervanging: vragen (eigen moment), intrekken en overnemen.
    var onRequestSwap: (() -> Void)? = nil
    var onWithdrawSwap: (() -> Void)? = nil
    var onTakeOver: (() -> Void)? = nil

    private var status: CareVisitStatus { visit.status() }
    private var isMine: Bool {
        currentBuddyId != nil && visit.claimedByBuddyId == currentBuddyId
    }

    private var statusPill: (label: String, color: Color) {
        if status == .claimed && visit.swapRequested {
            return ("Zoekt vervanging", BCColors.warning)
        }
        return (status.label, status.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: visit.category.icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(visit.category.displayName).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                    Text(dateLabel(visit.date)).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                }
                Spacer(minLength: 0)
                BCStatusPill(label: statusPill.label, color: statusPill.color, showDot: true)
            }
            if !visit.note.isEmpty {
                Text(visit.note).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            switch status {
            case .open:
                if isMember {
                    Button(action: onClaim) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.fill").font(.system(size: 14, weight: .semibold))
                            Text("Ik pak dit op").font(BCTypography.captionEmphasized)
                        }
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.primary))
                    }
                    .buttonStyle(.plain)
                }
            case .urgent:
                // Spoed: ook buddies buiten het team mogen dit moment oppakken.
                Button(action: onClaim) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold))
                        Text("Spring bij").font(BCTypography.captionEmphasized)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(.white)
                    .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(status.color))
                }
                .buttonStyle(.plain)
            case .claimed:
                claimedFooter
            }
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }

    /// Fase36: bij een geclaimd moment horen de vervangingsacties.
    @ViewBuilder
    private var claimedFooter: some View {
        if isMine {
            if visit.swapRequested {
                Label("Je zoekt vervanging voor dit moment", systemImage: "arrow.triangle.2.circlepath")
                    .font(BCTypography.caption).foregroundStyle(BCColors.warning)
                if let onWithdrawSwap {
                    Button(action: onWithdrawSwap) {
                        Text("Ik doe het toch zelf")
                            .font(BCTypography.captionEmphasized)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundStyle(BCColors.primary)
                            .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                                .fill(BCColors.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Label("Opgepakt door jou", systemImage: "checkmark.circle.fill")
                    .font(BCTypography.caption).foregroundStyle(BCColors.success)
                if let onRequestSwap {
                    Button(action: onRequestSwap) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Vraag vervanging").font(BCTypography.captionEmphasized)
                        }
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(BCColors.primary)
                        .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                            .fill(BCColors.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if visit.swapRequested {
            Label("\(visit.claimedByName ?? "Een teamlid") zoekt vervanging\(visit.swapReason.isEmpty ? "" : ": \(visit.swapReason)")",
                  systemImage: "arrow.triangle.2.circlepath")
                .font(BCTypography.caption).foregroundStyle(BCColors.warning)
                .fixedSize(horizontal: false, vertical: true)
            if isMember, let onTakeOver {
                Button(action: onTakeOver) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill").font(.system(size: 14, weight: .semibold))
                        Text("Ik neem het over").font(BCTypography.captionEmphasized)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundStyle(BCColors.navy900)
                    .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.accent))
                }
                .buttonStyle(.plain)
            }
        } else {
            Label("Opgepakt door \(visit.claimedByName ?? "een teamlid")", systemImage: "checkmark.circle.fill")
                .font(BCTypography.caption).foregroundStyle(BCColors.success)
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE d MMM 'om' HH:mm"
        return f.string(from: date).capitalized
    }
}

// MARK: - Uitnodigingskaart (ring-dispatch)

/// "«Naam» zoekt een team aan buddies" — de in-app kaart bij de pushmelding.
/// Privacy vóór toetreding: alleen voornaam, wijk/plaats en soort hulp;
/// bewust géén adres of foto.
struct TeamInviteSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let invite: TeamInvite

    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.lg) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 76, height: 76)
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 30, weight: .semibold)).foregroundStyle(BCColors.primary)
                }
                .padding(.top, BCSpacing.lg)

                VStack(spacing: BCSpacing.xs) {
                    Text("\(invite.elderlyName) zoekt een team aan buddies")
                        .font(BCTypography.title3).foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Doe jij mee? Samen met een paar vaste buddies help je \(invite.elderlyName) door de week heen.")
                        .font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if invite.isFavorite {
                    // Conversie-flow: deze buddy was al vaste buddy (hart).
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(BCColors.danger)
                        Text("Jij bent al vaste buddy van \(invite.elderlyName)")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                    .padding(.horizontal, BCSpacing.md).padding(.vertical, 8)
                    .background(Capsule(style: .continuous).fill(BCColors.danger.opacity(0.10)))
                }

                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    infoRow(icon: "mappin.and.ellipse", label: "Buurt",
                            value: invite.area.isEmpty ? "In jouw buurt" : invite.area)
                    infoRow(icon: "hands.sparkles.fill", label: "Soort hulp",
                            value: invite.helpSummary.isEmpty ? "Hoor je na je aanmelding" : invite.helpSummary)
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .bcSoftShadow(.card)

                HStack(alignment: .top, spacing: BCSpacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.textTertiary)
                    Text("Uit privacy zie je nu alleen de voornaam en de buurt. Het adres en de details krijg je zodra je in het team zit en \(invite.elderlyName) het team heeft bevestigd.")
                        .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: BCSpacing.sm) {
                    BCPrimaryButton(title: "Ik doe mee", icon: "heart.fill") {
                        appState.acceptTeamInvite(invite)
                        dismiss()
                    }
                    Button {
                        appState.declineTeamInvite(invite)
                        dismiss()
                    } label: {
                        Text("Nu even niet")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(BCColors.primary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                Text(value).font(BCTypography.subheadline).foregroundStyle(BCColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Invaller → teamlid (fase35 §4.1)

/// Voorstel na een afgeronde hulpvraag: word vast teamlid van de zorgkring
/// van deze hulpvrager. De hulpvrager beslist over het verzoek.
struct TeamProposalSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let team: CareTeam

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle().fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.fill").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
            }
            .padding(.top, BCSpacing.lg)

            VStack(spacing: BCSpacing.xs) {
                Text("Beviel het bij \(team.elderlyName)?")
                    .font(BCTypography.title3).foregroundStyle(BCColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Word vast teamlid van de zorgkring van \(team.elderlyName). Dan help je vaker en verdeel je de momenten samen met het team.")
                    .font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: BCSpacing.sm) {
                BCPrimaryButton(title: "Stuur verzoek", icon: "paperplane.fill") {
                    appState.requestJoinCareTeam(team, source: "fallback")
                    appState.pendingTeamProposal = nil
                    dismiss()
                }
                Button {
                    appState.pendingTeamProposal = nil
                    dismiss()
                } label: {
                    Text("Nee, bedankt")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(BCSpacing.lg)
        .background(BCColors.background)
    }
}
