import Foundation
import Supabase

final class TaskService {

    // MARK: - Open taken ophalen (buddy kaart)

    func fetchOpenTasks() async throws -> [DBTask] {
        try await supabase
            .from("tasks")
            .select()
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Taken voor een oudere (geschiedenis + actief)

    func fetchTasksForElderly(elderlyId: UUID) async throws -> [DBTask] {
        try await supabase
            .from("tasks")
            .select()
            .eq("elderly_id", value: elderlyId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
