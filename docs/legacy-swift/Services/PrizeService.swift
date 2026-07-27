import Foundation
import Supabase

// ============================================================
// PrizeService — beheer van de team-prijzenladder (fase20)
//
// Lezen mag iedereen (ingelogd); muteren alleen de admin (RLS).
// De prijs van een team wordt afgeleid uit deze ladder op basis van het
// gekozen puntendoel (zie de create_team-RPC).
// ============================================================

struct DBTeamPrize: Decodable, Identifiable, Equatable {
    let id: UUID
    let pointsThreshold: Int
    let title: String
    let icon: String?

    enum CodingKeys: String, CodingKey {
        case id, title, icon
        case pointsThreshold = "points_threshold"
    }
}

final class PrizeService {

    func fetchTeamPrizes() async throws -> [DBTeamPrize] {
        try await supabase
            .from("team_prizes")
            .select("id,points_threshold,title,icon")
            .order("points_threshold", ascending: true)
            .execute()
            .value
    }

    func createTeamPrize(threshold: Int, title: String, icon: String) async throws {
        struct Insert: Encodable {
            let pointsThreshold: Int
            let title: String
            let icon: String
            enum CodingKeys: String, CodingKey {
                case pointsThreshold = "points_threshold"
                case title, icon
            }
        }
        try await supabase
            .from("team_prizes")
            .insert(Insert(pointsThreshold: threshold, title: title, icon: icon))
            .execute()
    }

    func updateTeamPrize(id: UUID, threshold: Int, title: String, icon: String) async throws {
        struct Update: Encodable {
            let pointsThreshold: Int
            let title: String
            let icon: String
            enum CodingKeys: String, CodingKey {
                case pointsThreshold = "points_threshold"
                case title, icon
            }
        }
        try await supabase
            .from("team_prizes")
            .update(Update(pointsThreshold: threshold, title: title, icon: icon))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteTeamPrize(id: UUID) async throws {
        try await supabase
            .from("team_prizes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
