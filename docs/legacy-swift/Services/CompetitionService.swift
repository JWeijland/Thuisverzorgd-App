import Foundation
import Supabase

// ============================================================
// CompetitionService — competities + deelnames (fase14)
//
// Lezen is direct (RLS: zichtbaar voor ingelogden). Inschrijven/uitschrijven is
// het toevoegen/verwijderen van je eigen competition_participants-rij
// (RLS: buddy_id = auth.uid()). DB-triggers bewaken "max 1 actieve competitie"
// en de capaciteitsgrens.
// ============================================================

struct DBCompetitionParticipant: Decodable {
    let buddyId: UUID
    let points: Int
    let profile: DBTeamMemberRow.NameRow?

    enum CodingKeys: String, CodingKey {
        case buddyId = "buddy_id"
        case points, profile
    }
}

struct DBCompetition: Decodable, Identifiable {
    let id: UUID
    let name: String
    let tagline: String?
    let icon: String?
    let accent: String?
    let status: String
    let registrationDeadline: String?
    let startsAt: String?
    let endsAt: String?
    let durationWeeks: Int?
    let minParticipants: Int
    let maxParticipants: Int
    let prize1Title: String?
    let prize2Title: String?
    let prize3Title: String?
    let participants: [DBCompetitionParticipant]

    enum CodingKeys: String, CodingKey {
        case id, name, tagline, icon, accent, status
        case registrationDeadline = "registration_deadline"
        case startsAt             = "starts_at"
        case endsAt               = "ends_at"
        case durationWeeks        = "duration_weeks"
        case minParticipants      = "min_participants"
        case maxParticipants      = "max_participants"
        case prize1Title          = "prize_1_title"
        case prize2Title          = "prize_2_title"
        case prize3Title          = "prize_3_title"
        case participants         = "competition_participants"
    }
}

final class CompetitionService {

    func fetchCompetitions() async throws -> [DBCompetition] {
        try await supabase
            .from("competitions")
            .select("id,name,tagline,icon,accent,status,registration_deadline,starts_at,ends_at,duration_weeks,min_participants,max_participants,prize_1_title,prize_2_title,prize_3_title,competition_participants(buddy_id,points,profile:profiles!buddy_id(first_name,last_name))")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func register(competitionId: UUID, buddyId: UUID) async throws {
        struct Insert: Encodable {
            let competitionId: UUID
            let buddyId: UUID
            enum CodingKeys: String, CodingKey {
                case competitionId = "competition_id"
                case buddyId       = "buddy_id"
            }
        }
        try await supabase
            .from("competition_participants")
            .insert(Insert(competitionId: competitionId, buddyId: buddyId))
            .execute()
    }

    func unregister(competitionId: UUID, buddyId: UUID) async throws {
        try await supabase
            .from("competition_participants")
            .delete()
            .eq("competition_id", value: competitionId.uuidString)
            .eq("buddy_id", value: buddyId.uuidString)
            .execute()
    }
}
