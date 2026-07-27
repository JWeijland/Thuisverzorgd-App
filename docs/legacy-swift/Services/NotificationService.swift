import Foundation
import Supabase

// ============================================================
// NotificationService — in-app berichten-inbox (fase18)
//
// De `notifications`-tabel is de inbox. RLS zorgt dat je alleen je eigen
// berichten ziet/beheert; inserts gebeuren server-side via de team-RPC's.
// ============================================================

struct DBNotification: Decodable, Identifiable {
    let id: UUID
    let kind: String
    let title: String
    let body: String?
    let teamId: UUID?
    let requestId: UUID?
    let senderId: UUID?
    let senderName: String?
    let taskId: UUID?
    let careTeamId: UUID?
    let read: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, read
        case teamId     = "team_id"
        case requestId  = "request_id"
        case senderId   = "sender_id"
        case senderName = "sender_name"
        case taskId     = "task_id"
        case careTeamId = "care_team_id"
        case createdAt  = "created_at"
    }
}

final class NotificationService {

    func fetchInbox() async throws -> [DBNotification] {
        try await supabase
            .from("notifications")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func markRead(id: UUID) async throws {
        struct U: Encodable { let read: Bool }
        try await supabase
            .from("notifications")
            .update(U(read: true))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func markAllRead(userId: UUID) async throws {
        struct U: Encodable { let read: Bool }
        try await supabase
            .from("notifications")
            .update(U(read: true))
            .eq("user_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("notifications")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
