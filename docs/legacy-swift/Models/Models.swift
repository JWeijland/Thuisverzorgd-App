import Foundation
import SwiftUI
import CoreLocation

// MARK: - Task category (welzijn only)
//
// Vrijwilligers-welzijnsplatform: uitsluitend welzijnstaken. Geen zorg, geen
// medische handelingen, geen niveaus. Iedere buddy mag elke taak oppakken.

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case companionship
    case walkOutdoors
    case groceries
    case activity
    case digitalHelp
    case socialSupport
    case lightCleaning
    case appointment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .companionship: return "Gezelschap"
        case .walkOutdoors:  return "Samen wandelen"
        case .groceries:     return "Boodschappen"
        case .activity:      return "Samen iets doen"
        case .digitalHelp:   return "Digitale hulp"
        case .socialSupport: return "Luisterend oor"
        case .lightCleaning: return "Hand-en-spandiensten"
        case .appointment:   return "Samen naar afspraak"
        case .other:         return "Anders"
        }
    }

    var description: String {
        switch self {
        case .companionship: return "Een uurtje koffie, kletsen, samen tv kijken"
        case .walkOutdoors:  return "Samen een ommetje maken"
        case .groceries:     return "Boodschappen halen en opruimen"
        case .activity:      return "Samen koken, een spelletje of een uitje"
        case .digitalHelp:   return "Helpen met telefoon, tablet of computer"
        case .socialSupport: return "Even praten, aandacht en een luisterend oor"
        case .lightCleaning: return "Kleine klusjes en lichte hand-en-spandiensten"
        case .appointment:   return "Samen naar een afspraak of de winkel"
        case .other:         return "Iets anders waar gezelschap of hulp bij fijn is"
        }
    }

    var icon: String {
        switch self {
        case .companionship: return "cup.and.saucer.fill"
        case .walkOutdoors:  return "figure.walk"
        case .groceries:     return "bag.fill"
        case .activity:      return "puzzlepiece.fill"
        case .digitalHelp:   return "iphone"
        case .socialSupport: return "ear.fill"
        case .lightCleaning: return "hands.and.sparkles.fill"
        case .appointment:   return "calendar.badge.clock"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    /// Merk-icoon (Asset Catalog) voor weergave op lichte achtergronden.
    /// Voor wit-op-kleur (bijv. de kaartpin) gebruiken we nog `icon` (SF Symbol).
    var brandIcon: String {
        switch self {
        case .companionship: return "tv-gezelschap"
        case .walkOutdoors:  return "tv-wandelen"
        case .groceries:     return "tv-boodschappen"
        case .activity:      return "tv-activiteit"
        case .digitalHelp:   return "tv-digitalehulp"
        case .socialSupport: return "tv-socialesteun"
        case .lightCleaning: return "tv-huishouding"
        case .appointment:   return "tv-afspraak"
        case .other:         return "tv-overig"
        }
    }
}

// MARK: - Buddy service catalog (flat, welzijn)
//
/// Vlakke catalogus van welzijn-services. Geen niveaus. De namen worden
/// gebruikt in onboarding, profiel en matching.
enum BuddyServiceCatalog {

    struct Item: Hashable {
        let name: String
        let icon: String
        let subtitle: String
        /// Categorieën waaraan deze service mapt voor matching.
        let categories: Set<TaskCategory>
    }

    static let allItems: [Item] = [
        Item(name: "Gezelschap",           icon: "person.2.fill",      subtitle: "Gesprek en aanwezigheid",                  categories: [.companionship]),
        Item(name: "Koffie drinken",       icon: "cup.and.saucer.fill", subtitle: "Samen een kopje koffie of thee",          categories: [.companionship]),
        Item(name: "Wandelen",             icon: "figure.walk",        subtitle: "Samen naar buiten",                        categories: [.walkOutdoors]),
        Item(name: "Boodschappen",         icon: "cart.fill",          subtitle: "Inkopen doen of begeleiden",               categories: [.groceries]),
        Item(name: "Samen koken",          icon: "fork.knife",         subtitle: "Samen een maaltijd klaarmaken",            categories: [.activity]),
        Item(name: "Spelletjes",           icon: "dice.fill",          subtitle: "Gezelschapsspellen en kaarten",            categories: [.activity, .companionship]),
        Item(name: "Een uitje",            icon: "sun.max.fill",       subtitle: "Samen op pad, museum of park",             categories: [.activity]),
        Item(name: "Digitale hulp",        icon: "iphone",             subtitle: "Helpen met telefoon, tablet of computer",  categories: [.digitalHelp]),
        Item(name: "Luisterend oor",       icon: "ear.fill",           subtitle: "Aandacht en een goed gesprek",             categories: [.socialSupport]),
        Item(name: "Voorlezen",            icon: "book.fill",          subtitle: "Boeken, krant of brieven voorlezen",       categories: [.companionship, .socialSupport]),
        Item(name: "Hand-en-spandiensten", icon: "hands.and.sparkles.fill", subtitle: "Kleine klusjes en opruimen",          categories: [.lightCleaning]),
        Item(name: "Begeleiding afspraak", icon: "car.fill",           subtitle: "Meegaan naar arts of afspraak",            categories: [.appointment]),
        Item(name: "Administratie",        icon: "doc.text.fill",      subtitle: "Post sorteren en formulieren invullen",    categories: [.other]),
        Item(name: "Tuinieren",            icon: "leaf.fill",          subtitle: "Tuin bijhouden en planten verzorgen",      categories: [.other]),
        Item(name: "Huisdieren",           icon: "pawprint.fill",      subtitle: "Hond uitlaten of dier verzorgen",          categories: [.other]),
    ]

    /// Geeft alle service-namen die mappen op een bepaalde categorie.
    static func serviceNames(for category: TaskCategory) -> Set<String> {
        Set(allItems.filter { $0.categories.contains(category) }.map { $0.name })
    }
}

// MARK: - Recurring schedule

/// Eenheid voor een periodieke hulpvraag: elke N dagen of elke N weken.
enum RecurringUnit: String, CaseIterable, Identifiable {
    case days  = "dagen"
    case weeks = "weken"

    var id: String { rawValue }
    var singular: String { self == .days ? "dag" : "week" }
    var calendarComponent: Calendar.Component { self == .days ? .day : .weekOfYear }
}

struct RecurringSchedule: Hashable {
    /// Elke `intervalCount` `unit` (bijv. elke 2 weken, of elke 3 dagen). De
    /// gebruiker vult zelf het aantal en de eenheid in (geen vaste vakjes meer).
    var intervalCount: Int = 1
    var unit: RecurringUnit = .weeks
    let endDate: Date

    /// De stap waarmee de volgende afspraak wordt berekend.
    var recurrenceStep: (component: Calendar.Component, value: Int) {
        (unit.calendarComponent, max(1, intervalCount))
    }

    /// Genereert de concrete afspraakdatums vanaf `start` t/m de einddatum, met het
    /// gekozen interval toegepast. De eerste afspraak is `start` zelf. De bovengrens
    /// (366) voorkomt doorlopen bij onverwachte invoer.
    func occurrences(from start: Date, calendar: Calendar = .current) -> [Date] {
        var dates: [Date] = []
        var current = start
        let step = recurrenceStep
        while current <= endDate && dates.count < 366 {
            dates.append(current)
            guard let next = calendar.date(byAdding: step.component, value: step.value, to: current) else { break }
            current = next
        }
        return dates
    }

    var displayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM"
        let until = "t/m \(f.string(from: endDate))"
        let n = max(1, intervalCount)
        let every = n == 1 ? "Elke \(unit.singular)" : "Elke \(n) \(unit.rawValue)"
        return "\(every) \(until)"
    }
}

// MARK: - Task timing

enum TaskTiming: Hashable {
    case now
    case today(hour: Int)
    case scheduled(date: Date)

    var displayName: String {
        switch self {
        case .now: return "Zo snel mogelijk"
        case .today(let h): return String(format: "Vandaag om %02d:00", h)
        case .scheduled(let d):
            let f = DateFormatter()
            f.locale = Locale(identifier: "nl_NL")
            f.dateFormat = "EEEE d MMM 'om' HH:mm"
            return f.string(from: d).capitalized
        }
    }
}

// MARK: - Task status

enum TaskStatus: String, Codable {
    case open
    case accepted
    case arrived
    case inProgress
    case completed
    case cancelled

    var label: String {
        switch self {
        case .open: return "Open"
        case .accepted: return "Buddy onderweg"
        case .arrived: return "Buddy is aangekomen"
        case .inProgress: return "Bezig"
        case .completed: return "Afgerond"
        case .cancelled: return "Geannuleerd"
        }
    }

    var color: Color {
        switch self {
        case .open: return BCColors.warning
        case .accepted: return BCColors.primary
        case .arrived: return BCColors.accent
        case .inProgress: return BCColors.primary
        case .completed: return BCColors.success
        case .cancelled: return BCColors.danger
        }
    }
}

// MARK: - Service Task (avoid name clash with Swift Task)

struct ServiceTask: Identifiable, Hashable {
    let id: UUID
    let elderlyName: String
    let elderlyAddress: String
    let coordinate: CLLocationCoordinate2D
    let category: TaskCategory
    let timing: TaskTiming
    let note: String
    var status: TaskStatus
    let createdAt: Date

    var assignedBuddyName: String?
    var assignedBuddyRating: Double?
    var assignedBuddyEtaMinutes: Int?
    /// UUID van de toegewezen buddy — nodig om live een review te koppelen (reviewee).
    var assignedBuddyId: UUID? = nil
    /// Telefoonnummer van de toegewezen buddy, zodat de oudere tijdens een actieve
    /// hulpvraag de juiste buddy kan bellen. PRIVACY: alleen gevuld zolang de taak
    /// actief is (aangenomen/onderweg/bezig); daarbuiten nil, zodat het nummer niet
    /// buiten de hulpvraag om beschikbaar is.
    var assignedBuddyPhone: String? = nil
    /// UUID van de hulpvrager (cliënt) — nodig om een buddy→cliënt review te koppelen.
    var elderlyId: UUID? = nil

    var completionNote: String? = nil
    var completedAt: Date? = nil
    var recurringSchedule: RecurringSchedule? = nil
    var checkInRecord: CheckInRecord? = nil
    /// Zorgkring-pivot (fase35): 'team' = exclusief voor de zorgkring van deze
    /// hulpvrager (alleen zichtbaar voor teamleden), 'pool' = open voor iedereen.
    var visibility: String = "pool"

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ServiceTask, rhs: ServiceTask) -> Bool { lhs.id == rhs.id }
}

// MARK: - Check-in record

struct CheckInRecord {
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let qrPayload: String
    let hasSelfie: Bool
    let distanceMeters: Double?
    var selfieStorageUrl: String? = nil

    var timestampFormatted: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.timeStyle = .short
        return f.string(from: timestamp)
    }

    var distanceFormatted: String {
        guard let d = distanceMeters else { return "Onbekend" }
        return d < 1000 ? "\(Int(d.rounded())) m" : String(format: "%.1f km", d / 1000)
    }

    var isWithinRange: Bool {
        guard let d = distanceMeters else { return true }
        return d <= 500
    }
}

// MARK: - Users

/// Laagdrempelige demografie — alleen voor geaggregeerde, anonieme inzichten
/// (gemeente/verzekeraar). NOOIT als los persoonsgegeven verkocht; altijd via
/// de k-anonieme aggregatielaag. Zie MEGA_PROMPT_DATA_PRIVACY_LAAG.md.
enum Gender: String, CaseIterable, Identifiable, Codable {
    case female  = "vrouw"
    case male    = "man"
    case other   = "anders"
    case unknown = "onbekend"   // "zeg ik liever niet"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .female: return "Vrouw"
        case .male: return "Man"
        case .other: return "Anders"
        case .unknown: return "Zeg ik liever niet"
        }
    }
}

/// Status van de Verklaring Omtrent het Gedrag (VOG) van een buddy.
enum VOGStatus: String, CaseIterable, Identifiable, Codable {
    case nietAangevraagd = "niet_aangevraagd"
    case aangevraagd     = "aangevraagd"
    case inBehandeling   = "in_behandeling"
    case geldig          = "geldig"
    case afgewezen       = "afgewezen"
    case verlopen        = "verlopen"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .nietAangevraagd: return "Nog niet geregeld"
        case .aangevraagd:     return "Aangevraagd"
        case .inBehandeling:   return "In behandeling"
        case .geldig:          return "Geldig"
        case .afgewezen:       return "Afgewezen"
        case .verlopen:        return "Verlopen"
        }
    }
    var isVerified: Bool { self == .geldig }
}

/// Helpers voor een geboortedatum: omzetten van/naar de "yyyy-MM-dd" die de
/// Supabase DATE-kolom (date_of_birth) gebruikt, en nette weergave in het NL.
enum BCBirthDate {
    static let dbFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    /// Datum → "yyyy-MM-dd" voor de database.
    static func dbString(from date: Date) -> String { dbFormatter.string(from: date) }

    /// "yyyy-MM-dd" (of een volledige ISO-timestamp) → Datum.
    static func date(from string: String) -> Date? {
        dbFormatter.date(from: String(string.prefix(10)))
    }

    /// Datum → "12 maart 1948" voor weergave.
    static func display(_ date: Date) -> String { displayFormatter.string(from: date) }
}

struct ElderlyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    /// Volledige geboortedatum (dag/maand/jaar). De sentinel 1-1-1945 betekent
    /// "onbekend". Bron voor de exacte leeftijd.
    var dateOfBirth: Date
    var phoneNumber: String?
    var favoriteBuddyIDs: [UUID]
    var familyMemberIDs: [UUID]
    /// Laagdrempelige demografie (zie Gender) — geaggregeerd verkoopbaar.
    var gender: Gender = .unknown
    /// 4-cijferige postcode (PC4), grof genoeg voor regio-inzicht, niet herleidbaar.
    var postcode4: String = ""
    /// Zichtbaarheid per persoonlijk gegeven (punt 13). Bepaalt of het gegeven op
    /// het openbare profiel / voor anderen zichtbaar is. Telefoon en adres staan
    /// standaard privé (postcode wil niet iedereen delen).
    var showsPhone: Bool = false
    var showsAddress: Bool = false
    var showsBirthDate: Bool = true
    /// Echt geboortejaar (live: uit elderly_profiles). nil = onbekend.
    var birthYear: Int? = nil
    /// Gemiddelde beoordeling door buddies (fase25). 0 = nog geen beoordelingen.
    var ratingAverage: Double = 0
    var totalReviews: Int = 0

    var fullName: String { "\(firstName) \(lastName)" }
    var age: Int { Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0 }

    /// Is de volledige geboortedatum echt bekend (dus niet de sentinel 1-1-1945)?
    var hasRealDateOfBirth: Bool {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: dateOfBirth)
        return !(c.year == 1945 && c.month == 1 && c.day == 1)
    }

    /// Leeftijd om te tónen — alleen als die echt bekend is. Voorkomt de nep-"81"
    /// die ontstond door een standaard-geboortedatum (1-1-1945) in live-modus.
    /// Voorkeur: de volledige geboortedatum (exact, houdt rekening met of de
    /// verjaardag dit jaar al is geweest). Anders het losse geboortejaar.
    var displayAge: Int? {
        let cal = Calendar.current
        if hasRealDateOfBirth,
           let a = cal.dateComponents([.year], from: dateOfBirth, to: Date()).year,
           a > 0, a < 130 {
            return a
        }
        let thisYear = cal.component(.year, from: Date())
        if let birthYear, birthYear > 1900, birthYear <= thisYear {
            return thisYear - birthYear
        }
        return nil
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ElderlyUser, rhs: ElderlyUser) -> Bool { lhs.id == rhs.id }
}

struct BuddyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let avatarSystemName: String
    let ratingAverage: Double
    let totalTasks: Int
    var bio: String
    let study: String
    /// VOG blijft (gratis voor vrijwilligers). Blokkeert aanmelden niet, maar
    /// een buddy kan pas taken aannemen als VOG rond is én intake akkoord.
    var vogValid: Bool
    var vogExpiresAt: Date
    /// Gedetailleerde VOG-status (aangevraagd / geüpload / geldig …).
    var vogStatus: VOGStatus = .nietAangevraagd
    /// Pad naar het geüploade VOG-document in de vog-documents bucket (Model B).
    var vogDocumentUrl: String? = nil
    /// Korte (~5 min) intake — altijd verplicht, geen org-uitzondering.
    var intakeCompleted: Bool = false
    var isAvailableNow: Bool = true
    /// Thuis-/basisadres van de buddy (vrij ingevuld; bron voor de coördinaat).
    var address: String = ""
    /// Locatie van de buddy — gebruikt voor proximity matching.
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
    /// Maximale afstand in km die de buddy bereid is af te leggen.
    var maxDistanceKm: Int = 10
    /// Aantal voltooide taken per categorie — bron voor "ervaren buddy" matching.
    var completedTasksByCategory: [TaskCategory: Int] = [:]
    /// Welke welzijn-services (BuddyServiceCatalog-namen) de buddy wil doen.
    var preferredServices: Set<String> = []
    /// Laagdrempelige demografie (zie Gender) — geaggregeerd verkoopbaar.
    var gender: Gender = .unknown
    /// Geboortejaar — bron voor leeftijd; alleen geaggregeerd gebruikt.
    var birthYear: Int? = nil
    /// Volledige geboortedatum (dag/maand/jaar) — exacte leeftijd, getoond op het
    /// profiel. nil = onbekend (dan valt de leeftijd terug op birthYear).
    var dateOfBirth: Date? = nil
    /// 4-cijferige postcode (PC4) — grof regio-inzicht, niet herleidbaar.
    var postcode4: String = ""
    /// Telefoonnummer van de buddy (uit profiles.phone_number). Wordt tijdens een
    /// actieve hulpvraag aan de oudere doorgegeven zodat die de buddy kan bellen.
    var phoneNumber: String? = nil
    /// Zichtbaarheid per persoonlijk gegeven (punt 13). Bepaalt of het gegeven op
    /// het openbare profiel / voor anderen zichtbaar is. Je buurt staat standaard
    /// privé (postcode wil niet iedereen delen); bio en leeftijd standaard zichtbaar.
    var showsBio: Bool = true
    var showsNeighborhood: Bool = false
    var showsBirthDate: Bool = true

    var fullName: String { "\(firstName) \(lastName)" }
    /// Leeftijd om te tónen: bij voorkeur exact uit de volledige geboortedatum
    /// (houdt rekening met of de verjaardag dit jaar al is geweest), anders uit
    /// het losse geboortejaar. nil als niets bekend is.
    var age: Int? {
        let cal = Calendar.current
        if let dob = dateOfBirth,
           let a = cal.dateComponents([.year], from: dob, to: Date()).year,
           a > 0, a < 130 {
            return a
        }
        guard let birthYear, birthYear > 1900 else { return nil }
        let thisYear = cal.component(.year, from: Date())
        return max(0, thisYear - birthYear)
    }
    /// Een buddy mag rondkijken, maar pas taken aannemen als VOG rond is én intake akkoord.
    var canAcceptTasks: Bool { vogValid && intakeCompleted }
    /// True als de buddy 3+ taken in deze categorie heeft afgerond.
    func isExperiencedIn(_ category: TaskCategory) -> Bool {
        (completedTasksByCategory[category] ?? 0) >= 3
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: BuddyUser, rhs: BuddyUser) -> Bool { lhs.id == rhs.id }
}

struct FamilyUser: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let relationship: String
    let linkedElderlyIDs: [UUID]

    var fullName: String { "\(firstName) \(lastName)" }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FamilyUser, rhs: FamilyUser) -> Bool { lhs.id == rhs.id }
}

// MARK: - Reviews

struct Review: Identifiable, Hashable {
    let id: UUID
    let stars: Int
    let body: String
    let authorName: String
    let date: Date
}

// MARK: - Activity items (family timeline)

struct ActivityItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let icon: String
    let color: Color
    let title: String
    let detail: String

    static func == (lhs: ActivityItem, rhs: ActivityItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Organizations / partners
//
// Aangesloten vrijwilligersorganisaties en partners (gemeente, zorgverzekeraar,
// werkgever). Geen tarieven of geldstromen meer — alleen koppeling en herkomst.

struct Organization: Identifiable, Hashable {
    let id: UUID
    let name: String
    let shortName: String
    let logoSymbol: String
    let isActive: Bool
    /// Sleutel waarmee de organisatie in het profiel wordt vastgelegd
    /// (organization_key). Puur ter herkenning van de herkomst; de huisstijl
    /// verandert hier niet door.
    var key: String = "thuisverzorgd"

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Organization, rhs: Organization) -> Bool { lhs.id == rhs.id }
}

enum MembershipStatus: String, Equatable {
    case none, pending, approved, rejected

    var displayLabel: String {
        switch self {
        case .none:     return "Geen"
        case .pending:  return "In behandeling"
        case .approved: return "Goedgekeurd"
        case .rejected: return "Afgewezen"
        }
    }

    var color: Color {
        switch self {
        case .none:     return BCColors.textTertiary
        case .pending:  return BCColors.warning
        case .approved: return BCColors.success
        case .rejected: return BCColors.danger
        }
    }
}

struct OrganizationMembership: Identifiable {
    let id: UUID
    let userId: UUID
    let userName: String
    let userRole: UserRole
    let organizationId: UUID
    var status: MembershipStatus
    let proofNote: String
    let submittedAt: Date
    var reviewedAt: Date?
    var adminNote: String?
}

// MARK: - Koppelcodes (clients sluiten aan via een partner)
//
// Clients (ouderen/familie) worden toegelaten omdat hun welzijn voordelig is voor
// zorgverzekeraars, gemeenten en werkgevers. Die partners krijgen van ons koppelcodes
// die zij aan hun inwoners/verzekerden/medewerkers uitdelen. Admin genereert de codes.

enum PartnerType: String, CaseIterable, Identifiable, Codable {
    case gemeente
    case zorgverzekeraar
    case werkgever
    case organisatie
    case overig

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemeente:        return "Gemeente"
        case .zorgverzekeraar: return "Zorgverzekeraar"
        case .werkgever:       return "Werkgever"
        case .organisatie:     return "Organisatie"
        case .overig:          return "Overig"
        }
    }

    var icon: String {
        switch self {
        case .gemeente:        return "building.columns.fill"
        case .zorgverzekeraar: return "cross.case.fill"
        case .werkgever:       return "briefcase.fill"
        case .organisatie:     return "building.2.fill"
        case .overig:          return "tag.fill"
        }
    }
}

struct PartnerCode: Identifiable, Hashable {
    let id: UUID
    var code: String
    var partnerName: String
    var partnerType: PartnerType
    /// nil = onbeperkt aantal gebruiken.
    var maxUses: Int?
    var usedCount: Int
    var isActive: Bool
    let createdAt: Date
    var expiresAt: Date?

    var isExpired: Bool {
        if let e = expiresAt { return e < Date() }
        return false
    }
    var isUsedUp: Bool {
        if let m = maxUses { return usedCount >= m }
        return false
    }
    /// Een code is bruikbaar als hij actief is, niet verlopen en niet opgebruikt.
    var isValid: Bool { isActive && !isExpired && !isUsedUp }

    var usesLabel: String {
        if let m = maxUses { return "\(usedCount)/\(m) gebruikt" }
        return "\(usedCount)× gebruikt · onbeperkt"
    }

    var statusLabel: String {
        if !isActive { return "Ingetrokken" }
        if isExpired { return "Verlopen" }
        if isUsedUp { return "Opgebruikt" }
        return "Actief"
    }

    var statusColor: Color {
        isValid ? BCColors.success : BCColors.textTertiary
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PartnerCode, rhs: PartnerCode) -> Bool { lhs.id == rhs.id }
}

// CLLocationCoordinate2D Hashable conformance
extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
