import Foundation
import Supabase

final class ProfileService {

    func fetchProfile(userId: UUID) async throws -> DBProfile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchBuddyProfile(userId: UUID) async throws -> DBBuddyProfile {
        try await supabase
            .from("buddy_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchElderlyProfile(userId: UUID) async throws -> DBElderlyProfile {
        try await supabase
            .from("elderly_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }
}
