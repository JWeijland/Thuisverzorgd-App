//  AppStateLive+Teams.swift
//  Live-laag van AppState — teams, competities, inbox & prijzenladder.
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

extension AppState {

    // MARK: - Teams & berichten-inbox (fase18)

    // MARK: Mapping DB → app-model

    static func team(from db: DBTeam, currentUserId: UUID?) -> Team {
        let members = db.members.map { m -> PoolMember in
            let isMe = currentUserId != nil && m.buddyId == currentUserId
            return PoolMember(
                name: m.profile?.firstName ?? "Buddy",
                avatar: "person.crop.circle.fill",
                points: m.points,
                isCurrentUser: isMe
            )
        }
        let mine = currentUserId != nil && db.members.contains { $0.buddyId == currentUserId }
        return Team(
            id: db.id,
            name: db.name,
            icon: (db.icon?.isEmpty == false) ? db.icon! : "person.3.fill",
            tint: Palette.tint(forKey: db.accent),
            members: members,
            outingTarget: db.outingTarget,
            prizeTitle: db.prizeTitle ?? "",
            isMyTeam: mine
        )
    }

    static func inboxMessage(from db: DBNotification) -> InboxMessage {
        InboxMessage(
            id: db.id,
            kind: InboxMessage.Kind(raw: db.kind),
            title: db.title,
            body: db.body,
            teamId: db.teamId,
            requestId: db.requestId,
            senderId: db.senderId,
            senderName: db.senderName,
            taskId: db.taskId,
            careTeamId: db.careTeamId,
            read: db.read,
            date: parseISO(db.createdAt) ?? Date()
        )
    }

    static func competition(from db: DBCompetition, currentUserId: UUID?) -> Competition {
        let status: CompetitionStatus
        switch db.status {
        case "loopt":     status = .loopt
        case "afgelopen": status = .afgelopen
        default:          status = .inschrijving
        }

        let members = db.participants.map { p -> PoolMember in
            let isMe = currentUserId != nil && p.buddyId == currentUserId
            return PoolMember(name: p.profile?.firstName ?? "Buddy",
                              avatar: "person.crop.circle.fill",
                              points: p.points, isCurrentUser: isMe)
        }

        // Prijzen uit prize_1/2/3_title; nr.1 krijgt het trofee-icoon.
        var prizes: [CompetitionPrize] = []
        for (rank, title) in [db.prize1Title, db.prize2Title, db.prize3Title].enumerated() {
            if let t = title, !t.isEmpty {
                prizes.append(CompetitionPrize(rank: rank + 1, title: t,
                                               icon: rank == 0 ? "trophy.fill" : "gift.fill"))
            }
        }

        let deadline = parseISO(db.registrationDeadline ?? "") ?? Date()
        let weeksRemaining: Int = {
            guard let endsAt = parseISO(db.endsAt ?? "") else { return 0 }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: endsAt).day ?? 0
            return max(0, Int(ceil(Double(days) / 7.0)))
        }()
        let registered = currentUserId != nil && db.participants.contains { $0.buddyId == currentUserId }

        return Competition(
            id: db.id,
            name: db.name,
            tagline: db.tagline ?? "",
            icon: (db.icon?.isEmpty == false) ? db.icon! : "trophy.fill",
            tint: competitionTint(db.accent),
            status: status,
            deadline: deadline,
            durationWeeks: db.durationWeeks ?? 0,
            weeksRemaining: weeksRemaining,
            minParticipants: db.minParticipants,
            maxParticipants: db.maxParticipants,
            participantCount: db.participants.count,
            prizes: prizes,
            members: members,
            isRegistered: registered
        )
    }

    /// Accent kan een palet-sleutel ("purple") of een hex ("#7B45C7"/"7B45C7") zijn.
    static func competitionTint(_ accent: String?) -> [Color] {
        guard let a = accent, !a.isEmpty else { return Palette.purple }
        if let keyed = Palette.byKey[a] { return keyed }
        let hex = a.hasPrefix("#") ? String(a.dropFirst()) : a
        if let v = UInt32(hex, radix: 16) { let c = Color(hex: v); return [c, c] }
        return Palette.purple
    }

    // MARK: Laden

    func loadTeams() async {
        guard isLive, let me = realUserId else { return }
        guard let rows = try? await TeamService().fetchTeams() else { return }
        let pending = (try? await TeamService().fetchMyPendingRequests(buddyId: me)) ?? []
        let pendingTeamIds = Set(pending.map { $0.teamId })
        let mapped = rows.map { row -> Team in
            var t = Self.team(from: row, currentUserId: me)
            t.pendingJoin = pendingTeamIds.contains(row.id)
            return t
        }
        await MainActor.run { self.teams = mapped }
    }

    func loadInbox() async {
        guard isLive else { return }
        guard let rows = try? await NotificationService().fetchInbox() else { return }
        let mapped = rows.map { Self.inboxMessage(from: $0) }
        await MainActor.run { self.inbox = mapped }
    }

    func loadCompetitions() async {
        guard isLive else { return }
        guard let rows = try? await CompetitionService().fetchCompetitions() else { return }
        let me = realUserId
        let mapped = rows.map { Self.competition(from: $0, currentUserId: me) }
        await MainActor.run { self.competitions = mapped }
    }

    func loadTeamPrizes() async {
        guard isLive else { return }
        guard let rows = try? await PrizeService().fetchTeamPrizes() else { return }
        await MainActor.run { self.teamPrizes = rows }
    }

    /// Periodieke poll (10s) voor inbox + teams (vergelijkbaar met de taken-poll).
    func startInboxSync() {
        guard isLive, inboxPollTask == nil else { return }
        inboxPollTask = Task { [weak self] in
            guard let self else { return }
            // Prijzenladder hoeft niet elke ronde; eenmalig bij de start volstaat.
            await self.loadTeamPrizes()
            while !Task.isCancelled {
                await self.loadInbox()
                await self.loadTeams()
                await self.loadCareTeams()
                await self.loadTeamInvites()
                await self.loadCareJoinRequests()
                await self.loadCompetitions()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    func stopInboxSync() {
        inboxPollTask?.cancel()
        inboxPollTask = nil
    }

    // MARK: Acties (schakelen live ↔ demo)

    /// De prijs die bij een puntendoel hoort, afgeleid uit de (admin-)ladder.
    /// Hoogste tier waarvan de drempel binnen het doel valt.
    func prizeTitle(forTarget target: Int) -> String {
        teamPrizes.filter { $0.pointsThreshold <= target }
            .max(by: { $0.pointsThreshold < $1.pointsThreshold })?.title ?? ""
    }

    /// Maakt een team aan. `paletteKey` is een sleutel uit `Palette` (bijv. "amber").
    /// De prijs wordt niet door de gebruiker gekozen maar afgeleid uit het doel.
    func createTeam(name: String, icon: String, paletteKey: String, outingTarget: Int = 2000) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await TeamService().createTeam(
                        name: trimmed, icon: icon, accent: paletteKey, outingTarget: outingTarget
                    )
                    await self.loadTeams()
                    await MainActor.run { self.showToast(text: "Team \(trimmed) aangemaakt", icon: "person.3.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Aanmaken mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                    print("[Live] createTeam faalde: \(error)")
                }
            }
        } else {
            let me = PoolMember(name: buddyUser.firstName, avatar: buddyUser.avatarSystemName,
                                points: 0, isCurrentUser: true)
            for i in teams.indices { teams[i].isMyTeam = false }
            let team = Team(name: trimmed, icon: icon, tint: Palette.tint(forKey: paletteKey),
                            members: [me], outingTarget: outingTarget,
                            prizeTitle: prizeTitle(forTarget: outingTarget), isMyTeam: true)
            teams.insert(team, at: 0)
            showToast(text: "Team \(trimmed) aangemaakt", icon: "person.3.fill")
        }
    }

    /// Stuurt een join-verzoek voor een team (de eigenaar moet goedkeuren).
    func requestToJoinTeam(_ team: Team) {
        if isLive {
            let teamId = team.id
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await TeamService().requestToJoin(teamId: teamId)
                    await self.loadTeams()
                    await MainActor.run { self.showToast(text: "Verzoek verstuurd. Je hoort het zodra je bent toegelaten", icon: "paperplane.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Verzoek mislukt, misschien al verstuurd?", icon: "exclamationmark.triangle.fill") }
                    print("[Live] requestToJoin faalde: \(error)")
                }
            }
        } else {
            if let idx = teams.firstIndex(where: { $0.id == team.id }) { teams[idx].pendingJoin = true }
            showToast(text: "Verzoek verstuurd (demo)", icon: "paperplane.fill")
        }
    }

    func approveJoinRequest(_ msg: InboxMessage) {
        guard let reqId = msg.requestId else { return }
        markInboxRead(msg.id)
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await TeamService().approve(requestId: reqId)
                    await self.loadInbox()
                    await self.loadTeams()
                    await MainActor.run { self.showToast(text: "Toegelaten tot je team", icon: "checkmark.seal.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Goedkeuren mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                    print("[Live] approve faalde: \(error)")
                }
            }
        } else {
            showToast(text: "Goedgekeurd (demo)", icon: "checkmark.seal.fill")
        }
    }

    func rejectJoinRequest(_ msg: InboxMessage) {
        guard let reqId = msg.requestId else { return }
        markInboxRead(msg.id)
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await TeamService().reject(requestId: reqId)
                    await self.loadInbox()
                    await MainActor.run { self.showToast(text: "Verzoek afgewezen", icon: "xmark.circle.fill") }
                } catch {
                    await MainActor.run { self.showToast(text: "Afwijzen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                    print("[Live] reject faalde: \(error)")
                }
            }
        } else {
            showToast(text: "Afgewezen (demo)", icon: "xmark.circle.fill")
        }
    }

    // MARK: Competitie in-/uitschrijven

    /// Schrijft de buddy in (of uit) bij een competitie. Je kunt aan max. 1
    /// actieve competitie meedoen; bij inschrijven wordt een eventuele andere
    /// actieve inschrijving eerst opgezegd (de DB-trigger bewaakt dit ook).
    func setCompetitionRegistered(_ id: UUID, _ registered: Bool) {
        if isLive {
            guard let buddyId = realUserId else { return }
            // Andere actieve inschrijving die we moeten opzeggen vóór we inschrijven.
            let othersActive = registered
                ? competitions.filter { $0.id != id && $0.isRegistered && $0.status != .afgelopen }.map { $0.id }
                : []
            Task { [weak self] in
                guard let self else { return }
                do {
                    for otherId in othersActive {
                        try? await CompetitionService().unregister(competitionId: otherId, buddyId: buddyId)
                    }
                    if registered {
                        try await CompetitionService().register(competitionId: id, buddyId: buddyId)
                    } else {
                        try await CompetitionService().unregister(competitionId: id, buddyId: buddyId)
                    }
                    await self.loadCompetitions()
                } catch {
                    await MainActor.run { self.showToast(text: "Inschrijven mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
                    print("[Live] competitie in-/uitschrijven faalde: \(error)")
                }
            }
        } else {
            for i in competitions.indices {
                if competitions[i].id == id { competitions[i].isRegistered = registered }
                else if registered, competitions[i].status != .afgelopen { competitions[i].isRegistered = false }
            }
        }
    }

    // MARK: Admin — team-prijzenladder beheren

    func adminLoadTeamPrizes() {
        if isLive {
            Task { [weak self] in await self?.loadTeamPrizes() }
        } else if teamPrizes.isEmpty {
            teamPrizes = AppState.defaultTeamPrizes
        }
    }

    func adminAddTeamPrize(threshold: Int, title: String, icon: String) {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard threshold > 0, !t.isEmpty else { return }
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await PrizeService().createTeamPrize(threshold: threshold, title: t, icon: icon)
                    await self.loadTeamPrizes()
                } catch {
                    await MainActor.run { self.showToast(text: "Opslaan mislukt, bestaat dit doel al?", icon: "exclamationmark.triangle.fill") }
                }
            }
        } else {
            teamPrizes.removeAll { $0.pointsThreshold == threshold }
            teamPrizes.append(DBTeamPrize(id: UUID(), pointsThreshold: threshold, title: t, icon: icon))
            teamPrizes.sort { $0.pointsThreshold < $1.pointsThreshold }
        }
    }

    func adminUpdateTeamPrize(id: UUID, threshold: Int, title: String, icon: String) {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard threshold > 0, !t.isEmpty else { return }
        if isLive {
            Task { [weak self] in
                guard let self else { return }
                try? await PrizeService().updateTeamPrize(id: id, threshold: threshold, title: t, icon: icon)
                await self.loadTeamPrizes()
            }
        } else if let idx = teamPrizes.firstIndex(where: { $0.id == id }) {
            teamPrizes[idx] = DBTeamPrize(id: id, pointsThreshold: threshold, title: t, icon: icon)
            teamPrizes.sort { $0.pointsThreshold < $1.pointsThreshold }
        }
    }

    func adminDeleteTeamPrize(id: UUID) {
        teamPrizes.removeAll { $0.id == id }
        if isLive { Task { try? await PrizeService().deleteTeamPrize(id: id) } }
    }

    // MARK: Inbox-status

    func markInboxRead(_ id: UUID) {
        if let idx = inbox.firstIndex(where: { $0.id == id }), !inbox[idx].read {
            inbox[idx].read = true
        }
        if isLive { Task { try? await NotificationService().markRead(id: id) } }
    }

    func markAllInboxRead() {
        for i in inbox.indices where !inbox[i].read { inbox[i].read = true }
        if isLive, let uid = realUserId {
            Task { try? await NotificationService().markAllRead(userId: uid) }
        }
    }

    func deleteInboxMessage(_ id: UUID) {
        inbox.removeAll { $0.id == id }
        if isLive { Task { try? await NotificationService().delete(id: id) } }
    }
}
