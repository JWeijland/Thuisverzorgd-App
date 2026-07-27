import Foundation

enum Config {
    // Matching
    static let maxTaskRadiusKm: Double = 10.0
    static let favoriteBuddyPriorityMinutes: Int = 5

    // Vertrouwen
    static let vogRenewalYears: Int = 3
    static let reviewVisibilityDelayHours: Int = 48
    static let minimumBuddyAge: Int = 18

    // Lancering
    static let launchCities: [String] = ["Zeist", "Amsterdam"]
    static let launchQuarter: String = "Q3 2026"

    // Contact (vervang voor TestFlight)
    static let supportPhoneNumber: String = "085-XXX XXXX"
    static let supportEmail: String = "hulp@thuisverzorgd.nl"

    // Feature flags
    static let enableRealPushNotifications: Bool = false
}
