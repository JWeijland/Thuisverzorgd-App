//  AppState+Lifecycle.swift
//  Onderdeel van AppState — Initialisatie, auth, privacy-reset, uitloggen & navigatie.
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    // MARK: - Initialization (called on app start)

    func initialize() async {
        await authService.restoreSession()
        if let userId = authService.currentUserId {
            await handleAuthSuccess(userId: userId)
        } else {
            // Geen actieve sessie → toon de echte login (Supabase), niet het
            // mock-rolscherm. Zo draait de app op echte data zodra je inlogt.
            showLogin = true
        }
        isInitializing = false
    }

    // MARK: - Auth success handler

    func handleAuthSuccess(userId: UUID, role: UserRole? = nil) async {
        // Begin met een schone lei: wis eventuele resten van een vorig account
        // (profielfoto, reviews, favorieten, …) vóórdat we het nieuwe profiel laden.
        // Cruciaal als op hetzelfde apparaat van account wordt gewisseld.
        await MainActor.run { resetUserScopedState() }
        realUserId = userId

        // Haal altijd het echte profiel op — zowel om de rol te bepalen (bij
        // sessieherstel) als om de UI met de echte naam/locatie te vullen.
        let profile = try? await profileService.fetchProfile(userId: userId)

        if let role = role {
            currentRole = role
        } else {
            guard let profile else {
                // Profiel nog niet beschikbaar — gebruiker blijft op het authscherm.
                return
            }
            switch profile.role {
            case "elderly": currentRole = .elderly
            case "buddy":   currentRole = .buddy
            case "family":  currentRole = .family
            case "admin":   currentRole = .admin
            default: break
            }
        }

        // Organisatie-herkomst onthouden (uit het profiel), zodat de naam van de
        // organisatie op het profiel getoond kan worden. De huisstijl verandert
        // hier bewust niet door: iedereen krijgt de Thuisverzorgd-stijl.
        setOrganization(key: profile?.organizationKey)

        // Echte naam/locatie in de UI laden (zie AppStateLive.swift).
        if let profile { await applyRealProfile(profile) }

        // Pushnotificaties: registreren bij APNs en het device token koppelen
        // aan deze gebruiker + rol (zie PushManager.swift).
        if let roleString = currentRole?.rawValue {
            await PushManager.shared.setUser(userId: userId, role: roleString)
            PushManager.shared.registerForPushNotifications()
        }

        // Koppelcode-gate voorlopig uitgeschakeld: cliënten komen altijd direct
        // in de app. (De per-gebruiker onthouden gate-vlag blijft in UserDefaults
        // staan voor als de gate later weer aan gaat.)
        if currentRole == .elderly {
            elderlyHasLinkingCode = true
        }

        showLogin = false
        // hasSeenSplash niet hier zetten — de SplashView beheert die vlag,
        // anders verdwijnt de openingsanimatie meteen bij sessieherstel.
        isOnboardingComplete = true
    }

    // MARK: - Koppelcode-gate onthouden (per gebruiker)

    static func linkingCodeGateKey(_ userId: UUID) -> String {
        "elderlyLinkingCodeGatePassed_\(userId.uuidString)"
    }

    /// Markeert dat deze cliënt de koppelcode-gate is doorlopen (code ingewisseld of
    /// bewust zonder code verder). Per gebruiker bewaard zodat hij/zij bij een volgende
    /// start meteen op de hoofdpagina komt en het koppelscherm niet opnieuw ziet.
    func passElderlyLinkingCodeGate() {
        elderlyHasLinkingCode = true
        if let id = realUserId {
            UserDefaults.standard.set(true, forKey: Self.linkingCodeGateKey(id))
        }
    }

    // MARK: - "Hoe het werkt"-rondleiding onthouden (per gebruiker + rol, punt 9)

    static func walkthroughKey(_ role: UserRole, userId: UUID?) -> String {
        "walkthroughSeen_\(role.rawValue)_\(userId?.uuidString ?? "local")"
    }

    /// Is de rondleiding voor deze rol al een keer getoond?
    func hasSeenWalkthrough(_ role: UserRole) -> Bool {
        UserDefaults.standard.bool(forKey: Self.walkthroughKey(role, userId: realUserId))
    }

    /// Markeert de rondleiding als gezien (verschijnt daarna niet meer automatisch).
    func markWalkthroughSeen(_ role: UserRole) {
        UserDefaults.standard.set(true, forKey: Self.walkthroughKey(role, userId: realUserId))
        walkthroughReplay = nil
    }

    /// Roept de rondleiding opnieuw op vanuit het profiel.
    func replayWalkthrough(_ role: UserRole) { walkthroughReplay = role }

    // MARK: - Privacy: alle gebruikersgebonden gegevens wissen

    /// Zet ÁLLE gegevens die bij één gebruiker horen terug naar lege standaard-
    /// waarden. Dit is de centrale privacy-waarborg: het voorkomt dat data van een
    /// vorige (uitgelogde) gebruiker — naam, profielfoto, reviews, favorieten,
    /// geschiedenis, toestemming — zichtbaar blijft of bij een ander account
    /// terechtkomt. Wordt aangeroepen bij uitloggen én vóór het laden van een
    /// nieuw profiel, zodat er geen enkel restje van het vorige account overblijft.
    ///
    /// Moet op de main-thread draaien (muteert observable UI-state).
    @MainActor
    func resetUserScopedState() {
        // Identiteit / rol
        realUserId = nil
        currentRole = nil

        // Profielen → neutrale placeholders (nooit MockData of een ander account).
        elderlyUser = AppState.placeholderElderly
        buddyUser = AppState.placeholderBuddy
        familyUser = AppState.placeholderFamily
        allElderlyUsers = []
        familyLinkedElderly = []
        activeFamilyElderlyIndex = 0

        // Taken & matching
        openTasks = []
        activeTaskForElderly = nil
        activeTaskForBuddy = nil
        buddyCancelledNotice = nil
        buddyLiveLatitude = nil
        buddyLiveLongitude = nil
        buddyRouteProgress = 0
        buddyRouteStartKm = nil
        taskHistory = []
        allBuddies = []
        lastMatches = []

        // Reviews / favorieten / beoordelingen
        buddyReviews = []
        elderlyReviews = []
        pendingNewReview = nil

        // Teams, competities, prijzen & berichten-inbox (gamification)
        competitions = []
        teams = []
        careTeams = []
        teamPrizes = []
        inbox = []
        inboxDestination = nil
        demoConversations = [:]
        walkthroughReplay = nil
        favoriteBuddyNames = []
        buddyFans = []
        taskRatings = [:]
        skippedReviews = []

        // Intake / admin-lijsten
        myIntakeCall = nil
        myScheduledCall = nil
        intakeQueuePosition = 0
        intakeQueueTotal = 0
        waitingCalls = []
        scheduledCalls = []
        allUsers = []
        pendingVOGs = []

        // Organisatie / koppelcodes
        currentUserMembership = nil
        allMemberships = []
        partnerCodes = []
        elderlyHasLinkingCode = true   // gate voorlopig uit
        selectedOrganization = nil
        pendingRole = nil
        myLinkingCode = nil

        // Toestemming (privacy) — per account opnieuw ophalen/vragen.
        consentDecided = false
        consentProductAnalytics = false
        consentResearchInsights = false

        // Voorkeuren — zonder terug te schrijven naar de DB.
        suppressPreferenceWrite = true
        largeTextEnabled = false
        prefersFormal = true
        suppressPreferenceWrite = false

        suppressAvailabilityWrite = true
        isAvailableNow = false
        suppressAvailabilityWrite = false

        // Live locatie niet langer volgen na uitloggen.
        stopBuddyLocationTracking()

        // Profielfoto uit het geheugen wissen (per-gebruiker cache op schijf blijft,
        // maar wordt nooit aan een ander getoond — sleutel bevat de user-UUID).
        AvatarStore.shared.clearForSignOut()
        // Signed foto-URL's van anderen (kaart-druppels) horen niet mee te
        // reizen naar een volgend account.
        BuddyPhotoCache.shared.clearForSignOut()
    }

    // MARK: - Sign out

    func signOut() async {
        stopBuddyTaskSync()
        stopElderlyTaskSync()
        stopBuddyLiveLocationSync()
        stopInboxSync()
        await PushManager.shared.clearOnSignOut()
        try? await authService.signOut()
        // Wis álle gebruikersgegevens (profielfoto, reviews, favorieten, …).
        await MainActor.run { resetUserScopedState() }
        hasSeenSplash = true       // splash niet opnieuw afspelen na uitloggen
        isDemoMode = false
        showLogin = true           // terug naar de echte login, niet het mock-rolscherm
        isOnboardingComplete = false
        organizationName = nil
    }

    // MARK: - Navigation

    func resetToRoleSelection() {
        currentRole = nil
        activeTaskForElderly = nil
        activeTaskForBuddy = nil
        showSOS = false
        // Organisatie-staat opschonen zodat een volgende rolkeuze schoon start
        // (anders blijft een eerdere Cordaan-flow de onboarding beïnvloeden).
        currentUserMembership = nil
        selectedOrganization = nil
        pendingRole = nil
        isDemoMode = false
        elderlyHasLinkingCode = true   // gate voorlopig uit
        organizationName = nil
    }
}
