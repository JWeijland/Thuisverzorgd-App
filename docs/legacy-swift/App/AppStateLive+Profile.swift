//  AppStateLive+Profile.swift
//  Live-laag van AppState — profiel-, koppelcode- & reviews-laden na login.
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

extension AppState {

    // MARK: Echte profielgegevens laden na login

    /// Vult elderlyUser/buddyUser/familyUser met de echte naam (en, indien
    /// aanwezig, locatie) van de ingelogde gebruiker. Valt terug op nette
    /// defaults zodat een vers account zonder profielinhoud blijft werken.
    /// Bouwt een ElderlyUser uit de RPC-DTO (gekoppelde oudere).
    func elderlyUser(from dto: TaskService.LinkedElderlyDTO) -> ElderlyUser {
        let coord = (dto.latitude != nil && dto.longitude != nil)
            ? CLLocationCoordinate2D(latitude: dto.latitude!, longitude: dto.longitude!)
            : MockData.amsterdamCenter
        let dob = Calendar.current.date(from: DateComponents(year: 1945, month: 1, day: 1)) ?? Date()
        return ElderlyUser(
            id: dto.id,
            firstName: dto.firstName,
            lastName: dto.lastName,
            address: dto.address ?? "",
            coordinate: coord,
            dateOfBirth: dob,
            phoneNumber: nil,
            favoriteBuddyIDs: [],
            familyMemberIDs: []
        )
    }

    /// Oudere: haal (of maak) mijn deelbare koppelcode op (live).
    func loadMyLinkingCode() async {
        guard isLive, currentRole == .elderly else { return }
        if let code = try? await TaskService().ensureMyLinkingCode() {
            await MainActor.run { self.myLinkingCode = code }
        }
    }

    /// Oudere wisselt LIVE een partner-koppelcode in (gemeente/verzekeraar/werkgever).
    /// Geeft de partnernaam terug bij succes, anders nil.
    func redeemPartnerCodeLive(_ raw: String) async -> String? {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty,
              let pc = try? await TaskService().validatePartnerCode(code: code) else { return nil }
        try? await TaskService().incrementPartnerCodeUsage(id: pc.id, currentCount: pc.usedCount)
        await MainActor.run { self.passElderlyLinkingCodeGate() }
        return pc.partnerName
    }

    /// Familie wisselt LIVE een koppelcode in. Geeft de voornaam terug, of nil.
    func linkElderlyLive(code: String) async -> String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dto = try? await TaskService().redeemLinkingCode(code: trimmed) else { return nil }
        let elderly = elderlyUser(from: dto)
        await MainActor.run {
            if !self.familyLinkedElderly.contains(where: { $0.id == elderly.id }) {
                self.familyLinkedElderly.append(elderly)
            }
            self.activeFamilyElderlyIndex = max(0, self.familyLinkedElderly.count - 1)
        }
        return elderly.firstName
    }

    func applyRealProfile(_ profile: DBProfile) async {
        let id = profile.id
        let defaultDOB = Calendar.current.date(from: DateComponents(year: 1945, month: 1, day: 1)) ?? Date()

        switch profile.role {
        case "elderly":
            var coordinate = MockData.amsterdamCenter
            var address = ""
            var largeText = false
            var prefersFormal = true
            var birthYear: Int? = nil
            var dob: Date = defaultDOB
            var ratingAverage: Double = 0
            var showsPhone = false
            var showsAddress = false
            var showsBirthDate = true
            var teamMode = "team"
            if let ep = try? await ProfileService().fetchElderlyProfile(userId: id) {
                if let lat = ep.latitude, let lon = ep.longitude {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                if let a = ep.address, !a.isEmpty { address = a }
                largeText = ep.largeTextEnabled ?? false
                prefersFormal = ep.prefersFormal ?? true
                birthYear = ep.birthYear
                ratingAverage = ep.ratingAverage ?? 0
                // Volledige geboortedatum (exacte leeftijd) als die bekend is.
                if let ds = ep.dateOfBirth, let d = BCBirthDate.date(from: ds) {
                    dob = d
                    birthYear = Calendar.current.component(.year, from: d)
                }
                showsPhone = ep.showsPhone ?? false
                showsAddress = ep.showsAddress ?? false
                showsBirthDate = ep.showsBirthdate ?? true
                teamMode = ep.teamMode ?? "team"
            }
            var user = ElderlyUser(
                id: id,
                firstName: profile.firstName,
                lastName: profile.lastName,
                address: address,
                coordinate: coordinate,
                dateOfBirth: dob,
                phoneNumber: profile.phoneNumber,
                favoriteBuddyIDs: [],
                familyMemberIDs: []
            )
            user.birthYear = birthYear
            user.ratingAverage = ratingAverage
            user.showsPhone = showsPhone
            user.showsAddress = showsAddress
            user.showsBirthDate = showsBirthDate
            // Favorieten + overgeslagen beoordelingen ophalen.
            let favorites = (try? await ProfileService().fetchFavorites(elderlyId: id)) ?? []
            let skipped = (try? await ProfileService().fetchSkippedReviews(reviewerId: id)) ?? []
            await MainActor.run {
                self.elderlyUser = user
                self.elderlyTeamMode = teamMode
                self.suppressPreferenceWrite = true
                self.largeTextEnabled = largeText
                self.prefersFormal = prefersFormal
                self.suppressPreferenceWrite = false
                self.favoriteBuddyNames = Set(favorites.map(\.buddyName))
                self.skippedReviews = Set(skipped)
                // Profielfoto strikt aan dít account koppelen (laadt de lokaal
                // bewaarde foto van déze cliënt, of leeg).
                AvatarStore.shared.configure(for: id)
            }
            // Op een nieuw apparaat staat er lokaal nog niets — herstel dan de eigen
            // foto uit Supabase. Pad is deterministisch (<uid>.jpg); faalt stil als
            // er (nog) geen foto is.
            await AvatarStore.shared.loadFromServerIfNeeded(buddyId: id, hasServerAvatar: true)
            // PRIVACY: de beoordelingen die buddies over deze cliënt schreven, laden
            // we hier BEWUST NIET — de hulpvrager mag ze nergens zien. Ze worden
            // alleen aan buddies getoond op het hulpverzoek (zie TaskDetailSheet).
            // Zorg-team rond deze cliënt laden (voor "Mijn team" + team-hulpvragen).
            await loadCareTeams()

        case "buddy":
            let bp = try? await ProfileService().fetchBuddyProfile(userId: id)
            let user = BuddyUser(
                id: id,
                firstName: profile.firstName,
                lastName: profile.lastName,
                avatarSystemName: "person.crop.circle.fill",
                ratingAverage: bp?.ratingAverage ?? 0,
                totalTasks: bp?.totalTasks ?? 0,
                bio: bp?.bio ?? "",
                study: bp?.study ?? "",
                vogValid: bp?.vogValid ?? false,
                vogExpiresAt: Date(),
                vogStatus: VOGStatus(rawValue: bp?.vogStatus ?? "") ?? .nietAangevraagd,
                vogDocumentUrl: bp?.vogDocumentUrl,
                intakeCompleted: bp?.intakeCompleted ?? false
            )
            await MainActor.run {
                var u = user
                u.preferredServices = Set(bp?.preferredServices ?? [])
                u.address = bp?.address ?? ""
                if let lat = bp?.latitude, let lon = bp?.longitude {
                    u.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                // Volledige geboortedatum (exacte leeftijd) + geboortejaar in sync.
                if let ds = bp?.dateOfBirth, let d = BCBirthDate.date(from: ds) {
                    u.dateOfBirth = d
                    u.birthYear = Calendar.current.component(.year, from: d)
                }
                u.showsBio = bp?.showsBio ?? true
                u.showsNeighborhood = bp?.showsNeighborhood ?? false
                u.showsBirthDate = bp?.showsBirthdate ?? true
                // Telefoonnummer (uit profiles) zodat de oudere de buddy kan bellen
                // tijdens een actieve hulpvraag (punt 2).
                u.phoneNumber = profile.phoneNumber
                self.buddyUser = u
                // Beschikbaarheid uit de DB overnemen zonder terug te schrijven.
                self.suppressAvailabilityWrite = true
                self.isAvailableNow = bp?.isAvailableNow ?? false
                self.suppressAvailabilityWrite = false
                // Profielfoto strikt aan dít account koppelen. configure() wist
                // eerst een eventuele foto van een vorige gebruiker en laadt
                // daarna alleen de lokaal bewaarde foto van déze buddy.
                AvatarStore.shared.configure(for: id)
            }
            // Op een nieuw apparaat staat er lokaal nog niets — herstel dan de
            // eigen foto uit Supabase (alleen als de server er een heeft).
            let hasServerAvatar = (bp?.avatarUrl?.isEmpty == false)
            await AvatarStore.shared.loadFromServerIfNeeded(buddyId: id, hasServerAvatar: hasServerAvatar)
            await loadBuddyReviews(buddyId: id)
            // Wie koos mij als vaste buddy? (voedt "Vaste buddy van …" op het profiel)
            let fans = (try? await ProfileService().fetchFans(buddyId: id)) ?? []
            await MainActor.run {
                self.buddyFans = fans.map { $0.elderlyName.isEmpty ? "Een hulpvrager" : $0.elderlyName }
            }
            // Live locatie bijhouden zodra de buddy beschikbaar is (500m-meldingen).
            await MainActor.run { self.startBuddyLocationTrackingIfNeeded() }

        case "family":
            let user = FamilyUser(
                id: id,
                firstName: profile.firstName,
                lastName: profile.lastName,
                relationship: "",
                linkedElderlyIDs: []
            )
            // Echte gekoppelde ouderen ophalen (via RPC my_linked_elderly).
            let linked = (try? await TaskService().myLinkedElderly()) ?? []
            let elderly = linked.map { self.elderlyUser(from: $0) }
            await MainActor.run {
                self.familyUser = user
                self.familyLinkedElderly = elderly
                self.activeFamilyElderlyIndex = 0
            }
            // Zorg-teams laden zodat het familielid namens de ouder ook het team
            // kan vragen (RequestHelpFlow toont dan de team-optie).
            await loadCareTeams()

        default:
            break
        }

        // Toestemmingskeuze terughalen zodat we 'm onthouden i.p.v. opnieuw vragen.
        await loadConsentFromSupabase(userId: id)
    }

    /// Haalt de echte beoordelingen op die over deze buddy zijn geschreven.
    func loadBuddyReviews(buddyId: UUID) async {
        guard let rows = try? await TaskService().fetchReviews(revieweeId: buddyId) else { return }
        let reviews = rows.map { row in
            Review(
                id: UUID(),
                stars: row.stars,
                body: row.body.isEmpty ? "Fijne buddy, bedankt!" : row.body,
                authorName: row.reviewer?.firstName ?? "Cliënt",
                date: AppState.parseISO(row.createdAt) ?? Date()
            )
        }
        await MainActor.run { self.buddyReviews = reviews }
    }

    /// Voor de BUDDY: haal de beoordelingen op die buddies over een hulpvrager
    /// hebben geschreven. Deze worden uitsluitend op het hulpverzoek (de kaart)
    /// getoond — de hulpvrager zelf ziet ze nooit. Geeft een lege lijst in
    /// demo-modus of als er niets te halen valt.
    func fetchElderlyReviewsForRequest(elderlyId: UUID) async -> [Review] {
        guard isLive else { return [] }
        guard let rows = try? await TaskService().fetchReviews(revieweeId: elderlyId) else { return [] }
        return rows.map { row in
            Review(
                id: UUID(),
                stars: row.stars,
                body: row.body,
                authorName: row.reviewer?.firstName ?? "Buddy",
                date: AppState.parseISO(row.createdAt) ?? Date()
            )
        }
    }

    /// Haalt de beoordelingen op die buddies over deze cliënt hebben geschreven.
    func loadElderlyReviews(elderlyId: UUID) async {
        guard let rows = try? await TaskService().fetchReviews(revieweeId: elderlyId) else { return }
        let reviews = rows.map { row in
            Review(
                id: UUID(),
                stars: row.stars,
                body: row.body.isEmpty ? "Fijn bezoek, bedankt!" : row.body,
                authorName: row.reviewer?.firstName ?? "Buddy",
                date: AppState.parseISO(row.createdAt) ?? Date()
            )
        }
        await MainActor.run { self.elderlyReviews = reviews }
    }

    /// Haalt de opgeslagen toestemming op en zet de flags. Als er een keuze is,
    /// blijft het toestemmingsscherm weg (consentDecided = true).
    func loadConsentFromSupabase(userId: UUID) async {
        let state = await ConsentService().fetchCurrentConsents(userId: userId)
        guard state.decided else { return }
        await MainActor.run {
            self.consentProductAnalytics = state.productAnalytics
            self.consentResearchInsights = state.researchInsights
            self.consentDecided = true
        }
    }
}
