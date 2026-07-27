//  TaskService+QueriesLinks.swift
//  Verplaatst uit TaskService.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import Supabase

extension TaskService {

    /// De lopende, aan déze buddy toegewezen hulpvraag (accepted/arrived/in_progress),
    /// indien aanwezig. Gebruikt om de actieve taak terug te halen na een herstart,
    /// zodat de buddy 'm kan hervatten i.p.v. de oudere te laten wachten.
    func fetchMyAssignedActiveTask(buddyId: UUID) async throws -> DBTask? {
        let rows: [DBTask] = try await supabase
            .from("tasks")
            .select()
            .eq("assigned_buddy_id", value: buddyId.uuidString)
            .in("status", values: ["accepted", "arrived", "in_progress"])
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Eén taak op id (voor de buddy om te checken of zijn actieve taak nog loopt).
    func fetchTask(id: UUID) async throws -> DBTask? {
        let rows: [DBTask] = try await supabase
            .from("tasks")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Laat de edge function een push naar de toegewezen buddy sturen dat de
    /// hulpvraag is ingetrokken (zie supabase/functions/notify-task-cancelled).
    func notifyTaskCancelled(taskId: UUID) async throws {
        struct Body: Encodable { let taskId: String }
        try await supabase.functions.invoke(
            "notify-task-cancelled",
            options: .init(body: Body(taskId: taskId.uuidString))
        )
    }

    /// Buddy annuleerde een aangenomen hulpvraag → de taak staat weer 'open'.
    /// Laat de edge function de hulpvrager informeren (push + inbox) én buddies
    /// in de buurt opnieuw oproepen (zie supabase/functions/notify-task-reopened).
    func notifyTaskReopened(taskId: UUID, cancelledBuddyId: UUID?) async throws {
        struct Body: Encodable {
            let taskId: String
            let cancelledBuddyId: String?
        }
        try await supabase.functions.invoke(
            "notify-task-reopened",
            options: .init(body: Body(
                taskId: taskId.uuidString,
                cancelledBuddyId: cancelledBuddyId?.uuidString
            ))
        )
    }

    // MARK: - Taak afronden (geen verdiensten — vrijwillig)

    func completeTask(taskId: UUID, note: String) async throws {
        struct TaskUpdate: Encodable {
            let status: String
            let completedAt: Date
            let completionNote: String
            enum CodingKeys: String, CodingKey {
                case status
                case completedAt    = "completed_at"
                case completionNote = "completion_note"
            }
        }

        try await supabase
            .from("tasks")
            .update(TaskUpdate(status: "completed", completedAt: Date(), completionNote: note))
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    // MARK: - Review plaatsen

    func submitReview(
        taskId: UUID,
        reviewerId: UUID,
        revieweeId: UUID,
        stars: Int,
        body: String
    ) async throws {
        struct Insert: Encodable {
            let taskId: UUID
            let reviewerId: UUID
            let revieweeId: UUID
            let stars: Int
            let body: String
            enum CodingKeys: String, CodingKey {
                case taskId     = "task_id"
                case reviewerId = "reviewer_id"
                case revieweeId = "reviewee_id"
                case stars, body
            }
        }

        try await supabase
            .from("reviews")
            .insert(Insert(
                taskId: taskId,
                reviewerId: reviewerId,
                revieweeId: revieweeId,
                stars: stars,
                body: body
            ))
            .execute()
    }

    // MARK: - Reviews ophalen (voor het buddy-profiel)

    /// Decodet een review inclusief de voornaam van de schrijver (ingebed via FK).
    struct ReviewRow: Decodable {
        let stars: Int
        let body: String
        let createdAt: String
        let reviewer: Author?
        struct Author: Decodable { let firstName: String
            enum CodingKeys: String, CodingKey { case firstName = "first_name" } }
        enum CodingKeys: String, CodingKey {
            case stars, body
            case createdAt = "created_at"
            case reviewer
        }
    }

    /// Haalt de beoordelingen op die over deze gebruiker (buddy) zijn geschreven.
    func fetchReviews(revieweeId: UUID) async throws -> [ReviewRow] {
        try await supabase
            .from("reviews")
            .select("stars,body,created_at,reviewer:reviewer_id(first_name)")
            .eq("reviewee_id", value: revieweeId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Familie koppelen via 6-cijferige code

    func validateLinkingCode(code: String) async throws -> DBLinkingCode? {
        let results: [DBLinkingCode] = try await supabase
            .from("linking_codes")
            .select()
            .eq("code", value: code)
            .filter("used_at", operator: "is", value: "null")
            .gte("expires_at", value: Date().ISO8601Format())
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func linkFamilyToElderly(familyId: UUID, elderlyId: UUID, code: String) async throws {
        struct LinkInsert: Encodable {
            let familyId: UUID
            let elderlyId: UUID
            enum CodingKeys: String, CodingKey {
                case familyId  = "family_id"
                case elderlyId = "elderly_id"
            }
        }

        // Koppeling aanmaken
        try await supabase
            .from("family_elderly_links")
            .insert(LinkInsert(familyId: familyId, elderlyId: elderlyId))
            .execute()

        // Code markeren als gebruikt
        try await supabase
            .from("linking_codes")
            .update(["used_at": Date().ISO8601Format()])
            .eq("code", value: code)
            .execute()
    }

    // MARK: - Echte koppelcode-flow (oudere deelt code, familie wisselt in)

    struct LinkedElderlyDTO: Decodable {
        let id: UUID
        let firstName: String
        let lastName: String
        let address: String?
        let latitude: Double?
        let longitude: Double?
        enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName  = "last_name"
            case address, latitude, longitude
        }
    }

    /// Oudere: haal (of maak) mijn persoonlijke 6-cijferige koppelcode op.
    func ensureMyLinkingCode() async throws -> String {
        try await supabase.rpc("ensure_my_linking_code").execute().value
    }

    /// Familie: wissel een koppelcode in → koppeling + naam van de oudere terug.
    func redeemLinkingCode(code: String) async throws -> LinkedElderlyDTO? {
        try await supabase
            .rpc("redeem_linking_code", params: ["p_code": code])
            .execute().value
    }

    /// Familie: alle gekoppelde ouderen ophalen (bij inloggen).
    func myLinkedElderly() async throws -> [LinkedElderlyDTO] {
        try await supabase.rpc("my_linked_elderly").execute().value
    }

    // MARK: - Partner-koppelcodes (clients sluiten aan via partner)

    func fetchPartnerCodes() async throws -> [DBPartnerCode] {
        try await supabase
            .from("partner_codes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Zoekt een geldige, actieve, niet-verlopen koppelcode.
    func validatePartnerCode(code: String) async throws -> DBPartnerCode? {
        let results: [DBPartnerCode] = try await supabase
            .from("partner_codes")
            .select()
            .eq("code", value: code.uppercased())
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value
        guard let match = results.first else { return nil }
        // Verloop/limiet in de client checken (eenvoudige variant; productie via RPC/policy).
        if let exp = match.expiresAt, let date = ISO8601DateFormatter().date(from: exp), date < Date() {
            return nil
        }
        if let max = match.maxUses, match.usedCount >= max { return nil }
        return match
    }

    /// Verhoogt de gebruiksteller van een koppelcode (na succesvolle inwisseling).
    func incrementPartnerCodeUsage(id: UUID, currentCount: Int) async throws {
        try await supabase
            .from("partner_codes")
            .update(["used_count": currentCount + 1])
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Admin: maak een nieuwe koppelcode aan.
    func createPartnerCode(
        code: String,
        partnerName: String,
        partnerType: String,
        maxUses: Int?,
        expiresAt: Date?
    ) async throws -> DBPartnerCode {
        struct Insert: Encodable {
            let code: String
            let partnerName: String
            let partnerType: String
            let maxUses: Int?
            let expiresAt: Date?
            enum CodingKeys: String, CodingKey {
                case code
                case partnerName = "partner_name"
                case partnerType = "partner_type"
                case maxUses     = "max_uses"
                case expiresAt   = "expires_at"
            }
        }

        return try await supabase
            .from("partner_codes")
            .insert(Insert(
                code: code,
                partnerName: partnerName,
                partnerType: partnerType,
                maxUses: maxUses,
                expiresAt: expiresAt
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func deactivatePartnerCode(id: UUID) async throws {
        try await supabase
            .from("partner_codes")
            .update(["is_active": false])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Realtime: live taakupdates voor elderly/familie

    /// Realtime-abonnement op de eigen taken. Draait inline zolang de aanroepende
    /// Task leeft; bij annuleren (uitloggen / scherm sluiten) wordt het kanaal
    /// netjes opgezegd, zodat er geen kanalen blijven hangen.
    func subscribeToTaskUpdates(elderlyId: UUID, onUpdate: @escaping (DBTask) -> Void) async {
        let channel = supabase.realtimeV2.channel("tasks-\(elderlyId.uuidString)")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "tasks",
            filter: .eq("elderly_id", value: elderlyId.uuidString)
        )

        try? await channel.subscribeWithError()

        await withTaskCancellationHandler {
            for await change in changes {
                // Iedere wijziging (aannemen, inchecken, annuleren) triggert een
                // verse ophaling; de payload zelf gebruiken we niet strikt.
                if case let .update(action) = change,
                   let task = try? action.decodeRecord(as: DBTask.self, decoder: JSONDecoder()) {
                    await MainActor.run { onUpdate(task) }
                }
            }
        } onCancel: {
            Task { await channel.unsubscribe() }
        }
    }
}
