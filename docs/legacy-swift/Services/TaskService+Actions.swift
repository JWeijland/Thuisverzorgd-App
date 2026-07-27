//  TaskService+Actions.swift
//  Verplaatst uit TaskService.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import Supabase

extension TaskService {

    // MARK: - Taak aanmaken

    func createTask(
        elderlyId: UUID,
        category: String,
        timingType: String,
        scheduledAt: Date? = nil,
        note: String,
        elderlyFirstName: String,
        latitude: Double?,
        longitude: Double?
    ) async throws -> DBTask {
        struct Insert: Encodable {
            let elderlyId: UUID
            let category: String
            let timingType: String
            let scheduledAt: Date?
            let note: String
            let elderlyFirstName: String
            let elderlyLatitude: Double?
            let elderlyLongitude: Double?
            enum CodingKeys: String, CodingKey {
                case elderlyId = "elderly_id"
                case category
                case timingType  = "timing_type"
                case scheduledAt = "scheduled_at"
                case note
                case elderlyFirstName = "elderly_first_name"
                case elderlyLatitude  = "elderly_latitude"
                case elderlyLongitude = "elderly_longitude"
            }
        }

        return try await supabase
            .from("tasks")
            .insert(Insert(
                elderlyId: elderlyId,
                category: category,
                timingType: timingType,
                scheduledAt: scheduledAt,
                note: note,
                elderlyFirstName: elderlyFirstName,
                elderlyLatitude: latitude,
                elderlyLongitude: longitude
            ))
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Taak namens een cliënt (familie/admin) — via RPC

    /// Maakt een hulpvraag aan voor een gekoppelde cliënt. De locatie wordt
    /// server-side van de cliënt genomen (zie create_task_for_elderly, fase21).
    func createTaskForElderly(
        elderlyId: UUID, category: String, timingType: String,
        scheduledAt: Date?, note: String
    ) async throws -> DBTask {
        struct Params: Encodable {
            let p_elderly_id: UUID
            let p_category: String
            let p_timing_type: String
            let p_scheduled_at: Date?
            let p_note: String
        }
        return try await supabase
            .rpc("create_task_for_elderly", params: Params(
                p_elderly_id: elderlyId, p_category: category, p_timing_type: timingType,
                p_scheduled_at: scheduledAt, p_note: note
            ))
            .execute()
            .value
    }

    // MARK: - Taak accepteren (buddy)

    /// Neemt een hulpvraag aan via de atomische `accept_task`-RPC (fase24).
    /// Geeft `true` terug als déze buddy de taak echt heeft geclaimd, `false`
    /// als een andere buddy net eerder was (taak niet meer 'open'). De RPC
    /// gebruikt `auth.uid()` als buddy, dus claimen namens iemand anders kan niet.
    func acceptTask(taskId: UUID, etaMinutes: Int) async throws -> Bool {
        struct Params: Encodable {
            let pTaskId: UUID
            let pEtaMinutes: Int
            enum CodingKeys: String, CodingKey {
                case pTaskId    = "p_task_id"
                case pEtaMinutes = "p_eta_minutes"
            }
        }

        // De RPC geeft de bijgewerkte taakrij terug, of NULL als er niets te
        // claimen viel (iemand was eerder).
        let claimed: DBTask? = try await supabase
            .rpc("accept_task", params: Params(pTaskId: taskId, pEtaMinutes: etaMinutes))
            .execute()
            .value
        return claimed != nil
    }

    // MARK: - Selfie upload bij check-in

    /// PRIVACY: een check-in-selfie is een foto van de buddy bij de cliënt thuis.
    /// De 'check-in-selfies'-bucket is privé; we bewaren enkel het opslagpad (geen
    /// openbare URL). Wie de foto mag zien (bijv. admin) haalt 'm op met een
    /// tijdelijke signed URL. Pad bevat de buddy-map zodat RLS schrijven tot de
    /// eigen bestanden kan beperken.
    func uploadCheckInSelfie(imageData: Data, taskId: UUID, buddyId: UUID) async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        // Kleine letters in de mapnaam: storage-RLS matcht op auth.uid()::text.
        let path = "\(buddyId.uuidString.lowercased())/\(taskId.uuidString.lowercased())_\(timestamp).jpg"
        try await supabase.storage
            .from("check-in-selfies")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Tijdelijke (1 uur) link om een check-in-selfie te bekijken (privé-bucket).
    func checkInSelfieSignedURL(path: String) async throws -> URL {
        try await supabase.storage
            .from("check-in-selfies")
            .createSignedURL(path: path, expiresIn: 3600)
    }

    // MARK: - Buddy aankomst

    func markArrived(taskId: UUID, selfieUrl: String? = nil) async throws {
        struct Update: Encodable {
            let status: String
            let arrivedAt: Date
            let checkInSelfieUrl: String?
            enum CodingKeys: String, CodingKey {
                case status
                case arrivedAt        = "arrived_at"
                case checkInSelfieUrl = "check_in_selfie_url"
            }
        }

        try await supabase
            .from("tasks")
            .update(Update(status: "arrived", arrivedAt: Date(), checkInSelfieUrl: selfieUrl))
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    // MARK: - Taak terugzetten naar 'open' (buddy annuleert na aannemen)

    func reopenTask(taskId: UUID) async throws {
        struct Update: Encodable {
            let status: String
            let assignedBuddyId: UUID?
            let buddyEtaMinutes: Int?
            let arrivedAt: Date?
            enum CodingKeys: String, CodingKey {
                case status
                case assignedBuddyId = "assigned_buddy_id"
                case buddyEtaMinutes = "buddy_eta_minutes"
                case arrivedAt       = "arrived_at"
            }
        }
        try await supabase
            .from("tasks")
            .update(Update(status: "open", assignedBuddyId: nil, buddyEtaMinutes: nil, arrivedAt: nil))
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    /// De hulpvrager stuurt zijn toegewezen buddy een persoonlijk bericht. De edge
    /// function levert het als push + inbox-melding af bij de buddy en controleert
    /// server-side dat de beller ook echt de hulpvrager van deze taak is.
    func sendMessageToBuddy(taskId: UUID, text: String) async throws {
        struct Body: Encodable { let taskId: String; let text: String }
        try await supabase.functions.invoke(
            "notify-buddy-message",
            options: .init(body: Body(taskId: taskId.uuidString, text: text))
        )
    }

    // MARK: - SOS-melding vastleggen

    func logSOS(elderlyId: UUID, notes: String = "") async throws {
        struct Insert: Encodable {
            let elderlyId: UUID
            let notes: String
            enum CodingKeys: String, CodingKey {
                case elderlyId = "elderly_id"
                case notes
            }
        }
        try await supabase
            .from("sos_events")
            .insert(Insert(elderlyId: elderlyId, notes: notes))
            .execute()
    }

    // MARK: - Bezoek gestart (oudere bevestigt check-in)

    func markInProgress(taskId: UUID) async throws {
        try await supabase
            .from("tasks")
            .update(["status": "in_progress"])
            .eq("id", value: taskId.uuidString)
            .execute()
    }

    /// De hulpvrager (of familie) trekt de hulpvraag in. RLS staat dit toe omdat
    /// elderly_id = auth.uid(). De buddy-poll ziet de taak daarna verdwijnen.
    func cancelTask(taskId: UUID) async throws {
        try await supabase
            .from("tasks")
            .update(["status": "cancelled"])
            .eq("id", value: taskId.uuidString)
            .execute()
    }
}
