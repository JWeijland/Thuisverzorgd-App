//  AppState+Demo.swift
//  Onderdeel van AppState — Demo-data, prijzenladder & SOS.
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    // MARK: - Demo-data (alleen in demo-modus)

    /// Vult de app met voorbeelddata zodat de demo er gevuld uitziet. Wordt
    /// automatisch aangeroepen zodra `isDemoMode` op true gaat. In live-modus
    /// wordt dit nooit aangeroepen — daar bouwt iedereen z'n eigen data op.
    func loadDemoData() {
        openTasks         = MockData.openTasks
        taskHistory       = MockData.completedTasks
        allBuddies        = MockData.allBuddies
        favoriteBuddyNames = ["Aiyla", "Mark"]
        buddyFans         = ["Riet"]
        allMemberships    = MockData.sampleMemberships
        partnerCodes      = MockData.samplePartnerCodes

        // Gamification-demo: competities + teams + één voorbeeld-join-verzoek in de
        // inbox, zodat de hele goedkeuringsflow zonder backend te demonstreren is.
        let pts = buddyUser.totalTasks * 40
        competitions = GameData.competitions(currentName: buddyUser.firstName,
                                             avatar: buddyUser.avatarSystemName, points: pts)
        teams = GameData.teams(currentName: buddyUser.firstName,
                               avatar: buddyUser.avatarSystemName, points: pts)
        careTeams = CareTeamData.demoTeams(currentName: buddyUser.firstName, currentId: buddyUser.id)
        // Zorgkring-pivot: een kring in de buurt (nog niet vol) + een open
        // uitnodiging, zodat "Teams in de buurt" en de uitnodigingsflow te zien zijn.
        let nearbyTeam = CareTeam(id: UUID(), name: "Team Willem", elderlyName: "Willem",
                                  tint: Palette.purple, status: .live, minSize: 2, maxSize: 5,
                                  area: "Noord", helpSummary: "Wandelen en een praatje",
                                  members: [
                                    PoolMember(name: "Kees", avatar: "person.crop.circle.fill", points: 120, buddyId: UUID()),
                                    PoolMember(name: "Nadia", avatar: "person.crop.circle.fill", points: 90, buddyId: UUID()),
                                  ])
        careTeams.append(nearbyTeam)
        teamInvites = [
            TeamInvite(id: UUID(), careTeamId: nearbyTeam.id, elderlyName: "Willem",
                       area: "Noord", helpSummary: "Wandelen en een praatje",
                       isFavorite: false, status: "pending", sentAt: Date().addingTimeInterval(-120))
        ]
        teamPrizes = AppState.defaultTeamPrizes
        inbox = [
            InboxMessage(id: UUID(), kind: .elderlyMessage,
                         title: "Nieuw bericht van Riet",
                         body: "Zou je morgen wat later kunnen komen?",
                         teamId: nil, requestId: nil,
                         senderName: "Riet",
                         read: false, date: Date().addingTimeInterval(-600)),
            InboxMessage(id: UUID(), kind: .newTaskNearby,
                         title: "Nieuwe hulpvraag bij jou in de buurt",
                         body: openTasks.first.map { "\($0.category.displayName) bij \($0.elderlyName)" }
                               ?? "Tik om te bekijken en aan te nemen.",
                         teamId: nil, requestId: nil,
                         taskId: openTasks.first?.id,
                         read: false, date: Date().addingTimeInterval(-300)),
            InboxMessage(id: UUID(), kind: .teamJoinRequest,
                         title: "Sara wil bij \(teams.first?.name ?? "je team") komen",
                         body: "Tik om goed te keuren of af te wijzen.",
                         teamId: teams.first?.id, requestId: UUID(),
                         read: false, date: Date())
        ]
    }

    /// Verwijdert de demo-voorbeelddata weer (bij uitloggen / terug naar live).
    func clearDemoSeedData() {
        openTasks = []
        taskHistory = []
        allBuddies = []
        favoriteBuddyNames = []
        buddyFans = []
        allMemberships = []
        partnerCodes = []
        competitions = []
        teams = []
        careTeams = []
        teamInvites = []
        careJoinRequests = []
        pendingTeamProposal = nil
        teamPrizes = []
        inbox = []
    }

    /// Standaard prijzenladder (demo + terugval als de DB nog leeg is). Spiegelt
    /// de seed in supabase/migrations/fase20_prize_catalog.sql.
    static let defaultTeamPrizes: [DBTeamPrize] = [
        DBTeamPrize(id: UUID(), pointsThreshold: 1000, title: "Bioscoopbon voor het team",  icon: "popcorn.fill"),
        DBTeamPrize(id: UUID(), pointsThreshold: 1500, title: "High tea met het team",      icon: "cup.and.saucer.fill"),
        DBTeamPrize(id: UUID(), pointsThreshold: 2000, title: "Uit eten met het team",      icon: "fork.knife"),
        DBTeamPrize(id: UUID(), pointsThreshold: 3000, title: "Weekendje weg met het team", icon: "suitcase.fill"),
    ]

    func activateCordaanDemo(role: UserRole) {
        let org = MockData.cordaan
        selectedOrganization = org
        organizationName = org.name
        let name = role == .buddy ? "Demo Buddy (via organisatie)" : "Demo Cliënt (via partner)"
        let membership = OrganizationMembership(
            id: UUID(),
            userId: UUID(),
            userName: name,
            userRole: role,
            organizationId: org.id,
            status: .approved,
            proofNote: "Demo, automatisch goedgekeurd",
            submittedAt: Date(),
            reviewedAt: Date()
        )
        currentUserMembership = membership
        isDemoMode = true
        isOnboardingComplete = true
        hasSeenSplash = true
        elderlyHasLinkingCode = true   // demo: koppelcode-gate overslaan
        currentRole = role
    }

    // MARK: - SOS

    func triggerSOS() {
        showSOS = true
        // Live: leg de SOS-melding vast in Supabase (sos_events).
        if isLive, let id = realUserId {
            Task { try? await TaskService().logSOS(elderlyId: id) }
        }
        MockSMSService().sendSMS(
            to: "06-00000000",
            message: BuddieNotification.sosTriggered(elderlyName: elderlyUser.firstName).title
        )
        MockPushService().send(notification: .sosTriggered(elderlyName: elderlyUser.firstName))
    }
}
