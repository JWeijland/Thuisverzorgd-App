import SwiftUI
import CoreLocation

// ============================================================================
// Zorgkringen (fase35, zorgkring-pivot)
//
// De zorgkring is hét team van de app: een vast groepje buddies rond 1
// hulpvrager. Na de onboarding van de hulpvrager worden buddies in de buurt
// per ring uitgenodigd; de hulpvrager stelt min/max in, reviewt het team en
// gaat daarna live. Het team vult het schema (claims); ongevulde momenten
// escaleren via 48u → 24u (team) → 30 min (urgente broadcast naar de buurt).
// Spontane hulpvragen zijn 8 minuten exclusief voor het team.
// ============================================================================

enum TeamKind: String { case points, care }

/// Wie mag een hulpvraag oppakken: de eigen zorgkring of de buddy-pool.
enum HelpAudience: String {
    case pool   // alle beschikbare buddies in de buurt
    case team   // de eigen zorgkring (bezoek komt in het inzetrooster)
}

/// Levensfase van een zorgkring.
enum CareTeamStatus: String {
    case forming   // werving loopt (ring-dispatch)
    case review    // minimum bereikt — hulpvrager beoordeelt het team
    case live      // actief
    case paused    // tijdelijk stil

    var label: String {
        switch self {
        case .forming: return "Team wordt gevormd"
        case .review:  return "Wacht op jouw akkoord"
        case .live:    return "Actief"
        case .paused:  return "Gepauzeerd"
        }
    }
}

/// Status van een bezoek in het schema van de zorgkring.
enum CareVisitStatus {
    case open     // nog vrij, teamlid kan claimen
    case urgent   // 30 min vooraf: ook buddies buiten het team mogen bijspringen
    case claimed  // opgepakt

    var label: String {
        switch self {
        case .open:    return "Vrij, wie pakt dit op?"
        case .urgent:  return "Zoekt met spoed een buddy"
        case .claimed: return "Opgepakt"
        }
    }
    var color: Color {
        switch self {
        case .open:    return BCColors.warning
        case .urgent:  return BCColors.danger
        case .claimed: return BCColors.success
        }
    }
    var icon: String {
        switch self {
        case .open:    return "hand.raised.fill"
        case .urgent:  return "bolt.fill"
        case .claimed: return "checkmark.circle.fill"
        }
    }
}

/// Eén hulpmoment in het schema van de zorgkring.
struct CareVisit: Identifiable, Hashable {
    let id: UUID
    let category: TaskCategory
    /// Ingeplande datum/tijd van het bezoek.
    let date: Date
    let note: String
    let createdAt: Date
    var claimedByBuddyId: UUID? = nil
    var claimedByName: String? = nil
    /// 30 min vooraf zonder claim: de urgente broadcast is de deur uit en
    /// iedere beschikbare buddy mag dit moment oppakken.
    var urgentSent: Bool = false
    /// Fase36: de geclaimde buddy zoekt vervanging voor dit moment.
    var swapRequested: Bool = false
    var swapReason: String = ""

    func status(now: Date = Date()) -> CareVisitStatus {
        if claimedByBuddyId != nil { return .claimed }
        if urgentSent { return .urgent }
        return .open
    }

    /// Telt dit moment als "goed geregeld"? (geclaimd en geen vervanging open)
    var isCovered: Bool { claimedByBuddyId != nil && !swapRequested }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CareVisit, rhs: CareVisit) -> Bool { lhs.id == rhs.id }
}

/// Een zorgkring rond 1 hulpvrager.
struct CareTeam: Identifiable, Hashable {
    let id: UUID
    var name: String
    var elderlyId: UUID? = nil
    var elderlyName: String
    var tint: [Color] = Palette.teal
    var status: CareTeamStatus = .live
    var minSize: Int = 3
    var maxSize: Int = 5
    /// Mogen gaten gevuld worden door willekeurige buddies uit de buurt?
    var fallbackAllowed: Bool = true
    var area: String = ""
    var helpSummary: String = ""
    var members: [PoolMember] = []
    var visits: [CareVisit] = []
    var isMyTeam: Bool = false
    var inviteCode: String = ""
    var pendingJoin: Bool = false
    /// Gamification: gezamenlijk uitjes-doel van de kring.
    var outingTarget: Int = 2000
    /// Benaderde locatie (~1 km) — voor "andere kringen in de buurt" op de
    /// kaart-home. Het echte adres blijft privé.
    var approxLatitude: Double? = nil
    var approxLongitude: Double? = nil

    var approxCoordinate: CLLocationCoordinate2D? {
        guard let lat = approxLatitude, let lon = approxLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Aankomende bezoeken die nog vrij zijn.
    func openVisits(now: Date = Date()) -> [CareVisit] {
        visits.filter { $0.date > now && $0.status(now: now) != .claimed }
            .sorted { $0.date < $1.date }
    }
    /// Schema oplopend op datum.
    var schedule: [CareVisit] { visits.sorted { $0.date < $1.date } }

    var memberCount: Int { members.count }
    /// Nog te werven plekken tot het gewenste maximum.
    var openSpots: Int { max(0, maxSize - members.count) }
    /// Gezamenlijke punten van de kring (uitjes-doel).
    var totalPoints: Int { members.reduce(0) { $0 + $1.points } }

    /// Fase36: het rooster is helemaal rond — er zijn aankomende momenten en
    /// elk moment is geclaimd zonder openstaande vervanging. Voedt de groene
    /// gloed op de zorgkring-kaarten.
    func scheduleFilled(now: Date = Date()) -> Bool {
        let upcoming = visits.filter { $0.date > now }
        guard !upcoming.isEmpty else { return false }
        return upcoming.allSatisfy { $0.isCovered }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CareTeam, rhs: CareTeam) -> Bool { lhs.id == rhs.id }
}

/// Een uitnodiging aan déze buddy om een zorgkring te joinen (ring-dispatch).
struct TeamInvite: Identifiable, Equatable {
    let id: UUID
    let careTeamId: UUID
    let elderlyName: String
    /// Privacy: vóór toetreding alleen voornaam, wijk/plaats en soort hulp.
    let area: String
    let helpSummary: String
    /// Buddy was al vaste buddy van deze hulpvrager (conversie-flow).
    let isFavorite: Bool
    let status: String   // pending / reminded / accepted / declined / expired
    let sentAt: Date

    var isOpen: Bool { status == "pending" || status == "reminded" }
}

/// Verzoek van een buddy om lid te worden van een zorgkring.
struct CareJoinRequest: Identifiable, Equatable {
    let id: UUID
    let careTeamId: UUID
    let buddyId: UUID
    let buddyName: String
    let source: String   // search / fallback
    let status: String   // pending / approved / rejected
    let createdAt: Date
}

// MARK: - Teamchat (fase36)

/// De twee duidelijk gescheiden chatkanalen van een zorgkring.
enum TeamChatChannel: String, CaseIterable, Identifiable {
    /// Het hele team mét de hulpvrager en familie.
    case all
    /// Alleen de vrijwilligers onderling.
    case buddies

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:     return "Met hulpvrager & familie"
        case .buddies: return "Alleen vrijwilligers"
        }
    }
    var icon: String {
        switch self {
        case .all:     return "person.3.fill"
        case .buddies: return "person.2.fill"
        }
    }
}

/// Eén bericht in de teamchat van een zorgkring.
struct TeamChatMessage: Identifiable, Equatable {
    let id: UUID
    let senderId: UUID?
    let senderName: String
    let body: String
    let date: Date
    let isMine: Bool
}

// MARK: - Buddy-druppels op de kaart-home (fase36)

/// Eén buddy-druppel voor de kaart van de hulpvrager/familie: alleen voornaam,
/// grove locatie en of er een profielfoto is (view buddy_map_pins).
struct MapBuddyPin: Identifiable {
    let id: UUID
    let firstName: String
    let coordinate: CLLocationCoordinate2D
    let isAvailable: Bool
    let hasAvatar: Bool
}

enum CareTeamData {
    /// Demo-seed: een zorgkring rond "Riet" met een paar bezoeken.
    static func demoTeams(currentName: String, currentId: UUID) -> [CareTeam] {
        let now = Date()
        func day(_ d: Int, hour: Int = 10) -> Date {
            let base = Calendar.current.date(byAdding: .day, value: d, to: now) ?? now
            return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }
        let me = PoolMember(name: currentName, avatar: "person.crop.circle.fill", points: 320, isCurrentUser: true, buddyId: currentId)
        let sanne = PoolMember(name: "Sanne", avatar: "person.crop.circle.fill", points: 260, buddyId: UUID())
        let mark = PoolMember(name: "Mark", avatar: "person.crop.circle.fill", points: 180, buddyId: UUID())

        let visits: [CareVisit] = [
            CareVisit(id: UUID(), category: .walkOutdoors, date: day(3, hour: 14),
                      note: "Samen een ommetje in het park.", createdAt: now),
            CareVisit(id: UUID(), category: .groceries, date: day(5, hour: 11),
                      note: "Boodschappen halen bij de super.", createdAt: now,
                      claimedByBuddyId: UUID(), claimedByName: "Sanne"),
            CareVisit(id: UUID(), category: .companionship, date: day(1, hour: 15),
                      note: "Koffie en een praatje.", createdAt: now),
        ]
        return [
            CareTeam(id: UUID(), name: "Team Riet", elderlyName: "Riet",
                     tint: Palette.teal, status: .live, minSize: 3, maxSize: 5,
                     area: "Centrum", helpSummary: "Gezelschap en boodschappen",
                     members: [me, sanne, mark], visits: visits,
                     isMyTeam: true, inviteCode: "RIET24")
        ]
    }
}
