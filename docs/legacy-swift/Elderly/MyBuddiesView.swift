import SwiftUI

struct MyBuddiesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    // Zorgkring: bevestigingen en flows.
    @State private var memberPendingRemoval: PoolMember? = nil
    @State private var visitPendingCancel: CareVisit? = nil
    @State private var showTeamSetup = false
    @State private var showTeamCelebration = false
    // Teamchat (fase36): het gezamenlijke kanaal met de vrijwilligers.
    @State private var showTeamChat = false
    // Buddy-ids (stabiel over herladingen) die al "Prima" kregen in de review.
    @State private var acceptedBuddyIds: Set<UUID> = []
    @State private var searchPulse = false

    private var favoriteBuddies: [BuddyUser] {
        appState.allBuddies.filter { appState.favoriteBuddyNames.contains($0.firstName) }
    }

    private var pastBuddies: [BuddyUser] {
        let pastNames = Set(appState.taskHistory.compactMap(\.assignedBuddyName))
        return appState.allBuddies.filter {
            pastNames.contains($0.firstName) && !appState.favoriteBuddyNames.contains($0.firstName)
        }
    }

    /// De zorgkring rond deze hulpvrager; nil in random-only modus.
    private var myTeam: CareTeam? {
        guard appState.elderlyTeamMode != "random_only" else { return nil }
        return appState.careTeam(for: appState.elderlyUser)
    }

    private var pendingJoinRequests: [CareJoinRequest] {
        appState.careJoinRequests.filter { $0.status == "pending" }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Mijn buddies",
                     subtitle: myTeam != nil ? "Uw vaste team om u heen" : "Vaste mensen die u kennen")

            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    if let team = myTeam {
                        // Het team is het hart van deze pagina.
                        myTeamSection(team: team)

                        if !pendingJoinRequests.isEmpty {
                            joinRequestsSection(team: team)
                        }
                    } else {
                        // Random-only (of nog geen team): vaste buddies + de
                        // uitnodiging om alsnog een team te bouwen.
                        favoritesSection
                        pastSection
                        teamConversionCard
                    }
                }
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .task {
            // Live: het zorg-team (leden + rooster) en join-verzoeken vers ophalen.
            await appState.loadCareTeams()
            await appState.loadCareJoinRequests()
        }
        .fullScreenCover(isPresented: $showTeamSetup) {
            // Conversie vanuit "losse buddies": direct naar de teamgrootte-stap.
            TeamSetupFlow(startAtSize: true,
                          onDone: { showTeamSetup = false },
                          onCancel: { showTeamSetup = false })
                .environment(\.largeTextEnabled, appState.largeTextEnabled)
        }
        .sheet(isPresented: $showTeamChat) {
            if let team = myTeam {
                TeamChatView(teamId: team.id, teamName: team.name, channels: [.all])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Deze buddy uit uw team halen?",
               isPresented: Binding(get: { memberPendingRemoval != nil },
                                    set: { if !$0 { memberPendingRemoval = nil } }),
               presenting: memberPendingRemoval) { member in
            Button("Ja, uit mijn team", role: .destructive) {
                if let teamId = myTeam?.id, let buddyId = member.buddyId {
                    appState.removeCareTeamMember(teamId: teamId, buddyId: buddyId)
                }
                memberPendingRemoval = nil
            }
            Button("Nee, laat staan", role: .cancel) { memberPendingRemoval = nil }
        } message: { member in
            Text("\(member.name) krijgt hier netjes bericht van. U hoeft geen reden te geven.")
        }
        .alert("Dit moment schrappen?",
               isPresented: Binding(get: { visitPendingCancel != nil },
                                    set: { if !$0 { visitPendingCancel = nil } }),
               presenting: visitPendingCancel) { visit in
            Button("Ja, schrappen", role: .destructive) {
                if let teamId = myTeam?.id {
                    appState.cancelCareVisit(teamId: teamId, visitId: visit.id)
                }
                visitPendingCancel = nil
            }
            Button("Nee, laat staan", role: .cancel) { visitPendingCancel = nil }
        } message: { visit in
            Text("\(visit.category.displayName) op \(visit.date.formatted(date: .abbreviated, time: .shortened)) wordt uit het rooster gehaald.")
        }
        .overlay {
            if showTeamCelebration {
                BCCelebrationOverlay(
                    icon: "person.3.fill",
                    title: "Uw team staat klaar!",
                    subtitle: "Uw buddies zien nu uw rooster en verdelen de bezoeken onderling.",
                    onDone: { showTeamCelebration = false }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Mijn team (zorgkring rond deze cliënt)

    @ViewBuilder
    private func myTeamSection(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Mijn team")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.md)

            switch team.status {
            case .forming:
                formingBanner(team: team)
                if team.memberCount > 0 { fallbackChoiceBlock(team: team) }
            case .review:
                reviewSection(team: team)
            case .live, .paused:
                liveTeamCard(team: team)
            }
        }
    }

    // MARK: Status .forming — we zoeken nog buddies

    private func formingBanner(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BCColors.primary.opacity(0.12))
                        .frame(width: 56, height: 56)
                        .scaleEffect(searchPulse ? 1.15 : 0.9)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: searchPulse)
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("We zoeken nog buddies voor uw team")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("\(team.memberCount) van minimaal \(team.minSize) gevonden")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
            }

            ProgressView(value: Double(min(team.memberCount, team.minSize)),
                         total: Double(max(team.minSize, 1)))
                .tint(BCColors.primary)

            Text("Buddies bij u in de buurt krijgen een uitnodiging. U krijgt bericht zodra uw team er staat.")
                .font(et.caption)
                .foregroundStyle(BCColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if !team.members.isEmpty {
                Divider()
                Text("Al gevonden: \(team.members.map(\.name).joined(separator: ", "))")
                    .font(et.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
        .padding(.horizontal, BCSpacing.lg)
        .onAppear { searchPulse = true }
    }

    // MARK: Status .review — buddies beoordelen

    private func reviewSection(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text(team.memberCount == 1
                    ? "1 buddy staat voor u klaar"
                    : "\(team.memberCount) buddies staan voor u klaar")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)

            Text("Bekijk uw buddies rustig. Vindt u iemand toch niet passen? Tik dan op \u{201C}Liever niet\u{201D}.")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.lg)

            VStack(spacing: BCSpacing.sm) {
                ForEach(team.members) { member in
                    reviewCard(member: member, team: team)
                }
            }
            .padding(.horizontal, BCSpacing.lg)

            if team.memberCount < team.maxSize {
                fallbackChoiceBlock(team: team)
            }

            BCCTAButton(title: "Bevestig mijn team", icon: "checkmark") {
                appState.finalizeTeamReview(teamId: team.id)
                withAnimation(.easeOut(duration: 0.25)) { showTeamCelebration = true }
            }
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    private func reviewCard(member: PoolMember, team: CareTeam) -> some View {
        let accepted = acceptedBuddyIds.contains(member.buddyId ?? member.id)
        return VStack(alignment: .leading, spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.md) {
                memberAvatar(member)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Wil in uw team")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
                if accepted {
                    BCStatusPill(label: "Prima", color: BCColors.success, showDot: true)
                }
            }
            if !accepted {
                HStack(spacing: BCSpacing.sm) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        acceptedBuddyIds.insert(member.buddyId ?? member.id)
                        if let buddyId = member.buddyId {
                            appState.reviewTeamMember(teamId: team.id, buddyId: buddyId, accept: true)
                        }
                    } label: {
                        Label("Prima", systemImage: "hand.thumbsup.fill")
                            .font(et.caption)
                            .foregroundStyle(BCColors.success)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BCSpacing.sm)
                            .background(Capsule().fill(BCColors.success.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button {
                        memberPendingRemoval = member
                    } label: {
                        Label("Liever niet", systemImage: "hand.raised.fill")
                            .font(et.caption)
                            .foregroundStyle(BCColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BCSpacing.sm)
                            .background(Capsule().fill(BCColors.danger.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
    }

    // MARK: 1-uur-keuze — team nog niet vol

    private func fallbackChoiceBlock(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Uw team is nog niet vol. Wat wilt u?")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)

            Button {
                appState.setTeamFallback(teamId: team.id, allowed: true)
                appState.finalizeTeamReview(teamId: team.id)
                withAnimation(.easeOut(duration: 0.25)) { showTeamCelebration = true }
            } label: {
                choiceRow(icon: "person.3.fill",
                          title: "Vul aan met buddies uit de buurt",
                          subtitle: "Bij gaten helpt een buddy uit de buurt u alsnog.")
            }
            .buttonStyle(.plain)

            Button {
                appState.setTeamFallback(teamId: team.id, allowed: false)
                appState.finalizeTeamReview(teamId: team.id)
                withAnimation(.easeOut(duration: 0.25)) { showTeamCelebration = true }
            } label: {
                choiceRow(icon: "person.2.fill",
                          title: "Alleen deze buddies",
                          subtitle: "Alleen uw eigen team krijgt uw hulpvragen te zien.")
            }
            .buttonStyle(.plain)
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.primary.opacity(0.06))
        )
        .padding(.horizontal, BCSpacing.lg)
    }

    private func choiceRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: BCSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(BCColors.surface))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(et.body)
                    .foregroundStyle(BCColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(et.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BCColors.textTertiary)
        }
        .padding(BCSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(BCColors.surface)
        )
    }

    // MARK: Status .live — team + inzetrooster

    private func liveTeamCard(team: CareTeam) -> some View {
        // Fase36: groene gloed zodra het hele rooster is ingevuld.
        let filled = team.scheduleFilled()
        return VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Uw vaste buddies staan samen voor u klaar. Vraagt u hulp, dan verdelen zij de bezoeken onderling.")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.lg)

            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 48, height: 48)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.name)
                            .font(et.body)
                            .foregroundStyle(BCColors.textPrimary)
                        Text(team.memberCount == 1 ? "1 buddy" : "\(team.memberCount) buddies")
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                    if filled {
                        BCStatusPill(label: "Rooster rond", color: BCColors.accentDark, showDot: true)
                    } else {
                        BCStatusPill(label: team.status.label, color: BCColors.success, showDot: true)
                    }
                }

                // Teamchat (fase36): samen met de vrijwilligers overleggen.
                Button {
                    showTeamChat = true
                } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Berichten met uw team")
                            .font(et.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .foregroundStyle(BCColors.primary)
                    .padding(BCSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)

                if !team.members.isEmpty {
                    Divider()
                    ForEach(team.members) { member in
                        HStack(spacing: BCSpacing.md) {
                            memberAvatar(member)
                            Text(member.name)
                                .font(et.body)
                                .foregroundStyle(BCColors.textPrimary)
                            Spacer()
                            Menu {
                                Button(role: .destructive) {
                                    memberPendingRemoval = member
                                } label: {
                                    Label("Uit mijn team halen", systemImage: "person.badge.minus")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(BCColors.textTertiary)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(BCColors.surfaceMuted))
                            }
                            .accessibilityLabel("Opties voor \(member.name)")
                        }
                    }
                }

                // Inzetrooster: de eerstvolgende bezoeken met status.
                let upcoming = team.schedule.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
                if !upcoming.isEmpty {
                    Divider()
                    Text("Inzetrooster")
                        .font(BCTypography.captionEmphasized)
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(BCColors.textTertiary)
                    ForEach(upcoming.prefix(5)) { visit in
                        rosterRow(visit: visit)
                    }
                    if upcoming.count > 5 {
                        Text("En nog \(upcoming.count - 5) bezoeken verder vooruit.")
                            .font(et.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                }
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(filled ? BCColors.accent : .clear, lineWidth: 2)
            )
            .shadow(color: filled ? BCColors.accent.opacity(0.5) : BCColors.primaryDark.opacity(0.10),
                    radius: filled ? 12 : 6, x: 0, y: 2)
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    private func rosterRow(visit: CareVisit) -> some View {
        let status = visit.status()
        // Fase36: een geclaimd moment waarvoor vervanging wordt gezocht.
        let seeksSwap = status == .claimed && visit.swapRequested
        return HStack(spacing: BCSpacing.sm) {
            Image(systemName: visit.category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(visit.category.displayName)
                    .font(et.caption)
                    .foregroundStyle(BCColors.textPrimary)
                Text(visit.date.formatted(date: .abbreviated, time: .shortened))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            Spacer()
            BCStatusPill(
                label: seeksSwap ? "Zoekt vervanging"
                    : status == .claimed ? (visit.claimedByName ?? "Opgepakt") : status.label,
                color: seeksSwap ? BCColors.warning : status.color,
                showDot: true
            )
            // Een nog niet geclaimd moment mag de hulpvrager schrappen.
            if status != .claimed {
                Button {
                    visitPendingCancel = visit
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(BCColors.textTertiary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Schrap dit moment")
            }
        }
    }

    private func memberAvatar(_ member: PoolMember) -> some View {
        // Fase36: echte profielfoto van de vrijwilliger (initiaal als terugval).
        TeamMemberFace(member: member, size: 48)
    }

    // MARK: - Join-verzoeken (buddies die bij het team willen)

    private func joinRequestsSection(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Buddies die bij uw team willen")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.md)

            Text("Deze buddies vragen of ze bij uw team mogen. U beslist.")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.lg)

            VStack(spacing: BCSpacing.sm) {
                ForEach(pendingJoinRequests) { request in
                    joinRequestCard(request: request)
                }
            }
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    private func joinRequestCard(request: CareJoinRequest) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 48, height: 48)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.buddyName)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(request.source == "fallback"
                            ? "Heeft u al eens geholpen en wil vast teamlid worden"
                            : "Wil graag bij uw team")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: BCSpacing.sm) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appState.respondCareJoinRequest(request, approve: true)
                } label: {
                    Label("Accepteren", systemImage: "checkmark")
                        .font(et.caption)
                        .foregroundStyle(BCColors.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.sm)
                        .background(Capsule().fill(BCColors.success.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Button {
                    appState.respondCareJoinRequest(request, approve: false)
                } label: {
                    Label("Afwijzen", systemImage: "xmark")
                        .font(et.caption)
                        .foregroundStyle(BCColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.sm)
                        .background(Capsule().fill(BCColors.danger.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
    }

    // MARK: - Vaste buddies (random-only modus)

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Vaste buddies")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.md)

            Text("Vaste buddies zijn vertrouwde gezichten die u vaker helpen. Zij krijgen er bericht van als u ze kiest.")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.lg)

            if favoriteBuddies.isEmpty {
                BCCard {
                    Text("U heeft nog geen vaste buddies. Tik op een eerder bezoek om iemand toe te voegen.")
                        .font(et.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(.horizontal, BCSpacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(favoriteBuddies.enumerated()), id: \.element.id) { index, buddy in
                        BuddyRow(buddy: buddy, isFavorite: true) {
                            appState.toggleFavorite(buddyName: buddy.firstName)
                        }
                        if index < favoriteBuddies.count - 1 {
                            Divider()
                                .padding(.leading, BCSpacing.lg)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                        .fill(BCColors.surface)
                )
                .bcSoftShadow(.card)
                .padding(.horizontal, BCSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private var pastSection: some View {
        if !pastBuddies.isEmpty {
            Text("Eerder geholpen")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.lg)

            VStack(spacing: 0) {
                ForEach(Array(pastBuddies.enumerated()), id: \.element.id) { index, buddy in
                    BuddyRow(buddy: buddy, isFavorite: false) {
                        appState.toggleFavorite(buddyName: buddy.firstName)
                    }
                    if index < pastBuddies.count - 1 {
                        Divider()
                            .padding(.leading, BCSpacing.lg)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
            .padding(.horizontal, BCSpacing.lg)
        }
    }

    /// Random-only: uitnodiging om alsnog een vast team te bouwen. De vaste
    /// buddies worden dan automatisch als eersten uitgenodigd.
    private var teamConversionCard: some View {
        Button {
            showTeamSetup = true
        } label: {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(BCColors.primary)
                    }
                    Text("Toch een vast team om u heen?")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
                Text("Een klein groepje vaste buddies dat de bezoeken samen verdeelt. Uw vaste buddies worden automatisch als eersten uitgenodigd.")
                    .font(et.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
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
        .padding(.top, BCSpacing.lg)
    }
}

private struct BuddyRow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    let buddy: BuddyUser
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            let avatarSize: CGFloat = largeText ? 72 : 56
            ZStack {
                Circle().fill(BCColors.primary.opacity(0.10)).frame(width: avatarSize, height: avatarSize)
                Image(systemName: buddy.avatarSystemName)
                    .font(.system(size: largeText ? 38 : 30, weight: .regular))
                    .foregroundStyle(BCColors.primary)
            }
            VStack(alignment: .leading, spacing: largeText ? 6 : 4) {
                HStack(spacing: BCSpacing.xs) {
                    Text(buddy.firstName)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: largeText ? 16 : 12, weight: .semibold))
                            .foregroundStyle(BCColors.danger)
                    }
                }
                BCRatingStars(value: buddy.ratingAverage)
                HStack(spacing: BCSpacing.xs) {
                    Text("\(buddy.totalTasks) bezoeken")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
            Spacer()
            let heartSize: CGFloat = largeText ? 56 : 44
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: largeText ? 24 : 18, weight: .semibold))
                    .foregroundStyle(isFavorite ? BCColors.danger : BCColors.textTertiary)
                    .frame(width: heartSize, height: heartSize)
                    .background(Circle().fill(isFavorite ? BCColors.danger.opacity(0.10) : BCColors.surfaceMuted))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isFavorite)
        }
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MyBuddiesView().environment(AppState())
}
