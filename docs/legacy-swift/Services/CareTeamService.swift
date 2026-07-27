import Foundation
import Supabase

// ============================================================
// CareTeamService — zorgkringen (fase32 + fase35 zorgkring-pivot)
//
// Lezen gebeurt direct (RLS); muteren via SECURITY DEFINER-RPC's.
// Teamvorming (ring-dispatch) draait server-side in de team-formation cron;
// de app start 'm met start_team_formation en handelt uitnodigingen,
// review, join-verzoeken en claims af.
// ============================================================

struct DBCareVisit: Decodable, Identifiable {
    let id: UUID
    let category: String
    let scheduledAt: String
    let note: String?
    let claimedBy: UUID?
    let urgentSent: Bool?
    let swapRequested: Bool?
    let swapReason: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, category, note
        case scheduledAt   = "scheduled_at"
        case claimedBy     = "claimed_by"
        case urgentSent    = "urgent_sent"
        case swapRequested = "swap_requested"
        case swapReason    = "swap_reason"
        case createdAt     = "created_at"
    }
}

struct DBCareTeamMember: Decodable {
    let buddyId: UUID
    let role: String
    let points: Int?
    let profile: DBTeamMemberRow.NameRow?
    enum CodingKeys: String, CodingKey {
        case buddyId = "buddy_id"
        case role, points, profile
    }
}

struct DBCareTeam: Decodable, Identifiable {
    let id: UUID
    let name: String
    let elderlyId: UUID?
    let elderlyName: String?
    let accent: String?
    let inviteCode: String?
    let createdBy: UUID?
    let status: String?
    let minSize: Int?
    let maxSize: Int?
    let fallbackAllowed: Bool?
    let area: String?
    let helpSummary: String?
    let outingTarget: Int?
    let approxLatitude: Double?
    let approxLongitude: Double?
    let members: [DBCareTeamMember]
    let visits: [DBCareVisit]

    enum CodingKeys: String, CodingKey {
        case id, name, accent, status, area
        case members = "care_team_members", visits = "care_team_visits"
        case elderlyId       = "elderly_id"
        case elderlyName     = "elderly_name"
        case inviteCode      = "invite_code"
        case createdBy       = "created_by"
        case minSize         = "min_size"
        case maxSize         = "max_size"
        case fallbackAllowed = "fallback_allowed"
        case helpSummary     = "help_summary"
        case outingTarget    = "outing_target"
        case approxLatitude  = "approx_latitude"
        case approxLongitude = "approx_longitude"
    }
}

struct DBCareTeamInvite: Decodable, Identifiable {
    let id: UUID
    let careTeamId: UUID
    let ring: Int
    let status: String
    let isFavorite: Bool
    let elderlyName: String
    let area: String
    let helpSummary: String
    let sentAt: String

    enum CodingKeys: String, CodingKey {
        case id, ring, status, area
        case careTeamId  = "care_team_id"
        case isFavorite  = "is_favorite"
        case elderlyName = "elderly_name"
        case helpSummary = "help_summary"
        case sentAt      = "sent_at"
    }
}

struct DBCareJoinRequest: Decodable, Identifiable {
    let id: UUID
    let careTeamId: UUID
    let buddyId: UUID
    let source: String
    let status: String
    let createdAt: String
    let profile: DBTeamMemberRow.NameRow?

    enum CodingKeys: String, CodingKey {
        case id, source, status, profile
        case careTeamId = "care_team_id"
        case buddyId    = "buddy_id"
        case createdAt  = "created_at"
    }
}

final class CareTeamService {

    func fetchCareTeams() async throws -> [DBCareTeam] {
        try await supabase
            .from("care_teams")
            .select("""
            id,name,elderly_id,elderly_name,accent,invite_code,created_by,\
            status,min_size,max_size,fallback_allowed,area,help_summary,outing_target,\
            approx_latitude,approx_longitude,\
            care_team_members(buddy_id,role,points,profile:profiles!buddy_id(first_name,last_name)),\
            care_team_visits(id,category,scheduled_at,note,claimed_by,urgent_sent,swap_requested,swap_reason,created_at)
            """)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Teamvorming

    /// Start (of herstart) de teamvorming voor een hulpvrager. De ring-dispatch
    /// zelf draait server-side (team-formation cron). Familie geeft elderlyId mee.
    @discardableResult
    func startTeamFormation(name: String, minSize: Int, maxSize: Int, elderlyId: UUID? = nil) async throws -> UUID {
        struct Params: Encodable {
            let p_name: String
            let p_min: Int
            let p_max: Int
            let p_elderly_id: String?
        }
        return try await supabase
            .rpc("start_team_formation", params: Params(
                p_name: name, p_min: minSize, p_max: maxSize,
                p_elderly_id: elderlyId?.uuidString))
            .execute()
            .value
    }

    /// Uitnodigingen van de ingelogde buddy (RLS filtert op buddy_id).
    func fetchMyInvites() async throws -> [DBCareTeamInvite] {
        try await supabase
            .from("care_team_invites")
            .select("id,care_team_id,ring,status,is_favorite,elderly_name,area,help_summary,sent_at")
            .order("sent_at", ascending: false)
            .execute()
            .value
    }

    func acceptInvite(inviteId: UUID) async throws {
        try await supabase
            .rpc("accept_team_invite", params: ["p_invite_id": inviteId.uuidString])
            .execute()
    }

    func declineInvite(inviteId: UUID) async throws {
        try await supabase
            .rpc("decline_team_invite", params: ["p_invite_id": inviteId.uuidString])
            .execute()
    }

    // MARK: - Review & beheer (hulpvrager/familie)

    /// Weigeren haalt de buddy uit het team; accepteren is impliciet.
    func reviewMember(teamId: UUID, buddyId: UUID, accept: Bool) async throws {
        struct Params: Encodable {
            let p_team_id: String
            let p_buddy_id: String
            let p_accept: Bool
        }
        try await supabase
            .rpc("review_team_member", params: Params(
                p_team_id: teamId.uuidString, p_buddy_id: buddyId.uuidString, p_accept: accept))
            .execute()
    }

    func finalizeReview(teamId: UUID) async throws {
        try await supabase
            .rpc("finalize_team_review", params: ["p_team_id": teamId.uuidString])
            .execute()
    }

    func setFallbackAllowed(teamId: UUID, allowed: Bool) async throws {
        struct Params: Encodable {
            let p_team_id: String
            let p_allowed: Bool
        }
        try await supabase
            .rpc("set_team_fallback", params: Params(p_team_id: teamId.uuidString, p_allowed: allowed))
            .execute()
    }

    func removeMember(teamId: UUID, buddyId: UUID) async throws {
        struct Params: Encodable {
            let p_team_id: String
            let p_buddy_id: String
        }
        try await supabase
            .rpc("remove_care_team_member", params: Params(
                p_team_id: teamId.uuidString, p_buddy_id: buddyId.uuidString))
            .execute()
    }

    // MARK: - Join-verzoeken

    @discardableResult
    func requestJoin(teamId: UUID, source: String = "search") async throws -> UUID? {
        struct Params: Encodable {
            let p_team_id: String
            let p_source: String
        }
        return try await supabase
            .rpc("request_join_care_team", params: Params(p_team_id: teamId.uuidString, p_source: source))
            .execute()
            .value
    }

    /// Openstaande join-verzoeken (RLS: eigen verzoeken + die van je eigen team).
    func fetchJoinRequests() async throws -> [DBCareJoinRequest] {
        try await supabase
            .from("care_team_join_requests")
            .select("id,care_team_id,buddy_id,source,status,created_at,profile:profiles!buddy_id(first_name,last_name)")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func respondJoinRequest(requestId: UUID, approve: Bool) async throws {
        struct Params: Encodable {
            let p_request_id: String
            let p_approve: Bool
        }
        try await supabase
            .rpc("respond_care_join_request", params: Params(
                p_request_id: requestId.uuidString, p_approve: approve))
            .execute()
    }

    // MARK: - Schema

    /// Zet één of meer hulpmomenten in het inzetrooster (RPC request_care_visits).
    func requestCareVisits(teamId: UUID, category: String, note: String, dates: [Date]) async throws {
        struct Params: Encodable {
            let p_team_id: String
            let p_category: String
            let p_note: String
            let p_dates: [String]
        }
        let iso = ISO8601DateFormatter()
        try await supabase
            .rpc("request_care_visits", params: Params(
                p_team_id: teamId.uuidString,
                p_category: category,
                p_note: note,
                p_dates: dates.map { iso.string(from: $0) }))
            .execute()
    }

    func claimVisit(visitId: UUID) async throws {
        try await supabase
            .rpc("claim_care_visit", params: ["p_visit_id": visitId.uuidString])
            .execute()
    }

    /// Moment schrappen (hulpvrager/familie); de geclaimde buddy krijgt bericht.
    func cancelVisit(visitId: UUID) async throws {
        try await supabase
            .rpc("cancel_care_visit", params: ["p_visit_id": visitId.uuidString])
            .execute()
    }

    // MARK: - Vervanging (fase36)

    /// De geclaimde buddy vraagt vervanging voor een moment.
    func requestVisitSwap(visitId: UUID, reason: String) async throws {
        struct Params: Encodable {
            let p_visit_id: String
            let p_reason: String?
        }
        try await supabase
            .rpc("request_visit_swap", params: Params(
                p_visit_id: visitId.uuidString,
                p_reason: reason.isEmpty ? nil : reason))
            .execute()
    }

    /// De buddy trekt zijn vervangingsverzoek weer in.
    func withdrawVisitSwap(visitId: UUID) async throws {
        try await supabase
            .rpc("withdraw_visit_swap", params: ["p_visit_id": visitId.uuidString])
            .execute()
    }

    /// Een ander teamlid neemt het moment over. Retourneert de vorige buddy.
    @discardableResult
    func takeOverVisit(visitId: UUID) async throws -> UUID? {
        try await supabase
            .rpc("take_over_visit", params: ["p_visit_id": visitId.uuidString])
            .execute()
            .value
    }

    // MARK: - Teamchat (fase36)

    struct DBTeamChatMessage: Decodable, Identifiable {
        let id: UUID
        let careTeamId: UUID
        let senderId: UUID?
        let senderName: String
        let channel: String
        let body: String
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id, channel, body
            case careTeamId = "care_team_id"
            case senderId   = "sender_id"
            case senderName = "sender_name"
            case createdAt  = "created_at"
        }
    }

    /// Berichten van één kanaal ophalen (RLS bewaakt wie welk kanaal ziet).
    func fetchTeamMessages(teamId: UUID, channel: String, limit: Int = 200) async throws -> [DBTeamChatMessage] {
        try await supabase
            .from("care_team_messages")
            .select("id,care_team_id,sender_id,sender_name,channel,body,created_at")
            .eq("care_team_id", value: teamId.uuidString)
            .eq("channel", value: channel)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value
    }

    /// Bericht versturen (RPC bewaakt kanaal-rechten).
    @discardableResult
    func sendTeamMessage(teamId: UUID, channel: String, body: String) async throws -> UUID? {
        struct Params: Encodable {
            let p_team_id: String
            let p_channel: String
            let p_body: String
        }
        return try await supabase
            .rpc("send_care_team_message", params: Params(
                p_team_id: teamId.uuidString, p_channel: channel, p_body: body))
            .execute()
            .value
    }

    // MARK: - Push + inbox voor teamgebeurtenissen (edge function)

    /// Laat notify-team-event de rest van het team informeren (push + inbox).
    /// event: "chat" (met channel + text), "swap_request" of "swap_taken"
    /// (met visitId). Faalt stil: de actie zelf is dan al gelukt.
    func notifyTeamEvent(teamId: UUID, event: String,
                         channel: String? = nil, text: String? = nil,
                         visitId: UUID? = nil) async {
        struct Body: Encodable {
            let teamId: String
            let event: String
            let channel: String?
            let text: String?
            let visitId: String?
        }
        _ = try? await supabase.functions.invoke(
            "notify-team-event",
            options: .init(body: Body(
                teamId: teamId.uuidString, event: event,
                channel: channel, text: text,
                visitId: visitId?.uuidString))
        )
    }

    // MARK: - Buddy-druppels voor de kaart-home (fase36)

    struct DBBuddyMapPin: Decodable, Identifiable {
        let id: UUID
        let firstName: String?
        let latitude: Double?
        let longitude: Double?
        let currentLatitude: Double?
        let currentLongitude: Double?
        let locationUpdatedAt: String?
        let isAvailableNow: Bool?
        let hasAvatar: Bool?

        enum CodingKeys: String, CodingKey {
            case id, latitude, longitude
            case firstName         = "first_name"
            case currentLatitude   = "current_latitude"
            case currentLongitude  = "current_longitude"
            case locationUpdatedAt = "location_updated_at"
            case isAvailableNow    = "is_available_now"
            case hasAvatar         = "has_avatar"
        }
    }

    /// Buddy-druppels (view buddy_map_pins): alleen voornaam, grove locatie en
    /// foto-vlag van gescreende buddies.
    func fetchBuddyMapPins() async throws -> [DBBuddyMapPin] {
        try await supabase
            .from("buddy_map_pins")
            .select("id,first_name,latitude,longitude,current_latitude,current_longitude,location_updated_at,is_available_now,has_avatar")
            .execute()
            .value
    }
}
