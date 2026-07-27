import SwiftUI

struct FamilyDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showRequestFlow = false
    @State private var showEditProfile = false
    @State private var showRecentVisits = false
    @Binding var showLinking: Bool

    // Zorgkring-beheer (spec §5: familie mag alles meebeheren)
    @State private var showStartTeamSheet = false
    // Teamchat (fase36): het gezamenlijke kanaal met de vrijwilligers.
    @State private var showTeamChat = false
    @State private var memberToDecline: PoolMember? = nil   // review: "Liever niet"
    @State private var memberToRemove: PoolMember? = nil    // live: verwijderen
    @State private var visitToCancel: CareVisit? = nil      // rooster: schrappen
    @State private var approvedMemberIds: Set<UUID> = []    // review: al "Prima" getikt

    init(showLinking: Binding<Bool> = .constant(false)) {
        _showLinking = showLinking
    }

    // Cijfers afgeleid uit de bezoeken van de oudere die je nu beheert,
    // zodat wisselen van naaste zichtbaar andere data toont.
    private var elderlyVisits: [ServiceTask] {
        appState.taskHistory.filter { $0.elderlyName == appState.activeFamilyElderly.firstName }
    }
    private var satisfactionText: String {
        let ratings = elderlyVisits.compactMap { $0.assignedBuddyRating }
        guard !ratings.isEmpty else { return "—" }
        let avg = ratings.reduce(0, +) / Double(ratings.count)
        return String(format: "%.1f", avg).replacingOccurrences(of: ".", with: ",")
    }
    private var regularBuddyCount: Int {
        Set(elderlyVisits.compactMap { $0.assignedBuddyName }).count
    }
    /// "78 jaar · adres" — toont de leeftijd alleen als die echt bekend is.
    private var familySubtitle: String {
        let e = appState.activeFamilyElderly
        var parts: [String] = []
        if let age = e.displayAge { parts.append("\(age) jaar") }
        let address = e.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.isEmpty { parts.append(address) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if appState.familyLinkedElderly.isEmpty {
                noLinksState
            } else {
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    // Beheer-switcher: wíé je beheert — altijd bovenaan
                    elderlySwitcher
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.md)

                    // Naaste-card
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.md) {
                            HStack(spacing: BCSpacing.md) {
                                ZStack {
                                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 56, height: 56)
                                    Text(String(appState.activeFamilyElderly.firstName.prefix(1)))
                                        .font(BCTypography.title3)
                                        .foregroundStyle(BCColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.activeFamilyElderly.fullName)
                                        .font(BCTypography.headline)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text(familySubtitle)
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    showEditProfile = true
                                } label: {
                                    Label("Aanpassen", systemImage: "pencil")
                                        .font(BCTypography.captionEmphasized)
                                        .foregroundStyle(BCColors.primary)
                                        .padding(.horizontal, BCSpacing.sm)
                                        .padding(.vertical, BCSpacing.xs)
                                        .background(Capsule().fill(BCColors.primary.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                            Divider()
                            HStack(spacing: BCSpacing.md) {
                                StatPill(icon: "house.fill", value: "\(elderlyVisits.count)", label: "Bezoeken", color: BCColors.primary)
                                StatPill(icon: "star.fill", value: satisfactionText, label: "Tevreden", color: BCColors.success)
                                StatPill(icon: "person.2.fill", value: "\(regularBuddyCount)", label: "Vaste buddies", color: BCColors.navy500)
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Zorgkring: het vaste team rond de naaste beheren
                    careTeamSection

                    // Groene hulp-hero
                    BCHelpHeroCard(
                        eyebrow: "VOOR \(appState.activeFamilyElderly.firstName.uppercased())",
                        title: "Hulp aanvragen",
                        subtitle: "Plan een vertrouwde buddy in voor \(appState.activeFamilyElderly.firstName).",
                        icon: "hand.raised.fill"
                    ) {
                        showRequestFlow = true
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Nudge: bezoek wacht op beoordeling
                    if appState.familyHasUnreviewedVisits {
                        Button { showRecentVisits = true } label: {
                            HStack(spacing: BCSpacing.md) {
                                ZStack {
                                    Circle().fill(BCColors.warning.opacity(0.14)).frame(width: 40, height: 40)
                                    Image(systemName: "star.bubble.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(BCColors.warning)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bezoek wacht op beoordeling")
                                        .font(BCTypography.bodyEmphasized)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text("\(appState.activeFamilyElderly.firstName) heeft nog niet beoordeeld, wil jij het doen?")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer(minLength: BCSpacing.sm)
                                Circle()
                                    .fill(BCColors.danger)
                                    .frame(width: 10, height: 10)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                            .padding(BCSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                    .fill(BCColors.surface)
                            )
                            .bcSoftShadow(.card)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    // Snel regelen
                    BCSectionHeader(title: "Snel regelen")
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.top, BCSpacing.xs)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: BCSpacing.sm),
                                  GridItem(.flexible(), spacing: BCSpacing.sm)],
                        spacing: BCSpacing.sm
                    ) {
                        ZStack(alignment: .topTrailing) {
                            BCQuickTile(
                                title: "Recente bezoeken",
                                subtitle: "Wat is er gebeurd",
                                icon: "list.bullet.rectangle",
                                color: BCColors.accentDark
                            ) {
                                showRecentVisits = true
                            }
                            if appState.familyHasUnreviewedVisits {
                                Circle()
                                    .fill(BCColors.danger)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(BCColors.surface, lineWidth: 2))
                                    .padding(12)
                            }
                        }
                        BCQuickTile(
                            title: "Oudere koppelen",
                            subtitle: "Voeg een naaste toe",
                            icon: "person.badge.plus",
                            color: BCColors.navy500
                        ) {
                            showLinking = true
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showRequestFlow) {
            RequestHelpFlow(onBehalfOf: appState.activeFamilyElderly)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(editingFamilyElderly: true)
        }
        .sheet(isPresented: $showRecentVisits) {
            FamilyVisitsSheet()
        }
        .sheet(isPresented: $showStartTeamSheet) {
            StartCareTeamSheet(elderly: appState.activeFamilyElderly)
        }
        .sheet(isPresented: $showTeamChat) {
            if let team = appState.careTeam(for: appState.activeFamilyElderly) {
                TeamChatView(teamId: team.id, teamName: team.name, channels: [.all])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        // Review: bevestigen vóór je een buddy weigert
        .alert(
            "Liever niet met \(memberToDecline?.name ?? "deze buddy")?",
            isPresented: Binding(
                get: { memberToDecline != nil },
                set: { if !$0 { memberToDecline = nil } }
            )
        ) {
            Button("Liever niet", role: .destructive) {
                if let member = memberToDecline, let buddyId = member.buddyId,
                   let team = appState.careTeam(for: appState.activeFamilyElderly) {
                    appState.reviewTeamMember(teamId: team.id, buddyId: buddyId, accept: false)
                }
                memberToDecline = nil
            }
            Button("Annuleer", role: .cancel) { memberToDecline = nil }
        } message: {
            Text("Deze buddy wordt uit de zorgkring gehaald en krijgt daar netjes bericht van. Als het team daardoor te klein wordt, zoeken we door.")
        }
        // Live: bevestigen vóór je een teamlid verwijdert
        .alert(
            "\(memberToRemove?.name ?? "Dit teamlid") uit de zorgkring halen?",
            isPresented: Binding(
                get: { memberToRemove != nil },
                set: { if !$0 { memberToRemove = nil } }
            )
        ) {
            Button("Verwijderen", role: .destructive) {
                if let member = memberToRemove, let buddyId = member.buddyId,
                   let team = appState.careTeam(for: appState.activeFamilyElderly) {
                    appState.removeCareTeamMember(teamId: team.id, buddyId: buddyId)
                }
                memberToRemove = nil
            }
            Button("Annuleer", role: .cancel) { memberToRemove = nil }
        } message: {
            Text("Deze buddy helpt \(appState.activeFamilyElderly.firstName) dan niet meer en krijgt daar bericht van.")
        }
        // Rooster: bevestigen vóór je een moment schrapt
        .alert(
            "Dit moment schrappen?",
            isPresented: Binding(
                get: { visitToCancel != nil },
                set: { if !$0 { visitToCancel = nil } }
            )
        ) {
            Button("Schrappen", role: .destructive) {
                if let visit = visitToCancel,
                   let team = appState.careTeam(for: appState.activeFamilyElderly) {
                    appState.cancelCareVisit(teamId: team.id, visitId: visit.id)
                }
                visitToCancel = nil
            }
            Button("Annuleer", role: .cancel) { visitToCancel = nil }
        } message: {
            Text("Het moment verdwijnt uit het inzetrooster van de zorgkring.")
        }
        .task {
            // Live: zorgkring en join-verzoeken vers ophalen
            await appState.loadCareTeams()
            await appState.loadCareJoinRequests()
        }
    }

    // MARK: - Lege staat (nog geen oudere gekoppeld)

    private var noLinksState: some View {
        ScrollView {
            VStack(spacing: BCSpacing.lg) {
                // De losse pillen die elkaar zoeken: vriendelijke illustratie
                // voor de lege staat (Brand Guidelines 5.2), geen somber icoon.
                BCPillenPaar()
                    .padding(.top, BCSpacing.md)
                VStack(spacing: BCSpacing.sm) {
                    Text("Koppel uw eerste naaste")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Vraag uw naaste om hun persoonlijke koppelcode (te vinden op hun profiel) en voer die hier in. Daarna kunt u meekijken en hulp regelen.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                BCPrimaryButton(title: "Koppelcode invoeren", icon: "link") {
                    showLinking = true
                }
            }
            .padding(BCSpacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Navy header

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            HStack(alignment: .center, spacing: BCSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Familie-overzicht")
                        .font(BCTypography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    BCHeroKop(
                        text: "Hallo \(appState.familyUser.firstName)",
                        font: BCTypography.titleEmphasized,
                        color: .white
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.16))
                    Text(String(appState.familyUser.firstName.prefix(1)))
                        .font(BCTypography.title3)
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .frame(height: 64)
    }

    // MARK: - Beheer-switcher

    private var elderlySwitcher: some View {
        Menu {
            ForEach(Array(appState.familyLinkedElderly.enumerated()), id: \.element.id) { index, elderly in
                Button {
                    appState.activeFamilyElderlyIndex = index
                } label: {
                    if index == appState.activeFamilyElderlyIndex {
                        Label(elderly.fullName, systemImage: "checkmark")
                    } else {
                        Text(elderly.fullName)
                    }
                }
            }
        } label: {
            HStack(spacing: BCSpacing.sm) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("U beheert")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                    Text(appState.activeFamilyElderly.firstName)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                }
                Spacer()
                if appState.familyLinkedElderly.count > 1 {
                    HStack(spacing: BCSpacing.xs) {
                        Text("Wissel")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                    }
                }
            }
            .padding(.vertical, BCSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BCColors.border)
                    .frame(height: 1)
            }
        }
        .disabled(appState.familyLinkedElderly.count <= 1)
    }

    // MARK: - Zorgkring (teamvorming + beheer, spec §5)

    /// Sectie "Zorgkring van «voornaam»": per teamstatus een andere kaart.
    @ViewBuilder
    private var careTeamSection: some View {
        let elderly = appState.activeFamilyElderly

        BCSectionHeader(title: "Zorgkring van \(elderly.firstName)")
            .padding(.horizontal, BCSpacing.lg)
            .padding(.top, BCSpacing.xs)

        Group {
            if let team = appState.careTeam(for: elderly) {
                switch team.status {
                case .forming:        formingCard(team: team)
                case .review:         reviewCard(team: team)
                case .live, .paused:  liveCard(team: team)
                }
            } else {
                noTeamCard(elderly: elderly)
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    /// Nog geen zorgkring: uitleg + startknop.
    private func noTeamCard(elderly: ElderlyUser) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nog geen zorgkring")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Een vast team van buddies rond \(elderly.firstName)")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
                Text("Met een zorgkring staat een vast groepje buddies uit de buurt klaar voor \(elderly.firstName). Zij verdelen de bezoeken onderling, zodat er altijd een vertrouwd gezicht komt.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                BCPrimaryButton(title: "Start een zorgkring", icon: "person.2.wave.2.fill",
                                cornerRadius: BCRadius.md, height: 52) {
                    showStartTeamSheet = true
                }
            }
        }
    }

    /// Werving loopt: voortgang richting het minimum.
    private func formingCard(team: CareTeam) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Text("\(team.memberCount) van minimaal \(team.minSize) buddies gevonden")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    BCStatusPill(label: team.status.label, color: BCColors.warning, showDot: true)
                }
                BCProgressBar(value: Double(team.memberCount) / Double(max(1, team.minSize)),
                              color: BCColors.primary)
                Text("We zoeken door en nodigen buddies in de buurt uit. Je krijgt bericht zodra het team compleet genoeg is om te beoordelen.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Review: buddies goed- of afkeuren en het team bevestigen.
    private func reviewCard(team: CareTeam) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Text("Beoordeel het team")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    BCStatusPill(label: team.status.label, color: BCColors.warning, showDot: true)
                }
                Text("Deze buddies willen bij de zorgkring van \(team.elderlyName). Kijk ze even na; weiger je iemand, dan zoeken we een vervanger.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(Array(team.members.enumerated()), id: \.element.id) { index, member in
                        reviewMemberRow(member: member)
                        if index < team.members.count - 1 {
                            Divider()
                        }
                    }
                }

                if team.openSpots > 0 {
                    // 1-uur-keuzeblok (spec §1.3): team is nog niet vol —
                    // aanvullen met de buurt, of alleen met deze buddies verder.
                    Divider()
                    Text("Het team is nog niet vol. Hoe wil je verder?")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    BCPrimaryButton(title: "Vul aan met buddies uit de buurt", icon: "person.3.fill",
                                    cornerRadius: BCRadius.md, height: 52) {
                        appState.setTeamFallback(teamId: team.id, allowed: true)
                        appState.finalizeTeamReview(teamId: team.id)
                    }
                    BCSecondaryButton(title: "Alleen deze buddies") {
                        appState.setTeamFallback(teamId: team.id, allowed: false)
                        appState.finalizeTeamReview(teamId: team.id)
                    }
                } else {
                    BCPrimaryButton(title: "Bevestig het team", icon: "checkmark.circle.fill",
                                    cornerRadius: BCRadius.md, height: 52) {
                        appState.finalizeTeamReview(teamId: team.id)
                    }
                }
            }
        }
    }

    /// Eén buddy in de reviewlijst: Prima / Liever niet.
    private func reviewMemberRow(member: PoolMember) -> some View {
        HStack(spacing: BCSpacing.md) {
            memberAvatar(name: member.name)
            Text(member.name)
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            if let buddyId = member.buddyId, approvedMemberIds.contains(buddyId) {
                Label("Prima", systemImage: "checkmark")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.success)
            } else {
                Button {
                    if let buddyId = member.buddyId,
                       let team = appState.careTeam(for: appState.activeFamilyElderly) {
                        appState.reviewTeamMember(teamId: team.id, buddyId: buddyId, accept: true)
                        approvedMemberIds.insert(buddyId)
                    }
                } label: {
                    Text("Prima")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.success)
                        .padding(.horizontal, BCSpacing.sm)
                        .padding(.vertical, BCSpacing.xs)
                        .background(Capsule().fill(BCColors.success.opacity(0.10)))
                }
                .buttonStyle(.plain)
                Button {
                    memberToDecline = member
                } label: {
                    Text("Liever niet")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.danger)
                        .padding(.horizontal, BCSpacing.sm)
                        .padding(.vertical, BCSpacing.xs)
                        .background(Capsule().fill(BCColors.danger.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, BCSpacing.sm)
    }

    /// Actieve zorgkring: leden, inzetrooster en join-verzoeken.
    private func liveCard(team: CareTeam) -> some View {
        let pendingRequests = appState.careJoinRequests.filter {
            $0.status == "pending" && $0.careTeamId == team.id
        }
        // Fase36: groene gloed zodra het hele rooster is ingevuld.
        let filled = team.scheduleFilled()
        return BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    Text(team.name)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    if filled {
                        BCStatusPill(label: "Rooster rond", color: BCColors.accentDark, showDot: true)
                    } else {
                        BCStatusPill(label: team.status.label,
                                     color: team.status == .live ? BCColors.success : BCColors.warning,
                                     showDot: true)
                    }
                }

                // Teamchat (fase36): overleg samen met de vrijwilligers.
                Button {
                    showTeamChat = true
                } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Berichten met het team")
                            .font(BCTypography.bodyEmphasized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .foregroundStyle(BCColors.primary)
                    .padding(BCSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)

                // Ledenlijst met verwijder-optie (fase36: met profielfoto)
                VStack(spacing: 0) {
                    ForEach(Array(team.members.enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: BCSpacing.md) {
                            TeamMemberFace(member: member, size: 40)
                            Text(member.name)
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            Spacer()
                            Button {
                                memberToRemove = member
                            } label: {
                                Image(systemName: "person.badge.minus")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(BCColors.danger)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(BCColors.danger.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(member.name) uit de zorgkring halen")
                        }
                        .padding(.vertical, BCSpacing.sm)
                        if index < team.members.count - 1 {
                            Divider()
                        }
                    }
                }
                if team.openSpots > 0 {
                    Text("Nog \(team.openSpots == 1 ? "1 plek" : "\(team.openSpots) plekken") vrij in de kring.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }

                // Inzetrooster: wie komt wanneer
                Divider()
                Text("Inzetrooster")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                if team.schedule.isEmpty {
                    Text("Nog geen momenten in het rooster. Vraag hulp aan om iets in te plannen.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(team.schedule.enumerated()), id: \.element.id) { index, visit in
                            visitRow(visit: visit)
                            if index < team.schedule.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                // Join-verzoeken: buddies die erbij willen
                if !pendingRequests.isEmpty {
                    Divider()
                    Text("Wil erbij")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    VStack(spacing: 0) {
                        ForEach(Array(pendingRequests.enumerated()), id: \.element.id) { index, request in
                            joinRequestRow(request: request)
                            if index < pendingRequests.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .stroke(filled ? BCColors.accent : .clear, lineWidth: 2)
        )
        .shadow(color: filled ? BCColors.accent.opacity(0.5) : .clear,
                radius: 12, x: 0, y: 2)
    }

    /// Eén moment uit het inzetrooster, met status en schrap-optie.
    private func visitRow(visit: CareVisit) -> some View {
        let status = visit.status()
        // Fase36: geclaimd moment waarvoor de buddy vervanging zoekt.
        let seeksSwap = status == .claimed && visit.swapRequested
        return HStack(spacing: BCSpacing.md) {
            AppIcon(name: visit.category.brandIcon, size: 20)
                .frame(width: 36, height: 36)
                .background(Circle().fill(BCColors.primary.opacity(0.10)))
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.category.displayName)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(visit.date.formatted(date: .abbreviated, time: .shortened))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                HStack(spacing: 4) {
                    Image(systemName: seeksSwap ? "arrow.triangle.2.circlepath" : status.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(seeksSwap ? "\(visit.claimedByName ?? "Een teamlid") zoekt vervanging"
                         : status == .claimed ? "\(visit.claimedByName ?? "Een teamlid") komt" : status.label)
                        .font(BCTypography.caption)
                }
                .foregroundStyle(seeksSwap ? BCColors.warning : status.color)
            }
            Spacer()
            if status != .claimed {
                Button {
                    visitToCancel = visit
                } label: {
                    Text("Schrappen")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.danger)
                        .padding(.horizontal, BCSpacing.sm)
                        .padding(.vertical, BCSpacing.xs)
                        .background(Capsule().fill(BCColors.danger.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, BCSpacing.sm)
    }

    /// Eén join-verzoek: accepteren of afwijzen.
    private func joinRequestRow(request: CareJoinRequest) -> some View {
        HStack(spacing: BCSpacing.md) {
            memberAvatar(name: request.buddyName)
            VStack(alignment: .leading, spacing: 2) {
                Text(request.buddyName)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(request.source == "fallback" ? "Sprong eerder in als invaller" : "Wil bij de zorgkring")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
            Spacer()
            Button {
                appState.respondCareJoinRequest(request, approve: true)
            } label: {
                Text("Accepteren")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.success)
                    .padding(.horizontal, BCSpacing.sm)
                    .padding(.vertical, BCSpacing.xs)
                    .background(Capsule().fill(BCColors.success.opacity(0.10)))
            }
            .buttonStyle(.plain)
            Button {
                appState.respondCareJoinRequest(request, approve: false)
            } label: {
                Text("Afwijzen")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.danger)
                    .padding(.horizontal, BCSpacing.sm)
                    .padding(.vertical, BCSpacing.xs)
                    .background(Capsule().fill(BCColors.danger.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, BCSpacing.sm)
    }

    /// Avatar-initiaal, zelfde stijl als de naaste-card.
    private func memberAvatar(name: String) -> some View {
        ZStack {
            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 40, height: 40)
            Text(String(name.prefix(1)))
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.primary)
        }
    }
}

// MARK: - Start-zorgkring sheet (min/max teamgrootte)

private struct StartCareTeamSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let elderly: ElderlyUser
    @State private var minSize = 3
    @State private var maxSize = 5

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                Text("Hoeveel buddies mogen er in de zorgkring van \(elderly.firstName)? We zoeken door tot het minimum is bereikt; daarna beoordeel je het team.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                BCCard {
                    VStack(spacing: BCSpacing.sm) {
                        Stepper(value: $minSize, in: 1...6) {
                            HStack {
                                Text("Minimaal")
                                    .font(BCTypography.body)
                                    .foregroundStyle(BCColors.textPrimary)
                                Text("\(minSize)")
                                    .font(BCTypography.bodyEmphasized)
                                    .foregroundStyle(BCColors.primary)
                            }
                        }
                        .onChange(of: minSize) { _, newValue in
                            if maxSize < newValue { maxSize = newValue }
                        }
                        Divider()
                        Stepper(value: $maxSize, in: minSize...8) {
                            HStack {
                                Text("Maximaal")
                                    .font(BCTypography.body)
                                    .foregroundStyle(BCColors.textPrimary)
                                Text("\(maxSize)")
                                    .font(BCTypography.bodyEmphasized)
                                    .foregroundStyle(BCColors.primary)
                            }
                        }
                    }
                }

                BCPrimaryButton(title: "Start de zorgkring", icon: "person.2.wave.2.fill",
                                cornerRadius: BCRadius.md, height: 56) {
                    appState.startTeamFormation(minSize: minSize, maxSize: maxSize, for: elderly)
                    dismiss()
                }

                Spacer(minLength: 0)
            }
            .padding(BCSpacing.lg)
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Start een zorgkring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Recent visits sheet (for family rating)

private struct FamilyVisitsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTask: ServiceTask? = nil

    private var visits: [ServiceTask] {
        appState.taskHistory.filter { $0.elderlyName == appState.activeFamilyElderly.firstName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recente bezoeken")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("Bezoeken bij \(appState.activeFamilyElderly.firstName), tik om te beoordelen")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    if visits.isEmpty {
                        BCCard {
                            Text("Nog geen bezoeken.")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else {
                        VStack(spacing: BCSpacing.sm) {
                            ForEach(visits) { task in
                                let rated = appState.taskRatings[task.id]
                                let needsReview = rated == nil && !appState.skippedReviews.contains(task.id)
                                Button { selectedTask = task } label: {
                                    BCCard {
                                        HStack(spacing: BCSpacing.md) {
                                            AppIcon(name: task.category.brandIcon, size: 24)
                                                .frame(width: 44, height: 44)
                                                .background(Circle().fill(BCColors.primary.opacity(0.10)))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.category.displayName)
                                                    .font(BCTypography.bodyEmphasized)
                                                    .foregroundStyle(BCColors.textPrimary)
                                                if let buddy = task.assignedBuddyName {
                                                    Text("Met \(buddy)")
                                                        .font(BCTypography.caption)
                                                        .foregroundStyle(BCColors.textSecondary)
                                                }
                                                if let date = task.completedAt {
                                                    Text(date.formatted(date: .long, time: .omitted))
                                                        .font(BCTypography.caption)
                                                        .foregroundStyle(BCColors.textTertiary)
                                                }
                                                // Waardering tonen via de merk-component
                                                // (kringstippen, geen sterren).
                                                if let rated {
                                                    BCRatingStars(value: Double(rated), size: 10)
                                                        .padding(.top, 1)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(BCColors.textTertiary)
                                        }
                                    }
                                    .overlay(alignment: .leading) {
                                        if needsReview {
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: BCRadius.lg,
                                                bottomLeadingRadius: BCRadius.lg,
                                                bottomTrailingRadius: 0,
                                                topTrailingRadius: 0,
                                                style: .continuous
                                            )
                                            .fill(BCColors.primary)
                                            .frame(width: 4)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Bezoeken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            FamilyRatingSheet(task: task)
        }
    }
}

// MARK: - Rating sheet for family

private struct FamilyRatingSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted = false

    private var alreadyRated: Bool { appState.taskRatings[task.id] != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.xl) {
                    VStack(spacing: BCSpacing.md) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BCColors.primary)
                        }
                        Text("Hoe was het bezoek van \(task.assignedBuddyName ?? "de buddy")?")
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(task.category.displayName)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    .padding(.top, BCSpacing.lg)
                    .padding(.horizontal, BCSpacing.lg)

                    if submitted || alreadyRated {
                        VStack(spacing: BCSpacing.md) {
                            BCPopIcon(systemName: "star.fill", color: BCColors.warning, size: 48)
                            Text("Bedankt voor de beoordeling!")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .padding(BCSpacing.xl)
                    } else {
                        VStack(spacing: BCSpacing.lg) {
                            HStack(spacing: BCSpacing.md) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedStars = star
                                    } label: {
                                        Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                            .font(.system(size: 36, weight: .semibold))
                                            .foregroundStyle(star <= selectedStars ? BCColors.warning : BCColors.border)
                                            .frame(width: 56, height: 56)
                                            .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.2), value: selectedStars)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedStars > 0 {
                                BCCard {
                                    TextField("Vertel er iets meer over (optioneel)", text: $reviewText, axis: .vertical)
                                        .lineLimit(3, reservesSpace: true)
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                BCPrimaryButton(title: "Verstuur beoordeling", icon: "star.fill") {
                                    appState.rateTask(taskId: task.id, stars: selectedStars, body: reviewText)
                                    withAnimation { submitted = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity)
                            }

                            Button {
                                appState.skipReview(taskId: task.id)
                                dismiss()
                            } label: {
                                Text("Beoordeling overslaan")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                                    .padding(.vertical, BCSpacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedStars)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Beoordeling geven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .onAppear { selectedStars = appState.taskRatings[task.id] ?? 0 }
    }
}

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = BCColors.primary

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(BCTypography.headline)
                .foregroundStyle(color)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FamilyDashboardView().environment(AppState())
}
