import Foundation
import Supabase

// ============================================================
// TeamService — teams, leden en join-verzoeken (fase14 + fase18)
//
// Lezen gebeurt direct (RLS: teams/leden zichtbaar voor ingelogden); muteren
// loopt via SECURITY DEFINER-RPC's met ingebouwde eigenaarscontrole:
//   create_team · request_to_join_team · approve_join_request · reject_join_request
// ============================================================

// MARK: - DB-modellen

struct DBTeamMemberRow: Decodable {
    let buddyId: UUID
    let points: Int
    let role: String
    let profile: NameRow?

    struct NameRow: Decodable {
        let firstName: String
        let lastName: String?
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName  = "last_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case buddyId = "buddy_id"
        case points, role, profile
    }
}

struct DBTeam: Decodable, Identifiable {
    let id: UUID
    let name: String
    let icon: String?
    let accent: String?
    let outingTarget: Int
    let prizeTitle: String?
    let createdBy: UUID?
    let members: [DBTeamMemberRow]

    enum CodingKeys: String, CodingKey {
        case id, name, icon, accent
        case outingTarget = "outing_target"
        case prizeTitle   = "prize_title"
        case createdBy    = "created_by"
        case members      = "team_members"
    }
}

/// Openstaand join-verzoek (voor de teameigenaar én de aanvrager zelf).
struct DBJoinRequest: Decodable, Identifiable {
    let id: UUID
    let teamId: UUID
    let buddyId: UUID
    let status: String
    let profile: DBTeamMemberRow.NameRow?

    enum CodingKeys: String, CodingKey {
        case id, status, profile
        case teamId  = "team_id"
        case buddyId = "buddy_id"
    }
}

final class TeamService {

    // MARK: - Lezen

    /// Alle teams met hun leden (naam + punten) in één geneste query.
    func fetchTeams() async throws -> [DBTeam] {
        try await supabase
            .from("teams")
            .select("id,name,icon,accent,outing_target,prize_title,created_by,team_members(buddy_id,points,role,profile:profiles!buddy_id(first_name,last_name))")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Eigen openstaande verzoeken (zodat de UI "in afwachting" kan tonen).
    func fetchMyPendingRequests(buddyId: UUID) async throws -> [DBJoinRequest] {
        try await supabase
            .from("team_join_requests")
            .select("id,team_id,buddy_id,status")
            .eq("buddy_id", value: buddyId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }

    // MARK: - Muteren (RPC's)

    /// Maakt een team aan en voegt de maker als eigenaar toe (atomair). Geeft de
    /// nieuwe team-id terug.
    @discardableResult
    func createTeam(name: String, icon: String, accent: String, outingTarget: Int) async throws -> UUID {
        struct Params: Encodable {
            let p_name: String
            let p_icon: String
            let p_accent: String
            let p_outing_target: Int
        }
        return try await supabase
            .rpc("create_team", params: Params(
                p_name: name, p_icon: icon, p_accent: accent, p_outing_target: outingTarget
            ))
            .execute()
            .value
    }

    func requestToJoin(teamId: UUID) async throws {
        try await supabase
            .rpc("request_to_join_team", params: ["p_team_id": teamId.uuidString])
            .execute()
    }

    func approve(requestId: UUID) async throws {
        try await supabase
            .rpc("approve_join_request", params: ["p_request_id": requestId.uuidString])
            .execute()
    }

    func reject(requestId: UUID) async throws {
        try await supabase
            .rpc("reject_join_request", params: ["p_request_id": requestId.uuidString])
            .execute()
    }
}
