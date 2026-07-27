import Foundation
import CoreLocation

enum MockData {
    static let amsterdamCenter = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)

    static let omaRiet = ElderlyUser(
        id: UUID(),
        firstName: "Riet",
        lastName: "van der Berg",
        address: "Elandsgracht 86, Amsterdam",
        coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1948, month: 3, day: 12))!,
        phoneNumber: "06 12 34 56 78",
        favoriteBuddyIDs: [],
        familyMemberIDs: []
    )

    static let opaHenk = ElderlyUser(
        id: UUID(),
        firstName: "Henk",
        lastName: "de Boer",
        address: "Ferdinand Bolstraat 45, Amsterdam",
        coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
        dateOfBirth: Calendar.current.date(from: DateComponents(year: 1940, month: 7, day: 4))!,
        phoneNumber: "06 98 76 54 32",
        favoriteBuddyIDs: [],
        familyMemberIDs: []
    )

    static let buddyAiyla = BuddyUser(
        id: UUID(),
        firstName: "Aiyla",
        lastName: "Demir",
        avatarSystemName: "person.crop.circle.fill",
        ratingAverage: 4.9,
        totalTasks: 47,
        bio: "Hallo! Ik ben Aiyla, 21 jaar en student in Amsterdam. Ik help graag met gezelschap, wandelen en een praatje.",
        study: "Student, Hogeschool van Amsterdam",
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 3),
        intakeCompleted: true,
        isAvailableNow: true,
        coordinate: CLLocationCoordinate2D(latitude: 52.3745, longitude: 4.8900),
        maxDistanceKm: 8,
        completedTasksByCategory: [
            .companionship: 12,
            .groceries: 8,
            .walkOutdoors: 5,
            .lightCleaning: 4,
            .activity: 3
        ],
        preferredServices: ["Gezelschap", "Koffie drinken", "Boodschappen", "Wandelen", "Voorlezen", "Spelletjes"]
    )

    static let buddyMark = BuddyUser(
        id: UUID(),
        firstName: "Mark",
        lastName: "Janssen",
        avatarSystemName: "person.crop.circle.fill",
        ratingAverage: 4.7,
        totalTasks: 112,
        bio: "Ervaren buddy, graag op pad of een spelletje doen. Beschikbaar in de avonden.",
        study: "Sociale Studies, afgerond",
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 2),
        intakeCompleted: true,
        isAvailableNow: false,
        coordinate: CLLocationCoordinate2D(latitude: 52.3580, longitude: 4.9000),
        maxDistanceKm: 15,
        completedTasksByCategory: [
            .activity: 28,
            .companionship: 22,
            .digitalHelp: 18,
            .appointment: 10
        ],
        preferredServices: ["Gezelschap", "Begeleiding afspraak", "Digitale hulp", "Een uitje", "Samen koken", "Spelletjes"]
    )

    static let buddySophie = BuddyUser(
        id: UUID(),
        firstName: "Sophie",
        lastName: "de Wit",
        avatarSystemName: "person.crop.circle.fill",
        ratingAverage: 4.6,
        totalTasks: 8,
        bio: "Student, hou van koffie drinken en kletsen.",
        study: "Student, Universiteit van Amsterdam",
        vogValid: true,
        vogExpiresAt: Date().addingTimeInterval(86400 * 365 * 3),
        intakeCompleted: true,
        isAvailableNow: true,
        coordinate: CLLocationCoordinate2D(latitude: 52.3700, longitude: 4.8950),
        maxDistanceKm: 5,
        completedTasksByCategory: [
            .companionship: 4,
            .lightCleaning: 2,
            .groceries: 2
        ],
        preferredServices: ["Gezelschap", "Koffie drinken", "Voorlezen", "Hand-en-spandiensten", "Boodschappen", "Spelletjes"]
    )

    static var allBuddies: [BuddyUser] { [buddyAiyla, buddyMark, buddySophie] }

    static let familySandra = FamilyUser(
        id: UUID(),
        firstName: "Sandra",
        lastName: "van der Berg",
        relationship: "Dochter van Riet",
        linkedElderlyIDs: [omaRiet.id]
    )

    // Open tasks visible on the buddy map
    static let openTasks: [ServiceTask] = [
        ServiceTask(
            id: UUID(),
            elderlyName: "Riet",
            elderlyAddress: "Elandsgracht 86",
            coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
            category: .companionship,
            timing: .now,
            note: "Een uurtje koffie en kletsen, ze voelt zich wat alleen vandaag.",
            status: .open,
            createdAt: Date().addingTimeInterval(-300),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Henk",
            elderlyAddress: "Ferdinand Bolstraat 45",
            coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
            category: .groceries,
            timing: .today(hour: 16),
            note: "Boodschappenlijstje ligt op de keukentafel.",
            status: .open,
            createdAt: Date().addingTimeInterval(-1800),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Truus",
            elderlyAddress: "Keizersgracht 210",
            coordinate: CLLocationCoordinate2D(latitude: 52.3729, longitude: 4.8851),
            category: .activity,
            timing: .today(hour: 18),
            note: "Samen koken en gezellig samen eten.",
            status: .open,
            createdAt: Date().addingTimeInterval(-2400),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Kees",
            elderlyAddress: "Weesperzijde 112",
            coordinate: CLLocationCoordinate2D(latitude: 52.3558, longitude: 4.9195),
            category: .walkOutdoors,
            timing: .now,
            note: "Een kort rondje langs het park, ongeveer 30 minuten.",
            status: .open,
            createdAt: Date().addingTimeInterval(-600),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Beatrix",
            elderlyAddress: "Minervalaan 78",
            coordinate: CLLocationCoordinate2D(latitude: 52.3453, longitude: 4.8732),
            category: .lightCleaning,
            timing: .scheduled(date: Date().addingTimeInterval(86400)),
            note: "Wat opruimen en samen de planten water geven.",
            status: .open,
            createdAt: Date().addingTimeInterval(-3600),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Wim",
            elderlyAddress: "Middenweg 44",
            coordinate: CLLocationCoordinate2D(latitude: 52.3532, longitude: 4.9272),
            category: .digitalHelp,
            timing: .today(hour: 20),
            note: "Hulp met videobellen met de kleinkinderen op de tablet.",
            status: .open,
            createdAt: Date().addingTimeInterval(-900),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Greet",
            elderlyAddress: "Bilderdijkstraat 159",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.8716),
            category: .companionship,
            timing: .now,
            note: "Even gezelschap, samen de krant doornemen.",
            status: .open,
            createdAt: Date().addingTimeInterval(-180),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Johan",
            elderlyAddress: "Czaar Peterstraat 22",
            coordinate: CLLocationCoordinate2D(latitude: 52.3711, longitude: 4.9241),
            category: .groceries,
            timing: .now,
            note: "Kleine boodschappen bij de buurtsuper.",
            status: .open,
            createdAt: Date().addingTimeInterval(-420),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Annie",
            elderlyAddress: "Van Woustraat 88",
            coordinate: CLLocationCoordinate2D(latitude: 52.3556, longitude: 4.8967),
            category: .appointment,
            timing: .today(hour: 14),
            note: "Samen naar de huisarts en weer terug.",
            status: .open,
            createdAt: Date().addingTimeInterval(-1500),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Cor",
            elderlyAddress: "Javastraat 130",
            coordinate: CLLocationCoordinate2D(latitude: 52.3631, longitude: 4.9335),
            category: .walkOutdoors,
            timing: .now,
            note: "Een frisse neus halen in het Oosterpark.",
            status: .open,
            createdAt: Date().addingTimeInterval(-240),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Ria",
            elderlyAddress: "Admiraal de Ruijterweg 200",
            coordinate: CLLocationCoordinate2D(latitude: 52.3784, longitude: 4.8589),
            category: .socialSupport,
            timing: .today(hour: 11),
            note: "Even langs voor een goed gesprek en een luisterend oor.",
            status: .open,
            createdAt: Date().addingTimeInterval(-2100),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Sjaak",
            elderlyAddress: "Plantage Middenlaan 14",
            coordinate: CLLocationCoordinate2D(latitude: 52.3669, longitude: 4.9089),
            category: .activity,
            timing: .today(hour: 17),
            note: "Samen koken en gezellig de maaltijd klaarmaken.",
            status: .open,
            createdAt: Date().addingTimeInterval(-1200),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        ),
        ServiceTask(
            id: UUID(),
            elderlyName: "Els",
            elderlyAddress: "Haarlemmerdijk 102",
            coordinate: CLLocationCoordinate2D(latitude: 52.3852, longitude: 4.8898),
            category: .companionship,
            timing: .today(hour: 21),
            note: "Een gezellig avondbezoek, samen een spelletje doen.",
            status: .open,
            createdAt: Date().addingTimeInterval(-720),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil
        )
    ]

    static let completedTasks: [ServiceTask] = [
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .companionship,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 2)),
                note: "Koffie drinken en samen kruiswoordpuzzel.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                assignedBuddyName: "Aiyla",
                assignedBuddyRating: 4.9,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 2 + 3600)
            t.completionNote = "Riet was vrolijk, samen koffie gedronken en wat over haar kleinkinderen gepraat."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .groceries,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 5)),
                note: "Boodschappenlijstje van AH halen.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 5),
                assignedBuddyName: "Sophie",
                assignedBuddyRating: 4.6,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 5 + 5400)
            t.completionNote = "Boodschappen gedaan, alles netjes opgeruimd in de keuken."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Riet",
                elderlyAddress: "Elandsgracht 86",
                coordinate: CLLocationCoordinate2D(latitude: 52.3717, longitude: 4.8836),
                category: .walkOutdoors,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 9)),
                note: "Een ommetje langs het park.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 9),
                assignedBuddyName: "Aiyla",
                assignedBuddyRating: 4.9,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 9 + 2700)
            t.completionNote = "Mooi weer, lekker gewandeld langs het Vondelpark."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Henk",
                elderlyAddress: "Ferdinand Bolstraat 45",
                coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
                category: .walkOutdoors,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 3)),
                note: "Wandeling langs de Amstel.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 3),
                assignedBuddyName: "Jan",
                assignedBuddyRating: 4.6,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 3 + 2700)
            t.completionNote = "Henk genoot van de frisse lucht, rustig tempo aangehouden."
            return t
        }(),
        {
            var t = ServiceTask(
                id: UUID(),
                elderlyName: "Henk",
                elderlyAddress: "Ferdinand Bolstraat 45",
                coordinate: CLLocationCoordinate2D(latitude: 52.3534, longitude: 4.8993),
                category: .groceries,
                timing: .scheduled(date: Date().addingTimeInterval(-86400 * 7)),
                note: "Weekboodschappen halen.",
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400 * 7),
                assignedBuddyName: "Jan",
                assignedBuddyRating: 4.4,
                assignedBuddyEtaMinutes: 0
            )
            t.completedAt = Date().addingTimeInterval(-86400 * 7 + 5400)
            t.completionNote = "Boodschappen gehaald en samen opgeruimd."
            return t
        }()
    ]

    // MARK: - Organisaties / partners

    static let cordaan = Organization(
        id: UUID(),
        name: "Vrijwilligerscentrale Amsterdam",
        shortName: "VCA",
        logoSymbol: "building.2.fill",
        isActive: true,
        key: "vca"
    )

    // Aangesloten organisaties. De key wordt als organization_key op het profiel
    // vastgelegd; vaste UUID's zodat de keuze herkenbaar blijft. De huisstijl van
    // de app blijft voor iedereen dezelfde Thuisverzorgd-stijl.
    static let voorElkaarInZuid = Organization(
        id: UUID(uuidString: "0E1D2C3B-4A59-6877-8695-A4B3C2D1E0F0")!,
        name: "Voor Elkaar in Zuid",
        shortName: "Zuid",
        logoSymbol: "building.2.fill",
        isActive: true,
        key: "zuid"
    )

    static let stichtingPresent = Organization(
        id: UUID(uuidString: "1F2E3D4C-5B6A-7988-9706-B5C4D3E2F1A0")!,
        name: "Stichting Present",
        shortName: "Present",
        logoSymbol: "heart.fill",
        isActive: true,
        key: "present"
    )

    /// Alle organisaties die iemand bij de registratie kan kiezen.
    static let allOrganizations: [Organization] = [
        voorElkaarInZuid, stichtingPresent, cordaan
    ]

    static var sampleMemberships: [OrganizationMembership] {
        [
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Petra Smits", userRole: .buddy,
                organizationId: cordaan.id, status: .pending,
                proofNote: "Intake ingediend",
                submittedAt: Date().addingTimeInterval(-3600 * 2)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Jan de Vries", userRole: .buddy,
                organizationId: cordaan.id, status: .approved,
                proofNote: "Intake afgerond",
                submittedAt: Date().addingTimeInterval(-86400 * 5),
                reviewedAt: Date().addingTimeInterval(-86400 * 4)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Truus Vissers", userRole: .buddy,
                organizationId: cordaan.id, status: .pending,
                proofNote: "Intake ingediend",
                submittedAt: Date().addingTimeInterval(-3600 * 5)
            ),
            OrganizationMembership(
                id: UUID(), userId: UUID(), userName: "Maria Hoekstra", userRole: .buddy,
                organizationId: cordaan.id, status: .approved,
                proofNote: "Intake afgerond",
                submittedAt: Date().addingTimeInterval(-86400 * 12),
                reviewedAt: Date().addingTimeInterval(-86400 * 11)
            ),
        ]
    }

    // MARK: - Koppelcodes (door admin uitgegeven aan partners)

    static var samplePartnerCodes: [PartnerCode] {
        [
            PartnerCode(id: UUID(), code: "ZEIST2026", partnerName: "Gemeente Zeist",
                        partnerType: .gemeente, maxUses: 250, usedCount: 38, isActive: true,
                        createdAt: Date().addingTimeInterval(-86400 * 20), expiresAt: nil),
            PartnerCode(id: UUID(), code: "ZILVEREN50", partnerName: "Zilveren Kruis",
                        partnerType: .zorgverzekeraar, maxUses: nil, usedCount: 112, isActive: true,
                        createdAt: Date().addingTimeInterval(-86400 * 45), expiresAt: nil),
            PartnerCode(id: UUID(), code: "PHILIPS-MZ", partnerName: "Philips (mantelzorg)",
                        partnerType: .werkgever, maxUses: 100, usedCount: 7, isActive: true,
                        createdAt: Date().addingTimeInterval(-86400 * 5), expiresAt: nil),
        ]
    }

    /// Activiteit per beheerde oudere, zodat de familie-tijdlijn meebeweegt met wie je beheert.
    static func familyActivity(for firstName: String) -> [ActivityItem] {
        switch firstName {
        case "Henk":
            return [
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 3), icon: "figure.walk", color: BCColors.accent, title: "Wandeling", detail: "Jan wandelde langs de Amstel met Henk. Notitie: rustig tempo, Henk genoot."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 7), icon: "bag.fill", color: BCColors.primary, title: "Boodschappen gedaan", detail: "Jan haalde de weekboodschappen en ruimde alles samen op."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 9), icon: "iphone", color: BCColors.accent, title: "Digitale hulp", detail: "Jan hielp Henk met videobellen met de familie."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 12), icon: "checkmark.circle.fill", color: BCColors.success, title: "Koppeling gelukt", detail: "Henk is gekoppeld aan uw familie-account.")
            ]
        default: // Riet
            return [
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-3600 * 2), icon: "checkmark.circle.fill", color: BCColors.success, title: "Bezoek voltooid", detail: "Aiyla bracht een uur door met Riet. Notitie: Riet was vrolijk."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 2), icon: "bag.fill", color: BCColors.primary, title: "Boodschappen gedaan", detail: "Sophie deed boodschappen bij AH."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 4), icon: "figure.walk", color: BCColors.accent, title: "Wandeling", detail: "Aiyla wandelde 30 min met Riet in het Heemraadspark."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 5), icon: "star.fill", color: BCColors.warning, title: "Beoordeling toegevoegd", detail: "Riet gaf Aiyla 5 sterren."),
                ActivityItem(id: UUID(), date: Date().addingTimeInterval(-86400 * 8), icon: "cup.and.saucer.fill", color: BCColors.primary, title: "Gezelschap", detail: "Mark dronk koffie met Riet en deed een spelletje.")
            ]
        }
    }
}
