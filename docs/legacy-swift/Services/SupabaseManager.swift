import Foundation
import Supabase

// ============================================================
// Supabase client — singleton, beschikbaar door de hele app
//
// Wijst naar het onafhankelijke Thuisverzorgd-project. schema.sql + de migratie
// supabase/migrations/fase1_live_and_push.sql zijn hier gedraaid.
// ============================================================

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://fgavamsvbtxwmlfkfvgp.supabase.co")!,
    supabaseKey: "sb_publishable_g_H5aVwWKXtxEzedN9ORNw_n2Os26Iu"
)

// ============================================================
// DATABASE MODELLEN
// Komen 1-op-1 overeen met de tabellen in schema.sql
//
// Welzijn-versie: geen geld (tarieven/earnings), geen niveaus, geen cursussen,
// geen ID/KYC. Buddies hebben VOG + korte intake. Clients sluiten aan via een
// koppelcode (partner_codes).
// ============================================================

struct DBProfile: Codable, Identifiable {
    let id: UUID
    let role: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let createdAt: String?
    /// White-label thema-sleutel die bij de registratie is gekozen (de
    /// vrijwilligersorganisatie). nil = standaard Thuisverzorgd.
    var organizationKey: String?

    enum CodingKeys: String, CodingKey {
        case id, role
        case firstName       = "first_name"
        case lastName        = "last_name"
        case phoneNumber     = "phone_number"
        case createdAt       = "created_at"
        case organizationKey = "organization_key"
    }
}

struct DBElderlyProfile: Codable, Identifiable {
    let id: UUID
    var address: String?
    var latitude: Double?
    var longitude: Double?
    /// De koppelcode waarmee deze cliënt is toegelaten (van gemeente/verzekeraar/werkgever).
    var linkingCodeUsed: String?
    var largeTextEnabled: Bool?
    var prefersFormal: Bool?
    var birthYear: Int?
    /// Volledige geboortedatum als "yyyy-MM-dd" (DATE-kolom). Bron voor de
    /// exacte leeftijd; birthYear blijft voor de geaggregeerde analytics.
    var dateOfBirth: String?
    /// Gemiddelde beoordeling van de cliënt door buddies (fase25).
    var ratingAverage: Double?
    var totalReviews: Int?
    /// Zichtbaarheid per gegeven (fase31, punt 13).
    var showsPhone: Bool?
    var showsAddress: Bool?
    var showsBirthdate: Bool?
    /// Zorgkring-pivot (fase35): 'team' of 'random_only'.
    var teamMode: String?

    enum CodingKeys: String, CodingKey {
        case id, address, latitude, longitude
        case linkingCodeUsed  = "linking_code_used"
        case largeTextEnabled = "large_text_enabled"
        case prefersFormal    = "prefers_formal"
        case birthYear        = "birth_year"
        case dateOfBirth      = "date_of_birth"
        case ratingAverage    = "rating_average"
        case totalReviews     = "total_reviews"
        case showsPhone       = "shows_phone"
        case showsAddress     = "shows_address"
        case showsBirthdate   = "shows_birthdate"
        case teamMode         = "team_mode"
    }
}

struct DBBuddyProfile: Codable, Identifiable {
    let id: UUID
    var bio: String?
    var study: String?
    var ratingAverage: Double?
    var totalTasks: Int?
    var vogValid: Bool?
    var vogExpiresAt: String?
    var vogStatus: String?
    var vogDocumentUrl: String?
    var intakeCompleted: Bool?
    var maxDistanceKm: Int?
    var isAvailableNow: Bool?
    var isOnboardingComplete: Bool?
    var preferredServices: [String]?
    /// URL/markering dat er een profielfoto in de `avatars`-bucket staat.
    /// Wordt gebruikt om bij het inloggen de eigen foto te herstellen.
    var avatarUrl: String?
    /// Thuis-/basisadres + grove coördinaat (voor "hulpvraag in je buurt", fase22).
    var address: String?
    var latitude: Double?
    var longitude: Double?
    /// Volledige geboortedatum als "yyyy-MM-dd" (DATE-kolom, fase26).
    var dateOfBirth: String?
    /// Zichtbaarheid per gegeven (fase31, punt 13).
    var showsBio: Bool?
    var showsNeighborhood: Bool?
    var showsBirthdate: Bool?

    enum CodingKeys: String, CodingKey {
        case id, bio, study
        case ratingAverage        = "rating_average"
        case totalTasks           = "total_tasks"
        case vogValid             = "vog_valid"
        case vogExpiresAt         = "vog_expires_at"
        case vogStatus            = "vog_status"
        case vogDocumentUrl       = "vog_document_url"
        case intakeCompleted      = "intake_completed"
        case maxDistanceKm        = "max_distance_km"
        case isAvailableNow       = "is_available_now"
        case isOnboardingComplete = "is_onboarding_complete"
        case preferredServices    = "preferred_services"
        case avatarUrl            = "avatar_url"
        case address
        case latitude
        case longitude
        case dateOfBirth          = "date_of_birth"
        case showsBio             = "shows_bio"
        case showsNeighborhood    = "shows_neighborhood"
        case showsBirthdate       = "shows_birthdate"
    }
}

struct DBTask: Codable, Identifiable {
    let id: UUID
    let elderlyId: UUID
    var assignedBuddyId: UUID?
    // Weergavevelden (zie schema.sql): zodat een buddy een open verzoek kan
    // tonen zonder het ouder-profiel te mogen lezen.
    var elderlyFirstName: String?
    var elderlyLatitude: Double?
    var elderlyLongitude: Double?
    let category: String
    let timingType: String
    var scheduledAt: String?
    let note: String
    var status: String
    let createdAt: String
    var acceptedAt: String?
    var arrivedAt: String?
    var completedAt: String?
    var completionNote: String?
    var buddyEtaMinutes: Int?
    /// Zorgkring-pivot (fase35): 'team' = exclusief voor de zorgkring,
    /// 'pool' = zichtbaar in de open lijst voor alle buddies.
    var visibility: String?

    enum CodingKeys: String, CodingKey {
        case id, note, status, category, visibility
        case elderlyId         = "elderly_id"
        case assignedBuddyId   = "assigned_buddy_id"
        case elderlyFirstName  = "elderly_first_name"
        case elderlyLatitude   = "elderly_latitude"
        case elderlyLongitude  = "elderly_longitude"
        case timingType        = "timing_type"
        case scheduledAt       = "scheduled_at"
        case createdAt         = "created_at"
        case acceptedAt        = "accepted_at"
        case arrivedAt         = "arrived_at"
        case completedAt       = "completed_at"
        case completionNote    = "completion_note"
        case buddyEtaMinutes   = "buddy_eta_minutes"
    }
}

/// Familie-koppeling: 6-cijferige code waarmee een familielid aan een oudere koppelt.
struct DBLinkingCode: Codable {
    let code: String
    let elderlyId: UUID
    let expiresAt: String
    var usedAt: String?

    enum CodingKeys: String, CodingKey {
        case code
        case elderlyId = "elderly_id"
        case expiresAt = "expires_at"
        case usedAt    = "used_at"
    }
}

/// Partner-koppelcode: door admin uitgegeven aan gemeenten/verzekeraars/werkgevers,
/// waarmee clients zich op het platform kunnen aanmelden.
struct DBPartnerCode: Codable, Identifiable {
    let id: UUID
    var code: String
    var partnerName: String
    var partnerType: String
    var maxUses: Int?
    var usedCount: Int
    var isActive: Bool
    let createdAt: String
    var expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, code
        case partnerName = "partner_name"
        case partnerType = "partner_type"
        case maxUses     = "max_uses"
        case usedCount   = "used_count"
        case isActive    = "is_active"
        case createdAt   = "created_at"
        case expiresAt   = "expires_at"
    }
}
