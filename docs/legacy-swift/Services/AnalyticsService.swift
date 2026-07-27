import Foundation
import CoreLocation
import Supabase

// ============================================================
// Privacy-by-design analytics (client-kant).
//
// Schrijft naar de Supabase-tabellen uit fase3_privacy_analytics.sql:
//   - consents          (toestemming per doel; juridische basis)
//   - analytics_events  (pseudonieme events; RLS weigert insert zonder toestemming)
//
// Harde regels (zie MEGA_PROMPT_DATA_PRIVACY_LAAG.md):
//   • Nooit PII, nooit exacte locatie, nooit gezondheidsdetails in een event.
//   • Alleen een GROVE regio (PC4 of ~11 km hokje).
//   • Events stromen alleen in live-modus én met toestemming.
// ============================================================

enum ConsentPurpose: String {
    case productAnalytics  = "product_analytics"
    case researchInsights  = "research_insights"
}

/// Huidige toestemmingsstand van een gebruiker. `decided` is false als er nog
/// nooit een keuze is vastgelegd (→ toon het toestemmingsscherm).
struct ConsentState {
    var productAnalytics: Bool
    var researchInsights: Bool
    var decided: Bool
}

struct ConsentService {
    static let policyVersion = "v1"

    /// Leest de laatste keuze per doel uit de consents-tabel (RLS: eigen rijen).
    /// Faalt stil naar "nog niet beslist".
    func fetchCurrentConsents(userId: UUID) async -> ConsentState {
        struct Row: Decodable { let purpose: String; let granted: Bool }
        do {
            // Nieuwste eerst; de eerste rij per doel is de actuele keuze.
            let rows: [Row] = try await supabase
                .from("consents")
                .select("purpose,granted")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            guard !rows.isEmpty else {
                return ConsentState(productAnalytics: false, researchInsights: false, decided: false)
            }
            var product = false
            var research = false
            var seen = Set<String>()
            for row in rows where !seen.contains(row.purpose) {
                seen.insert(row.purpose)
                if row.purpose == ConsentPurpose.productAnalytics.rawValue { product = row.granted }
                if row.purpose == ConsentPurpose.researchInsights.rawValue { research = row.granted }
            }
            return ConsentState(productAnalytics: product, researchInsights: research, decided: true)
        } catch {
            return ConsentState(productAnalytics: false, researchInsights: false, decided: false)
        }
    }

    /// Legt een toestemmingskeuze vast (append-only: elke keuze = nieuwe rij).
    func setConsent(userId: UUID, purpose: ConsentPurpose, granted: Bool) async throws {
        struct Insert: Encodable {
            let userId: UUID
            let purpose: String
            let granted: Bool
            let policyVersion: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case purpose
                case granted
                case policyVersion = "policy_version"
            }
        }
        try await supabase.from("consents").insert(Insert(
            userId: userId,
            purpose: purpose.rawValue,
            granted: granted,
            policyVersion: Self.policyVersion
        )).execute()
    }
}

enum AnalyticsEvent: String {
    case appOpen           = "app_open"
    case helpRequested     = "help_requested"
    case taskAccepted      = "task_accepted"
    case taskCompleted     = "task_completed"
    case taskCancelled     = "task_cancelled"
    case visitCheckin      = "visit_checkin"
    case buddyAvailableOn  = "buddy_available_on"
    case buddyAvailableOff = "buddy_available_off"
}

struct AnalyticsService {
    /// Log één event. `region` = GROVE regio (PC4 of ~11 km), nooit exact adres.
    /// Faalt stil: analytics mag de app nooit blokkeren. De RLS-policy weigert
    /// de insert sowieso als er geen toestemming is — dubbele bescherming.
    func track(_ event: AnalyticsEvent,
               userId: UUID?,
               role: String?,
               region: String?,
               category: String? = nil) async {
        struct Insert: Encodable {
            let userId: UUID?
            let role: String?
            let eventType: String
            let region: String?
            let category: String?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case role
                case eventType = "event_type"
                case region
                case category
            }
        }
        do {
            try await supabase.from("analytics_events").insert(Insert(
                userId: userId,
                role: role,
                eventType: event.rawValue,
                region: region,
                category: category
            )).execute()
        } catch {
            #if DEBUG
            print("[analytics] track \(event.rawValue) faalde: \(error)")
            #endif
        }
    }
}

extension CLLocationCoordinate2D {
    /// Grove regiocode (~11 km hokje), bewust onnauwkeurig voor privacy.
    /// Gebruikt als fallback wanneer er geen PC4 bekend is.
    var coarseRegion: String {
        String(format: "%.1f,%.1f", latitude, longitude)
    }
}
