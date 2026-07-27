import Foundation
import Supabase

// ============================================================
// MessageService — 1-op-1 gesprekken buddy <-> hulpvrager (fase30, punt 10)
//
// Lezen gebeurt direct (RLS: alleen de twee deelnemers zien het gesprek);
// versturen loopt via de SECURITY DEFINER-RPC send_direct_message, die meteen een
// inbox-melding voor de ontvanger aanmaakt.
// ============================================================

struct DBDirectMessage: Decodable, Identifiable {
    let id: UUID
    let senderId: UUID
    let recipientId: UUID
    let body: String
    let read: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, body, read
        case senderId    = "sender_id"
        case recipientId = "recipient_id"
        case createdAt   = "created_at"
    }
}

final class MessageService {

    /// Alle berichten tussen mij en `otherId`, oplopend op tijd.
    func fetchConversation(with otherId: UUID, me: UUID) async throws -> [DBDirectMessage] {
        let a = "and(sender_id.eq.\(me.uuidString),recipient_id.eq.\(otherId.uuidString))"
        let b = "and(sender_id.eq.\(otherId.uuidString),recipient_id.eq.\(me.uuidString))"
        return try await supabase
            .from("direct_messages")
            .select()
            .or("\(a),\(b)")
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Stuurt een bericht en geeft de ontvanger een inbox-melding (server-side).
    func send(to recipient: UUID, body: String) async throws {
        struct Params: Encodable {
            let p_recipient: String
            let p_body: String
        }
        try await supabase
            .rpc("send_direct_message", params: Params(p_recipient: recipient.uuidString, p_body: body))
            .execute()
    }

    /// Markeert de van `otherId` ontvangen berichten als gelezen.
    func markConversationRead(with otherId: UUID, me: UUID) async throws {
        struct U: Encodable { let read: Bool }
        try await supabase
            .from("direct_messages")
            .update(U(read: true))
            .eq("recipient_id", value: me.uuidString)
            .eq("sender_id", value: otherId.uuidString)
            .eq("read", value: false)
            .execute()
    }
}
