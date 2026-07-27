//  AppState+CareTeams.swift
//  Zorgkringen (fase35, zorgkring-pivot). Demo: lokaal; live: Supabase.

import Foundation
import SwiftUI
import CoreLocation

extension AppState {

    /// Mijn zorgkringen bovenaan, daarna de rest.
    var sortedCareTeams: [CareTeam] {
        careTeams.sorted { ($0.isMyTeam ? 0 : 1) < ($1.isMyTeam ? 0 : 1) }
    }

    /// De zorgkring rond een specifieke hulpvrager (voor de cliënt zelf of het
    /// familielid dat namens hem/haar beheert). nil = geen team.
    func careTeam(for elderly: ElderlyUser) -> CareTeam? {
        if let match = careTeams.first(where: { team in
            if let id = team.elderlyId { return id == elderly.id }
            return !team.elderlyName.isEmpty && team.elderlyName == elderly.firstName
        }) { return match }
        // Demo: er is maar één voorbeeldteam — laat de cliënt-rol dat team zien.
        if !isLive, currentRole != .buddy { return careTeams.first }
        return nil
    }

    /// Openstaande uitnodigingen voor déze buddy.
    var openTeamInvites: [TeamInvite] { teamInvites.filter { $0.isOpen } }

    // MARK: - Mapping DB → app-model

    static func careTeam(from db: DBCareTeam, currentUserId: UUID?,
                         buddyNames: [UUID: String] = [:]) -> CareTeam {
        let members = db.members.map { m -> PoolMember in
            // profiles is alleen self-leesbaar (RLS); de voornamen van andere
            // buddies komen uit de buddy_map_pins-view als terugval.
            let name = m.profile?.firstName ?? buddyNames[m.buddyId] ?? "Buddy"
            return PoolMember(name: name,
                       avatar: "person.crop.circle.fill", points: m.points ?? 0,
                       isCurrentUser: currentUserId != nil && m.buddyId == currentUserId,
                       buddyId: m.buddyId)
        }
        let nameFor: (UUID) -> String = { id in
            members.first { $0.buddyId == id }?.name ?? buddyNames[id] ?? "Teamlid"
        }
        let mine = currentUserId != nil && db.members.contains { $0.buddyId == currentUserId }
        let visits = db.visits.map { v -> CareVisit in
            CareVisit(id: v.id,
                      category: TaskCategory(rawValue: v.category) ?? .other,
                      date: parseISO(v.scheduledAt) ?? Date(),
                      note: v.note ?? "",
                      createdAt: parseISO(v.createdAt) ?? Date(),
                      claimedByBuddyId: v.claimedBy,
                      claimedByName: v.claimedBy.map(nameFor),
                      urgentSent: v.urgentSent ?? false,
                      swapRequested: v.swapRequested ?? false,
                      swapReason: v.swapReason ?? "")
        }
        return CareTeam(id: db.id, name: db.name, elderlyId: db.elderlyId,
                        elderlyName: db.elderlyName ?? "Hulpvrager",
                        tint: Palette.tint(forKey: db.accent),
                        status: CareTeamStatus(rawValue: db.status ?? "live") ?? .live,
                        minSize: db.minSize ?? 3, maxSize: db.maxSize ?? 5,
                        fallbackAllowed: db.fallbackAllowed ?? true,
                        area: db.area ?? "", helpSummary: db.helpSummary ?? "",
                        members: members, visits: visits, isMyTeam: mine,
                        inviteCode: db.inviteCode ?? "",
                        outingTarget: db.outingTarget ?? 2000,
                        approxLatitude: db.approxLatitude,
                        approxLongitude: db.approxLongitude)
    }

    static func teamInvite(from db: DBCareTeamInvite) -> TeamInvite {
        TeamInvite(id: db.id, careTeamId: db.careTeamId,
                   elderlyName: db.elderlyName, area: db.area,
                   helpSummary: db.helpSummary, isFavorite: db.isFavorite,
                   status: db.status, sentAt: parseISO(db.sentAt) ?? Date())
    }

    // MARK: - Laden

    func loadCareTeams() async {
        guard isLive else { return }
        guard let rows = try? await CareTeamService().fetchCareTeams() else { return }
        let me = realUserId
        let names = Dictionary(uniqueKeysWithValues: mapBuddyPins.map { ($0.id, $0.firstName) })
        let mapped = rows.map { Self.careTeam(from: $0, currentUserId: me, buddyNames: names) }
        await MainActor.run { self.careTeams = mapped }
    }

    /// Buddy-druppels voor de kaart-home (fase36). Demo: uit MockData.
    func loadBuddyMapPins() async {
        if isLive {
            guard let rows = try? await CareTeamService().fetchBuddyMapPins() else { return }
            let fresh = Date().addingTimeInterval(-30 * 60)
            let mapped: [MapBuddyPin] = rows.compactMap { row in
                // Verse live-locatie gaat vóór het (grove) thuisadres.
                var lat = row.latitude, lon = row.longitude
                if let cl = row.currentLatitude, let cn = row.currentLongitude,
                   let updated = Self.parseISO(row.locationUpdatedAt ?? ""), updated > fresh {
                    lat = cl; lon = cn
                }
                guard let la = lat, let lo = lon else { return nil }
                return MapBuddyPin(id: row.id,
                                   firstName: row.firstName?.isEmpty == false ? row.firstName! : "Buddy",
                                   coordinate: CLLocationCoordinate2D(latitude: la, longitude: lo),
                                   isAvailable: row.isAvailableNow ?? false,
                                   hasAvatar: row.hasAvatar ?? false)
            }
            await MainActor.run { self.mapBuddyPins = mapped }
        } else {
            let mapped = allBuddies.filter { $0.canAcceptTasks }.map {
                MapBuddyPin(id: $0.id, firstName: $0.firstName,
                            coordinate: $0.coordinate,
                            isAvailable: $0.isAvailableNow, hasAvatar: false)
            }
            await MainActor.run { self.mapBuddyPins = mapped }
        }
    }

    func loadTeamInvites() async {
        guard isLive else { return }
        guard let rows = try? await CareTeamService().fetchMyInvites() else { return }
        let mapped = rows.map(Self.teamInvite(from:))
        await MainActor.run { self.teamInvites = mapped }
    }

    func loadCareJoinRequests() async {
        guard isLive else { return }
        guard let rows = try? await CareTeamService().fetchJoinRequests() else { return }
        let mapped = rows.map { r in
            CareJoinRequest(id: r.id, careTeamId: r.careTeamId, buddyId: r.buddyId,
                            buddyName: r.profile?.firstName ?? "Buddy",
                            source: r.source, status: r.status,
                            createdAt: Self.parseISO(r.createdAt) ?? Date())
        }
        await MainActor.run { self.careJoinRequests = mapped }
    }

    // MARK: - Teamvoorkeur (hulpvrager)

    /// Kiest de hulpvrager voor "geen team, alleen losse buddies" (random_only)
    /// of voor een zorgkring ('team'). Bij random_only blijven vaste buddies
    /// (hart) het aanspreekpunt; bij een latere teamwens worden zij als eersten
    /// uitgenodigd (ring 1 van de team-formation cron).
    func setElderlyTeamMode(_ mode: String) {
        elderlyTeamMode = mode
        guard isLive, let id = realUserId else { return }
        Task { try? await ProfileService().updateElderlyTeamMode(elderlyId: id, teamMode: mode) }
    }

    // MARK: - Teamvorming (hulpvrager/familie)

    /// Start de werving: buddies in de buurt krijgen per ring een uitnodiging.
    /// Familie geeft `elderly` mee; de hulpvrager zelf laat 'm weg.
    func startTeamFormation(minSize: Int, maxSize: Int, for elderly: ElderlyUser? = nil) {
        let target = elderly ?? elderlyUser
        let name = "Team \(target.firstName)"
        if isLive {
            let elderlyId: UUID? = (currentRole == .family) ? target.id : nil
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await CareTeamService().startTeamFormation(
                        name: name, minSize: minSize, maxSize: maxSize, elderlyId: elderlyId)
                    await self.loadCareTeams()
                    await MainActor.run {
                        self.elderlyTeamMode = "team"
                        self.showToast(text: "We zoeken buddies in de buurt voor je team", icon: "person.2.wave.2.fill")
                    }
                } catch {
                    await MainActor.run { self.showToast(text: "Team starten mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else {
            // Demo: toon meteen een team in review-fase met een paar buddies.
            let demo = CareTeam(id: UUID(), name: name, elderlyId: target.id,
                                elderlyName: target.firstName, tint: Palette.teal,
                                status: .review, minSize: minSize, maxSize: maxSize,
                                members: [
                                    PoolMember(name: "Sanne", avatar: "person.crop.circle.fill", points: 0, buddyId: UUID()),
                                    PoolMember(name: "Mark", avatar: "person.crop.circle.fill", points: 0, buddyId: UUID()),
                                    PoolMember(name: "Fatima", avatar: "person.crop.circle.fill", points: 0, buddyId: UUID()),
                                ])
            careTeams.removeAll { $0.elderlyId == target.id }
            careTeams.insert(demo, at: 0)
            elderlyTeamMode = "team"
            showToast(text: "We zoeken buddies in de buurt voor je team", icon: "person.2.wave.2.fill")
        }
    }

    /// Review: buddy weigeren of accepteren. Weigeren haalt 'm uit het team.
    func reviewTeamMember(teamId: UUID, buddyId: UUID, accept: Bool) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await CareTeamService().reviewMember(teamId: teamId, buddyId: buddyId, accept: accept)
                await self.loadCareTeams()
                if !accept {
                    await MainActor.run { self.showToast(text: "Buddy uit het team gehaald", icon: "person.badge.minus") }
                }
            }
        } else if !accept, let ti = careTeams.firstIndex(where: { $0.id == teamId }) {
            careTeams[ti].members.removeAll { $0.buddyId == buddyId }
            showToast(text: "Buddy uit het team gehaald", icon: "person.badge.minus")
        }
    }

    /// Review afronden → team live.
    func finalizeTeamReview(teamId: UUID) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().finalizeReview(teamId: teamId)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Je team staat voor je klaar!", icon: "heart.circle.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Bevestigen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }) {
            careTeams[ti].status = .live
            showToast(text: "Je team staat voor je klaar!", icon: "heart.circle.fill")
        }
    }

    /// Keuze na 1 uur: gaten laten vullen door willekeurige buddies of niet.
    func setTeamFallback(teamId: UUID, allowed: Bool) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await CareTeamService().setFallbackAllowed(teamId: teamId, allowed: allowed)
                await self.loadCareTeams()
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }) {
            careTeams[ti].fallbackAllowed = allowed
        }
        showToast(text: allowed ? "Gaten worden gevuld door buddies uit de buurt"
                                : "Alleen je eigen team helpt je voorlopig",
                  icon: allowed ? "person.3.fill" : "person.2.fill")
    }

    /// Teamlid verwijderen (hulpvrager/familie).
    func removeCareTeamMember(teamId: UUID, buddyId: UUID) {
        reviewTeamMember(teamId: teamId, buddyId: buddyId, accept: false)
    }

    // MARK: - Uitnodigingen (buddy)

    func acceptTeamInvite(_ invite: TeamInvite) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().acceptInvite(inviteId: invite.id)
                    await self.loadTeamInvites()
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Je zit in het team van \(invite.elderlyName)!", icon: "heart.circle.fill") }
                } catch {
                    await self.loadTeamInvites()
                    await MainActor.run { self.showToast(text: "Dit team zit inmiddels vol", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else {
            teamInvites.removeAll { $0.id == invite.id }
            showToast(text: "Je zit in het team van \(invite.elderlyName)!", icon: "heart.circle.fill")
        }
    }

    func declineTeamInvite(_ invite: TeamInvite) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await CareTeamService().declineInvite(inviteId: invite.id)
                await self.loadTeamInvites()
            }
        } else {
            teamInvites.removeAll { $0.id == invite.id }
        }
    }

    // MARK: - Join-verzoeken

    /// Buddy vraagt om lid te worden ("Teams in de buurt" of als invaller).
    func requestJoinCareTeam(_ team: CareTeam, source: String = "search") {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await CareTeamService().requestJoin(teamId: team.id, source: source)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Verzoek gestuurd aan \(team.elderlyName)", icon: "paperplane.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Verzoek sturen mislukt", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else if let idx = careTeams.firstIndex(where: { $0.id == team.id }) {
            careTeams[idx].pendingJoin = true
            showToast(text: "Verzoek gestuurd aan \(team.elderlyName)", icon: "paperplane.fill")
        }
    }

    /// Hulpvrager/familie beslist over een join-verzoek.
    func respondCareJoinRequest(_ request: CareJoinRequest, approve: Bool) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().respondJoinRequest(requestId: request.id, approve: approve)
                    await self.loadCareJoinRequests()
                    await self.loadCareTeams()
                    await MainActor.run {
                        self.showToast(text: approve ? "\(request.buddyName) zit nu in je team" : "Verzoek afgewezen",
                                       icon: approve ? "person.badge.plus" : "xmark.circle.fill")
                    }
                } catch {
                    await MainActor.run { self.showToast(text: "Verwerken mislukt (team vol?)", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else {
            careJoinRequests.removeAll { $0.id == request.id }
        }
    }

    // MARK: - Schema

    /// Zet hulpmomenten in het inzetrooster van de zorgkring. De teamleden
    /// krijgen automatisch een "claim jouw plekken"-melding (schedule-watchdog).
    func requestTeamVisits(teamId: UUID, category: TaskCategory, note: String, dates: [Date]) {
        // Rooster nooit onbeperkt vullen: maximaal een jaar aan wekelijkse bezoeken.
        let capped = Array(dates.prefix(52))
        guard !capped.isEmpty else { return }
        let toastText = capped.count == 1
            ? "Moment in het teamrooster gezet"
            : "\(capped.count) momenten in het teamrooster gezet"
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().requestCareVisits(
                        teamId: teamId, category: category.rawValue, note: note, dates: capped)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: toastText, icon: "calendar.badge.plus") }
                } catch {
                    await MainActor.run {
                        self.showToast(text: "In het rooster zetten mislukt, probeer opnieuw",
                                       icon: "exclamationmark.triangle.fill")
                    }
                }
            }
        } else {
            guard let idx = careTeams.firstIndex(where: { $0.id == teamId }) else { return }
            let now = Date()
            let visits = capped.map {
                CareVisit(id: UUID(), category: category, date: $0, note: note, createdAt: now)
            }
            careTeams[idx].visits.append(contentsOf: visits)
            showToast(text: toastText, icon: "calendar.badge.plus")
        }
    }

    /// De concrete bezoekdatums voor een team-aanvraag: de gekozen datum, of
    /// alle datums uit het herhaalschema (periodiek → inzetrooster).
    static func teamVisitDates(timing: TaskTiming, schedule: RecurringSchedule?) -> [Date] {
        guard case .scheduled(let start) = timing else { return [] }
        if let schedule { return schedule.occurrences(from: start) }
        return [start]
    }

    /// Claimt een moment uit het schema. Teamleden altijd; buiten het team kan
    /// het alleen na de urgente broadcast (30 min vooraf).
    func claimCareVisit(teamId: UUID, visitId: UUID) {
        guard let ti = careTeams.firstIndex(where: { $0.id == teamId }),
              let vi = careTeams[ti].visits.firstIndex(where: { $0.id == visitId }) else { return }
        guard careTeams[ti].visits[vi].status() != .claimed else {
            showToast(text: "Dit moment is al opgepakt", icon: "exclamationmark.triangle.fill")
            return
        }
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().claimVisit(visitId: visitId)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Je pakt dit moment op", icon: "checkmark.circle.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Oppakken mislukt, misschien net geclaimd", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else {
            careTeams[ti].visits[vi].claimedByBuddyId = buddyUser.id
            careTeams[ti].visits[vi].claimedByName = buddyUser.firstName
            showToast(text: "Je pakt dit moment op", icon: "checkmark.circle.fill")
        }
    }

    /// Moment schrappen (hulpvrager/familie). De geclaimde buddy krijgt bericht.
    func cancelCareVisit(teamId: UUID, visitId: UUID) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await CareTeamService().cancelVisit(visitId: visitId)
                await self.loadCareTeams()
                await MainActor.run { self.showToast(text: "Moment uit het schema gehaald", icon: "calendar.badge.minus") }
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }) {
            careTeams[ti].visits.removeAll { $0.id == visitId }
            showToast(text: "Moment uit het schema gehaald", icon: "calendar.badge.minus")
        }
    }

    // MARK: - Vervanging (fase36)

    /// De buddy die dit moment heeft opgepakt vraagt vervanging. Het hele team
    /// (incl. hulpvrager en familie) krijgt hier push + inbox-bericht van.
    func requestVisitSwap(teamId: UUID, visitId: UUID, reason: String = "") {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().requestVisitSwap(visitId: visitId, reason: reason)
                    await CareTeamService().notifyTeamEvent(teamId: teamId, event: "swap_request", visitId: visitId)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Vervanging gevraagd, je team krijgt bericht", icon: "arrow.triangle.2.circlepath") }
                } catch {
                    await MainActor.run { self.showToast(text: "Vervanging vragen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }),
                  let vi = careTeams[ti].visits.firstIndex(where: { $0.id == visitId }) {
            careTeams[ti].visits[vi].swapRequested = true
            careTeams[ti].visits[vi].swapReason = reason
            showToast(text: "Vervanging gevraagd, je team krijgt bericht", icon: "arrow.triangle.2.circlepath")
        }
    }

    /// De buddy doet het moment toch zelf: vervangingsverzoek intrekken.
    func withdrawVisitSwap(teamId: UUID, visitId: UUID) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await CareTeamService().withdrawVisitSwap(visitId: visitId)
                await self.loadCareTeams()
                await MainActor.run { self.showToast(text: "Fijn, je doet dit moment toch zelf", icon: "checkmark.circle.fill") }
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }),
                  let vi = careTeams[ti].visits.firstIndex(where: { $0.id == visitId }) {
            careTeams[ti].visits[vi].swapRequested = false
            careTeams[ti].visits[vi].swapReason = ""
            showToast(text: "Fijn, je doet dit moment toch zelf", icon: "checkmark.circle.fill")
        }
    }

    /// Een ander teamlid biedt vervanging aan en neemt het moment over.
    func takeOverVisit(teamId: UUID, visitId: UUID) {
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await CareTeamService().takeOverVisit(visitId: visitId)
                    await CareTeamService().notifyTeamEvent(teamId: teamId, event: "swap_taken", visitId: visitId)
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Top! Jij neemt dit moment over", icon: "checkmark.circle.fill") }
                } catch {
                    await self.loadCareTeams()
                    await MainActor.run { self.showToast(text: "Overnemen mislukt, misschien al geregeld", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else if let ti = careTeams.firstIndex(where: { $0.id == teamId }),
                  let vi = careTeams[ti].visits.firstIndex(where: { $0.id == visitId }) {
            careTeams[ti].visits[vi].claimedByBuddyId = buddyUser.id
            careTeams[ti].visits[vi].claimedByName = buddyUser.firstName
            careTeams[ti].visits[vi].swapRequested = false
            showToast(text: "Top! Jij neemt dit moment over", icon: "checkmark.circle.fill")
        }
    }

    // MARK: - Teamchat (fase36)

    /// Sleutel voor de demo-opslag van een teamchat-kanaal.
    private func teamChatKey(teamId: UUID, channel: TeamChatChannel) -> String {
        "teamchat.\(teamId.uuidString).\(channel.rawValue)"
    }

    /// Laadt de berichten van één kanaal. Live: Supabase; demo: lokaal.
    func loadTeamChat(teamId: UUID, channel: TeamChatChannel) async -> [TeamChatMessage] {
        if isLive {
            let me = realUserId
            guard let rows = try? await CareTeamService()
                .fetchTeamMessages(teamId: teamId, channel: channel.rawValue) else { return [] }
            return rows.map {
                TeamChatMessage(id: $0.id, senderId: $0.senderId,
                                senderName: $0.senderName, body: $0.body,
                                date: Self.parseISO($0.createdAt) ?? Date(),
                                isMine: me != nil && $0.senderId == me)
            }
        } else {
            let key = teamChatKey(teamId: teamId, channel: channel)
            if demoConversations[key] == nil {
                let starter = channel == .buddies
                    ? "Hoi team! Hier stemmen we onderling af wie wanneer gaat."
                    : "Welkom in de teamchat! Hier overleggen we samen met de familie."
                demoConversations[key] = [
                    ChatMessage(id: UUID(), isMine: false, body: starter,
                                date: Date().addingTimeInterval(-3600))
                ]
            }
            return (demoConversations[key] ?? []).map {
                TeamChatMessage(id: $0.id, senderId: nil,
                                senderName: $0.isMine ? "Jij" : "Sanne",
                                body: $0.body, date: $0.date, isMine: $0.isMine)
            }
        }
    }

    /// Verstuurt een teamchat-bericht en geeft het bijgewerkte gesprek terug.
    /// Live: RPC + notify-team-event (push/inbox voor de rest van het team).
    @discardableResult
    func sendTeamChat(teamId: UUID, channel: TeamChatChannel, body: String) async -> [TeamChatMessage] {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return await loadTeamChat(teamId: teamId, channel: channel)
        }
        if isLive {
            do {
                _ = try await CareTeamService().sendTeamMessage(
                    teamId: teamId, channel: channel.rawValue, body: trimmed)
                await CareTeamService().notifyTeamEvent(
                    teamId: teamId, event: "chat",
                    channel: channel.rawValue, text: trimmed)
            } catch {
                await MainActor.run { self.showToast(text: "Versturen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
            }
            return await loadTeamChat(teamId: teamId, channel: channel)
        } else {
            let key = teamChatKey(teamId: teamId, channel: channel)
            var list = demoConversations[key] ?? []
            list.append(ChatMessage(id: UUID(), isMine: true, body: trimmed, date: Date()))
            demoConversations[key] = list
            return await loadTeamChat(teamId: teamId, channel: channel)
        }
    }
}
