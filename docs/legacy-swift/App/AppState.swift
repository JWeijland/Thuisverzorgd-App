import SwiftUI
import Observation

struct ToastMessage: Equatable {
    let text: String
    let icon: String
}

@Observable
final class AppState {
    // Navigation
    var currentRole: UserRole? = nil
    var hasSeenSplash: Bool = false
    var isOnboardingComplete: Bool = false
    var showLogin: Bool = false

    // Auth & initialization
    var authService = AuthService()
    var isInitializing: Bool = true
    /// Demo-modus laadt mock-data (zie loadDemoData). In live-modus blijft alles
    /// leeg tot de gebruiker eigen data opbouwt of de live-laag het uit Supabase haalt.
    var isDemoMode: Bool = false {
        didSet {
            guard isDemoMode != oldValue else { return }
            if isDemoMode { loadDemoData() } else { clearDemoSeedData() }
        }
    }
    var realUserId: UUID? = nil
    let profileService = ProfileService()

    // Live-modus: handle naar de buddy-poll die open taken uit Supabase haalt.
    // Bijbehorende live-logica staat in AppStateLive.swift.
    @ObservationIgnored var openTaskPollTask: Task<Void, Never>? = nil

    // Live-modus: handle naar de inbox-/teams-poll (fase18).
    @ObservationIgnored var inboxPollTask: Task<Void, Never>? = nil

    // Live-modus: handle naar de poll die de actieve hulpvraag van de oudere
    // bijwerkt (status/buddy) zodra de buddy aanneemt, incheckt of uitcheckt.
    @ObservationIgnored var elderlyTaskPollTask: Task<Void, Never>? = nil
    // Live-modus: realtime-abonnement op de eigen taken (instant update, naast de
    // poll als vangnet).
    @ObservationIgnored var elderlyTaskRealtimeTask: Task<Void, Never>? = nil

    // Live-modus: positie van de buddy die onderweg is naar de oudere. Voedt de
    // voortgangsbalk (voller naarmate de buddy dichterbij is) en de live kaart.
    @ObservationIgnored var buddyLiveLocationTask: Task<Void, Never>? = nil
    @ObservationIgnored var buddyRouteStartKm: Double? = nil
    var buddyLiveLatitude: Double? = nil
    var buddyLiveLongitude: Double? = nil
    /// 0…1 — hoe ver de buddy onderweg is (1 = aangekomen).
    var buddyRouteProgress: Double = 0

    // User data (used by both demo and real mode)
    var elderlyUser: ElderlyUser = MockData.omaRiet
    var buddyUser: BuddyUser = MockData.buddyAiyla
    var familyUser: FamilyUser = MockData.familySandra
    var allElderlyUsers: [ElderlyUser] = [MockData.omaRiet, MockData.opaHenk]

    // MARK: - Familie — gekoppelde ouderen
    // Eén familielid kan meerdere ouderen beheren (bijv. moeder én vader).
    // Meerdere familieleden kunnen dezelfde oudere koppelen via dezelfde code.
    var familyLinkedElderly: [ElderlyUser] = [MockData.omaRiet, MockData.opaHenk]
    var activeFamilyElderlyIndex: Int = 0

    /// Neutrale placeholder als er (nog) geen oudere gekoppeld is — géén mock.
    static let placeholderElderly = ElderlyUser(
        id: UUID(), firstName: "", lastName: "", address: "",
        coordinate: MockData.amsterdamCenter,
        dateOfBirth: Date(), phoneNumber: nil,
        favoriteBuddyIDs: [], familyMemberIDs: []
    )

    /// Lege buddy-placeholder — gebruikt om bij uitloggen/accountwissel álle
    /// gegevens van de vorige gebruiker te wissen (privacy). Géén MockData.
    static let placeholderBuddy = BuddyUser(
        id: UUID(), firstName: "", lastName: "",
        avatarSystemName: "person.crop.circle.fill",
        ratingAverage: 0, totalTasks: 0, bio: "", study: "",
        vogValid: false, vogExpiresAt: Date(),
        vogStatus: .nietAangevraagd, vogDocumentUrl: nil, intakeCompleted: false
    )

    /// Lege familie-placeholder — zelfde reden als hierboven.
    static let placeholderFamily = FamilyUser(
        id: UUID(), firstName: "", lastName: "",
        relationship: "", linkedElderlyIDs: []
    )

    /// De oudere die het familielid nu beheert.
    var activeFamilyElderly: ElderlyUser {
        get {
            guard familyLinkedElderly.indices.contains(activeFamilyElderlyIndex) else {
                return familyLinkedElderly.first ?? AppState.placeholderElderly
            }
            return familyLinkedElderly[activeFamilyElderlyIndex]
        }
        set {
            guard familyLinkedElderly.indices.contains(activeFamilyElderlyIndex) else { return }
            familyLinkedElderly[activeFamilyElderlyIndex] = newValue
        }
    }

    /// Koppelt een oudere via een 6-cijferige code. Geeft de voornaam terug
    /// bij succes, of nil als de code onbekend is.
    func linkElderly(code: String) -> String? {
        let known: [String: ElderlyUser] = [
            "123456": MockData.omaRiet,
            "654321": MockData.opaHenk
        ]
        guard let elderly = known[code] else { return nil }
        if let existing = familyLinkedElderly.firstIndex(where: { $0.id == elderly.id }) {
            activeFamilyElderlyIndex = existing
        } else {
            familyLinkedElderly.append(elderly)
            activeFamilyElderlyIndex = familyLinkedElderly.count - 1
        }
        return elderly.firstName
    }

    // Tasks — leeg in live-modus; demo vult via loadDemoData(), live via Supabase-poll.
    var openTasks: [ServiceTask] = []
    var activeTaskForElderly: ServiceTask? = nil
    var activeTaskForBuddy: ServiceTask? = nil {
        didSet {
            // Tijdens een lopende taak (buddy onderweg) volgen we de locatie wat
            // nauwkeuriger zodat de oudere 'm vloeiend ziet bewegen; daarbuiten weer
            // zuinig. Alleen schakelen als de "heeft taak"-status echt verandert.
            if (oldValue == nil) != (activeTaskForBuddy == nil) {
                BuddyLocationManager.shared.setHighPrecision(activeTaskForBuddy != nil)
            }
        }
    }
    /// Gezet zodra de buddy ontdekt dat zijn aangenomen hulpvraag is ingetrokken;
    /// bevat de naam van de hulpvrager. Toont een apart "ingetrokken"-scherm.
    var buddyCancelledNotice: String? = nil
    var taskHistory: [ServiceTask] = []

    // Alle buddies in het systeem (voor matching) — leeg tot demo/live ze laadt.
    var allBuddies: [BuddyUser] = []

    // Matching
    let matchingService = MatchingService()
    /// Laatste matches voor activeTaskForElderly — zodat UI kan tonen wie wordt benaderd
    var lastMatches: [MatchingService.Match] = []

    // UI state
    var showSOS: Bool = false
    var toastMessage: ToastMessage? = nil

    // Elderly preferences (not on ElderlyUser struct to avoid breaking init).
    // Live: bewaar in elderly_profiles. Tijdens laden onderdrukt door de vlag.
    @ObservationIgnored var suppressPreferenceWrite = false
    var largeTextEnabled: Bool = false {
        didSet { persistElderlyPreferencesIfLive(changed: oldValue != largeTextEnabled) }
    }
    var prefersFormal: Bool = true {
        didSet { persistElderlyPreferencesIfLive(changed: oldValue != prefersFormal) }
    }

    private func persistElderlyPreferencesIfLive(changed: Bool) {
        guard !suppressPreferenceWrite, changed, isLive,
              currentRole == .elderly, let id = realUserId else { return }
        let lt = largeTextEnabled, pf = prefersFormal
        Task { try? await ProfileService().updateElderlyPreferences(elderlyId: id, largeText: lt, prefersFormal: pf) }
    }

    // Buddy availability — live: bewaar in buddy_profiles + log analytics-event.
    /// Tijdens het laden van het profiel zetten we de waarde zonder terug te
    /// schrijven of een event te loggen (anders bij elke login een vals event).
    @ObservationIgnored var suppressAvailabilityWrite = false
    var isAvailableNow: Bool = true {
        didSet {
            guard !suppressAvailabilityWrite,
                  isAvailableNow != oldValue, isLive,
                  currentRole == .buddy, let id = realUserId else { return }
            let available = isAvailableNow
            Task { try? await ProfileService().updateBuddyAvailability(buddyId: id, isAvailable: available) }
            trackEvent(available ? .buddyAvailableOn : .buddyAvailableOff)
            // Live locatie volgen zolang de buddy beschikbaar is (meldingen in de
            // buurt) — óf zolang er een aangenomen taak loopt, zodat de oudere de
            // buddy onderweg live kan volgen, ook als die op niet-beschikbaar staat.
            if available { startBuddyLocationTrackingIfNeeded() }
            else if activeTaskForBuddy == nil { stopBuddyLocationTracking() }
        }
    }

    // MARK: - Organisatie ("Tak") state
    var availableOrganizations: [Organization] = MockData.allOrganizations
    var pendingRole: UserRole? = nil
    var selectedOrganization: Organization? = nil

    // MARK: - Organisatie-herkomst
    /// Naam van de vrijwilligersorganisatie waarmee deze gebruiker is aangesloten
    /// (uit de registratie of het profiel). Alleen ter weergave op de profielen;
    /// de huisstijl blijft altijd de standaard Thuisverzorgd-stijl.
    var organizationName: String? = nil

    /// Onthoudt de organisatie-herkomst op basis van de sleutel uit het profiel
    /// (organization_key). Onbekend of nil → geen organisatienaam.
    func setOrganization(key: String?) {
        guard let key, !key.isEmpty,
              let org = availableOrganizations.first(where: { $0.key == key }) else {
            organizationName = nil
            return
        }
        organizationName = org.name
    }
    var currentUserMembership: OrganizationMembership? = nil
    var allMemberships: [OrganizationMembership] = []

    // MARK: - Koppelcodes
    /// Door admin uitgegeven koppelcodes voor partners (gemeente/zorgverzekeraar/werkgever).
    var partnerCodes: [PartnerCode] = []
    /// Heeft de huidige cliënt een geldige koppelcode ingevuld (of demo-omzeild)?
    /// De koppelcode-gate staat voorlopig UIT: standaard true, zodat cliënten
    /// direct in de app komen. De walkthrough en flows blijven hierdoor werken.
    var elderlyHasLinkingCode: Bool = true

    var isOrganizationMember: Bool {
        currentUserMembership?.status == .approved
    }
    var isCordaanBuddy: Bool {
        isOrganizationMember && currentRole == .buddy
    }
    var isCordaanElderly: Bool {
        isOrganizationMember && currentRole == .elderly
    }

    // Elderly — favorites & ratings (leeg: bouwt op uit echte bezoeken)
    var favoriteBuddyNames: Set<String> = []
    var taskRatings: [UUID: Int] = [:]
    var skippedReviews: Set<UUID> = []

    /// Buddy — namen van hulpvragers die míj als vaste buddy hebben gekozen.
    /// Live uit favorite_buddies (RLS "Buddy ziet eigen fans"); demo lokaal.
    var buddyFans: [String] = []

    /// Actieve tab in de cliënt-app (0 hulp, 1 buddies, 2 profiel) — zodat de
    /// vaste-buddies-kaart op de hulppagina naar het Buddies-tabblad kan springen.
    var elderlyTabSelection: Int = 0

    /// Echte beoordelingen die ouderen/familie schrijven voor de buddy.
    /// Start leeg: in de demo verschijnen hier alleen reviews die je zelf
    /// schrijft (geen nep-reviews meer). In live-modus komen ze uit Supabase.
    var buddyReviews: [Review] = []

    /// Beoordelingen die buddies over de hulpvrager (cliënt) hebben geschreven —
    /// getoond op het cliëntprofiel. Live: uit Supabase.
    var elderlyReviews: [Review] = []

    /// Een net binnengekomen beoordeling die de buddy nog niet heeft gezien —
    /// wordt feestelijk getoond zodra de buddy de app opent. nil = niets nieuws.
    var pendingNewReview: Review? = nil

    // MARK: - Teams & berichten-inbox (gamification, fase18)
    /// Competities van de buddy-gamification. Demo: lokale mock; live: uit Supabase.
    var competitions: [Competition] = []
    /// Teams van de buddy-gamification. Demo: lokale mock; live: uit Supabase.
    var teams: [Team] = []
    /// Zorg-teams rond 1 ouder (punt 12). Demo: lokale mock; live: uit Supabase.
    var careTeams: [CareTeam] = []
    // MARK: Zorgkring-pivot (fase35)
    /// Openstaande team-uitnodigingen voor déze buddy (ring-dispatch).
    var teamInvites: [TeamInvite] = []
    /// Join-verzoeken: als buddy je eigen verzoeken, als hulpvrager/familie die
    /// van jouw team (RLS bepaalt wat je ziet).
    var careJoinRequests: [CareJoinRequest] = []
    /// Teamvoorkeur van de ingelogde hulpvrager: 'team' of 'random_only'.
    var elderlyTeamMode: String = "team"
    /// Na een afgeronde fallback-taak: stel de invaller voor om vast teamlid te
    /// worden van deze kring. nil = geen voorstel actief.
    var pendingTeamProposal: CareTeam? = nil
    /// Buddy-druppels voor de kaart-home van de hulpvrager/familie (fase36).
    /// Live: view buddy_map_pins; demo: afgeleid van MockData.allBuddies.
    var mapBuddyPins: [MapBuddyPin] = []
    /// Door de beheerder bepaalde team-prijzenladder (prijs per puntendoel).
    var teamPrizes: [DBTeamPrize] = []
    /// In-app berichten-inbox (join-verzoeken, goed-/afkeuringen).
    var inbox: [InboxMessage] = []
    /// Aantal ongelezen berichten — voedt de badge in de topbalk.
    var unreadInboxCount: Int { inbox.lazy.filter { !$0.read }.count }

    /// Punt 10: bestemming waar het aangetikte inbox-bericht naartoe leidt. Wordt
    /// door BuddyMapView opgepakt om de juiste pagina te openen; daarna weer nil.
    var inboxDestination: InboxDestination? = nil
    /// Demo-modus: lokale gesprekken per gesprekspartner (id of naam). In live-modus
    /// komen berichten uit Supabase (direct_messages) en blijft dit ongebruikt.
    var demoConversations: [String: [ChatMessage]] = [:]

    /// Punt 9: forceert dat de "hoe het werkt"-rondleiding voor deze rol opnieuw
    /// wordt getoond (aangevraagd vanuit het profiel). nil = niet actief.
    var walkthroughReplay: UserRole? = nil

    /// De persoonlijke koppelcode van de oudere om met familie te delen (live).
    var myLinkingCode: String? = nil

    /// Vergelijkt het aantal reviews met wat de buddy eerder zag. Is er iets
    /// nieuws bijgekomen, dan zet dit `pendingNewReview` (toont een animatie).
    func checkForNewReviews() {
        guard currentRole == .buddy else { return }
        let key = "buddy.seenReviewCount.\(realUserId?.uuidString ?? "demo")"
        let seen = UserDefaults.standard.integer(forKey: key)
        if buddyReviews.count > seen, let newest = buddyReviews.first {
            pendingNewReview = newest
        }
        UserDefaults.standard.set(buddyReviews.count, forKey: key)
    }

    /// Openstaande VOG's (aangevraagd / in behandeling) voor het admin-scherm.
    var pendingVOGs: [ProfileService.PendingVOG] = []

    // MARK: - Intake-videogesprek (wachtrij)
    /// Het actieve intake-gesprek van de ingelogde buddy (nil = geen).
    var myIntakeCall: ProfileService.DBIntakeCall? = nil
    /// Het eerstvolgende zelf-ingeplande intakegesprek van de buddy (nil = geen).
    var myScheduledCall: ProfileService.DBIntakeCall? = nil
    var intakeQueuePosition: Int = 0
    var intakeQueueTotal: Int = 0
    /// Live wachtrij voor het admin-scherm.
    var waitingCalls: [ProfileService.DBIntakeCall] = []
    /// Ingeplande intakegesprekken (zelf gekozen moment) voor het admin-scherm.
    var scheduledCalls: [ProfileService.DBIntakeCall] = []

    /// Alle gebruikers voor het admin-gebruikersbeheer.
    var allUsers: [DBProfile] = []

    // MARK: - Privacy & toestemming (analytics)
    /// Of de gebruiker de toestemmingskeuze al heeft gemaakt (sturen we het scherm?).
    var consentDecided: Bool = false
    /// Toestemming om de app te verbeteren met anonieme gebruiksstatistieken.
    var consentProductAnalytics: Bool = false
    /// Toestemming om bij te dragen aan geaggregeerde, anonieme welzijnsinzichten.
    var consentResearchInsights: Bool = false

    /// Grove regio (PC4 indien bekend, anders ~11 km hokje) van de huidige
    /// gebruiker. Nooit een exact adres. Gebruikt als `region` in events.
    var currentRegion: String? {
        switch currentRole {
        case .buddy:
            return buddyUser.postcode4.isEmpty ? buddyUser.coordinate.coarseRegion : buddyUser.postcode4
        case .elderly:
            return elderlyUser.postcode4.isEmpty ? elderlyUser.coordinate.coarseRegion : elderlyUser.postcode4
        default:
            return nil
        }
    }

    /// Legt de toestemmingskeuze vast (en, in live-modus, in Supabase).
    func recordConsent(productAnalytics: Bool, researchInsights: Bool) {
        consentProductAnalytics = productAnalytics
        consentResearchInsights = researchInsights
        consentDecided = true
        guard isLive, let userId = realUserId else { return }
        Task {
            try? await ConsentService().setConsent(userId: userId, purpose: .productAnalytics, granted: productAnalytics)
            try? await ConsentService().setConsent(userId: userId, purpose: .researchInsights, granted: researchInsights)
        }
    }

    /// Log een analytics-event — alleen live én met toestemming. Faalt stil.
    func trackEvent(_ event: AnalyticsEvent, category: TaskCategory? = nil) {
        guard isLive, consentProductAnalytics else { return }
        let region = currentRegion
        let role = currentRole?.rawValue
        let userId = realUserId
        let cat = category?.dbValue
        Task {
            await AnalyticsService().track(event, userId: userId, role: role, region: region, category: cat)
        }
    }

    /// Welke welzijn-services de buddy wil doen. Persists naar buddyUser én allBuddies.
    func setBuddyPreferences(services: Set<String>) {
        buddyUser.preferredServices = services
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].preferredServices = services
        }
        // Live: bewaar de gekozen welzijn-services in buddy_profiles.
        if isLive, currentRole == .buddy, let id = realUserId {
            let list = Array(services)
            Task { try? await ProfileService().updateBuddyServices(buddyId: id, services: list) }
        }
    }

    // MARK: - Toast

    func showToast(text: String, icon: String = "checkmark.circle.fill") {
        toastMessage = ToastMessage(text: text, icon: icon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.toastMessage?.text == text {
                self?.toastMessage = nil
            }
        }
    }
}

enum UserRole: String, CaseIterable, Identifiable {
    case elderly
    case buddy
    case family
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .elderly: return "Ik zoek hulp"
        case .buddy:   return "Ik ben buddy"
        case .family:  return "Ik ben familielid"
        case .admin:   return "Admin"
        }
    }

    var subtitle: String {
        switch self {
        case .elderly: return "Vind een buddy voor gezelschap en hulp in de buurt"
        case .buddy:   return "Help vrijwillig mensen in jouw buurt: gezelschap, wandelen, een praatje"
        case .family:  return "Regel hulp voor je vader, moeder of opa/oma"
        case .admin:   return "Beheer koppelcodes, organisaties en aanmeldingen"
        }
    }

    var icon: String {
        switch self {
        case .elderly: return "figure.wave"
        case .buddy:   return "person.2.fill"
        case .family:  return "house.and.flag.fill"
        case .admin:   return "gearshape.2.fill"
        }
    }
}
