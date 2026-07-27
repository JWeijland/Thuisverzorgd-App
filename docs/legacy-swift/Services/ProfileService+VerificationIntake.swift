//  ProfileService+VerificationIntake.swift
//  Verplaatst uit ProfileService.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import Supabase

extension ProfileService {

    func updateBuddyAvailability(buddyId: UUID, isAvailable: Bool) async throws {
        try await supabase
            .from("buddy_profiles")
            .update(["is_available_now": isAvailable])
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Demo: zet VOG + intake op "rond" in de database, zodat de buddy taken
    /// kan aannemen zonder de echte verificatie te doorlopen.
    func updateBuddyVerification(buddyId: UUID, vogValid: Bool, intakeCompleted: Bool) async throws {
        try await supabase
            .from("buddy_profiles")
            .update([
                "vog_valid": vogValid,
                "intake_completed": intakeCompleted
            ])
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    // MARK: - VOG

    /// Model B: buddy uploadt zijn bestaande VOG-document naar de privé-bucket.
    /// Pad = {buddyId}/vog_{timestamp}.{ext} (RLS: alleen eigen map).
    func uploadVOGDocument(buddyId: UUID, data: Data, fileExtension: String, contentType: String) async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        // LET OP: kleine letters. Swift's uuidString is HOOFDLETTERS, maar de
        // storage-RLS vergelijkt de mapnaam met auth.uid()::text (kleine letters).
        // Met hoofdletters faalt elke upload met "row-level security policy".
        let path = "\(buddyId.uuidString.lowercased())/vog_\(timestamp).\(fileExtension)"
        try await supabase.storage
            .from("vog-documents")
            .upload(path, data: data, options: FileOptions(contentType: contentType, upsert: true))
        return path
    }

    /// Na upload: status op 'in_behandeling' + documentpad opslaan.
    func submitVOGUpload(buddyId: UUID, documentPath: String) async throws {
        struct U: Encodable {
            let vogStatus: String; let vogDocumentUrl: String
            enum CodingKeys: String, CodingKey { case vogStatus = "vog_status"; case vogDocumentUrl = "vog_document_url" }
        }
        try await supabase.from("buddy_profiles")
            .update(U(vogStatus: "in_behandeling", vogDocumentUrl: documentPath))
            .eq("id", value: buddyId.uuidString).execute()
    }

    /// Model A: buddy vraagt aan via Thuisverzorgd → status 'aangevraagd'.
    func requestVOG(buddyId: UUID) async throws {
        try await supabase.from("buddy_profiles")
            .update(["vog_status": "aangevraagd"])
            .eq("id", value: buddyId.uuidString).execute()
    }

    /// Admin keurt goed: status 'geldig' + vog_valid = true + verloopdatum.
    func approveVOG(buddyId: UUID, expiresAt: Date) async throws {
        struct U: Encodable {
            let vogStatus: String; let vogValid: Bool; let vogExpiresAt: Date
            enum CodingKeys: String, CodingKey {
                case vogStatus = "vog_status"; case vogValid = "vog_valid"; case vogExpiresAt = "vog_expires_at"
            }
        }
        try await supabase.from("buddy_profiles")
            .update(U(vogStatus: "geldig", vogValid: true, vogExpiresAt: expiresAt))
            .eq("id", value: buddyId.uuidString).execute()
    }

    /// Admin wijst af: status 'afgewezen' + vog_valid = false.
    func rejectVOG(buddyId: UUID) async throws {
        struct U: Encodable {
            let vogStatus: String; let vogValid: Bool
            enum CodingKeys: String, CodingKey { case vogStatus = "vog_status"; case vogValid = "vog_valid" }
        }
        try await supabase.from("buddy_profiles")
            .update(U(vogStatus: "afgewezen", vogValid: false))
            .eq("id", value: buddyId.uuidString).execute()
    }

    /// Openstaande VOG's (aangevraagd of in behandeling) met naam van de buddy.
    struct PendingVOG: Decodable, Identifiable {
        let id: UUID
        let vogStatus: String
        let vogDocumentUrl: String?
        let profile: NameRow?
        struct NameRow: Decodable {
            let firstName: String; let lastName: String
            enum CodingKeys: String, CodingKey { case firstName = "first_name"; case lastName = "last_name" }
        }
        enum CodingKeys: String, CodingKey {
            case id
            case vogStatus = "vog_status"
            case vogDocumentUrl = "vog_document_url"
            case profile
        }
        var name: String {
            [profile?.firstName, profile?.lastName].compactMap { $0 }.joined(separator: " ")
        }
    }

    func fetchPendingVOGs() async throws -> [PendingVOG] {
        do {
            return try await supabase.from("buddy_profiles")
                .select("id,vog_status,vog_document_url,profile:profiles!id(first_name,last_name)")
                .in("vog_status", values: ["aangevraagd", "in_behandeling"])
                .execute().value
        } catch {
            // Mocht de naam-join (PostgREST-embed) falen, dan tonen we de VOG's
            // alsnog — zonder naam — i.p.v. een lege lijst. Zo komt een aanvraag
            // nooit "stil" niet binnen bij de admin.
            return try await supabase.from("buddy_profiles")
                .select("id,vog_status,vog_document_url")
                .in("vog_status", values: ["aangevraagd", "in_behandeling"])
                .execute().value
        }
    }

    /// Tijdelijke (10 min) link om een geüpload VOG-document te bekijken.
    func vogSignedURL(path: String) async throws -> URL {
        try await supabase.storage.from("vog-documents").createSignedURL(path: path, expiresIn: 600)
    }

    // MARK: - Gebruikersbeheer (admin)

    /// Alle profielen ophalen (admin-only via RLS).
    func fetchAllProfiles() async throws -> [DBProfile] {
        try await supabase.from("profiles")
            .select("id,role,first_name,last_name,phone_number,created_at")
            .order("created_at", ascending: false)
            .execute().value
    }

    /// Rol van een gebruiker wijzigen (admin-only via RLS + fase9-trigger).
    func setUserRole(userId: UUID, role: String) async throws {
        try await supabase.from("profiles")
            .update(["role": role])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    /// Admin: keurt alleen de intake goed (los van VOG).
    func approveIntake(buddyId: UUID) async throws {
        try await supabase.from("buddy_profiles")
            .update(["intake_completed": true])
            .eq("id", value: buddyId.uuidString).execute()
    }

    // MARK: - Intake-videogesprek (wachtrij)

    struct DBIntakeCall: Codable, Identifiable {
        let id: UUID
        let buddyId: UUID
        var status: String
        var roomName: String
        var adminId: UUID?
        let createdAt: String
        /// Gekozen moment bij een zelf-ingepland gesprek (status 'scheduled').
        var scheduledAt: String?
        /// Optionele agenda-/videolink.
        var meetingUrl: String?
        var profile: NameRow?           // alleen ingevuld bij de admin-query
        struct NameRow: Codable {
            let firstName: String; let lastName: String
            enum CodingKeys: String, CodingKey { case firstName = "first_name"; case lastName = "last_name" }
        }
        enum CodingKeys: String, CodingKey {
            case id, status, profile
            case buddyId     = "buddy_id"
            case roomName    = "room_name"
            case adminId     = "admin_id"
            case createdAt   = "created_at"
            case scheduledAt = "scheduled_at"
            case meetingUrl  = "meeting_url"
        }
        var name: String { [profile?.firstName, profile?.lastName].compactMap { $0 }.joined(separator: " ") }

        /// Het geplande moment als `Date` (ISO8601 uit Supabase), indien aanwezig.
        var scheduledDate: Date? {
            guard let scheduledAt else { return nil }
            return ISO8601DateFormatter.intakeParsers.lazy.compactMap { $0.date(from: scheduledAt) }.first
        }
    }

    struct QueueStatus: Decodable {
        let position: Int
        let totalWaiting: Int
        enum CodingKeys: String, CodingKey {
            case position = "queue_position"
            case totalWaiting = "total_waiting"
        }
    }

    private static let intakeSelect = "id,buddy_id,status,room_name,admin_id,created_at,scheduled_at,meeting_url"

    /// Buddy: start een intake-gesprek → komt in de wachtrij ('waiting').
    func requestIntakeCall(buddyId: UUID, roomName: String) async throws -> DBIntakeCall {
        struct Insert: Encodable {
            let buddyId: UUID; let roomName: String
            enum CodingKeys: String, CodingKey { case buddyId = "buddy_id"; case roomName = "room_name" }
        }
        return try await supabase.from("intake_calls")
            .insert(Insert(buddyId: buddyId, roomName: roomName))
            .select(Self.intakeSelect)
            .single().execute().value
    }

    /// Buddy: plan zelf een intakegesprek op een gekozen moment ('scheduled').
    func scheduleIntakeCall(buddyId: UUID, roomName: String, scheduledAt: Date,
                            meetingUrl: String?) async throws -> DBIntakeCall {
        struct Insert: Encodable {
            let buddyId: UUID; let roomName: String; let status: String
            let scheduledAt: Date; let meetingUrl: String?
            enum CodingKeys: String, CodingKey {
                case buddyId = "buddy_id"; case roomName = "room_name"; case status
                case scheduledAt = "scheduled_at"; case meetingUrl = "meeting_url"
            }
        }
        return try await supabase.from("intake_calls")
            .insert(Insert(buddyId: buddyId, roomName: roomName, status: "scheduled",
                           scheduledAt: scheduledAt, meetingUrl: meetingUrl))
            .select(Self.intakeSelect)
            .single().execute().value
    }

    /// Het actieve (live) gesprek van een buddy (waiting of in_progress), indien aanwezig.
    func fetchMyActiveCall(buddyId: UUID) async throws -> DBIntakeCall? {
        let rows: [DBIntakeCall] = try await supabase.from("intake_calls")
            .select(Self.intakeSelect)
            .eq("buddy_id", value: buddyId.uuidString)
            .in("status", values: ["waiting", "in_progress"])
            .order("created_at", ascending: false)
            .limit(1).execute().value
        return rows.first
    }

    /// Het eerstvolgende zelf-ingeplande gesprek van een buddy ('scheduled').
    func fetchMyScheduledCall(buddyId: UUID) async throws -> DBIntakeCall? {
        let rows: [DBIntakeCall] = try await supabase.from("intake_calls")
            .select(Self.intakeSelect)
            .eq("buddy_id", value: buddyId.uuidString)
            .eq("status", value: "scheduled")
            .order("scheduled_at", ascending: true)
            .limit(1).execute().value
        return rows.first
    }

    /// Admin: de ingeplande gesprekken (zelf gekozen moment), oplopend op tijd.
    func fetchScheduledCalls() async throws -> [DBIntakeCall] {
        try await supabase.from("intake_calls")
            .select("\(Self.intakeSelect),profile:profiles!buddy_id(first_name,last_name)")
            .eq("status", value: "scheduled")
            .order("scheduled_at", ascending: true)
            .execute().value
    }

    /// Positie in de wachtrij + totaal aantal wachtenden (via SECURITY DEFINER-rpc).
    func fetchQueueStatus(callId: UUID) async throws -> QueueStatus {
        let rows: [QueueStatus] = try await supabase
            .rpc("intake_queue_status", params: ["p_call_id": callId.uuidString])
            .execute().value
        return rows.first ?? QueueStatus(position: 0, totalWaiting: 0)
    }

    func cancelIntakeCall(callId: UUID) async throws {
        struct U: Encodable { let status: String; let endedAt: Date
            enum CodingKeys: String, CodingKey { case status; case endedAt = "ended_at" } }
        try await supabase.from("intake_calls")
            .update(U(status: "cancelled", endedAt: Date()))
            .eq("id", value: callId.uuidString).execute()
    }

    /// Admin: de wachtrij + namen (admin mag alles lezen).
    func fetchWaitingCalls() async throws -> [DBIntakeCall] {
        try await supabase.from("intake_calls")
            .select("\(Self.intakeSelect),profile:profiles!buddy_id(first_name,last_name)")
            .in("status", values: ["waiting", "in_progress"])
            .order("created_at", ascending: true)
            .execute().value
    }

    /// Daily-room + kort geldig meeting token voor een intake-videogesprek. De
    /// edge function `intake-video` houdt de Daily REST-key server-side; de app
    /// krijgt alleen de room-URL + token terug om mee te joinen.
    struct IntakeVideoCredentials: Decodable, Sendable {
        let roomUrl: String
        let token: String
    }

    func fetchIntakeVideoCredentials(callId: UUID) async throws -> IntakeVideoCredentials {
        struct Body: Encodable { let callId: String }
        return try await supabase.functions.invoke(
            "intake-video",
            options: .init(body: Body(callId: callId.uuidString))
        ) { data, _ in
            try JSONDecoder().decode(IntakeVideoCredentials.self, from: data)
        }
    }

    /// Admin: neem het gesprek aan → 'in_progress' + admin_id + starttijd.
    func answerIntakeCall(callId: UUID, adminId: UUID) async throws {
        struct U: Encodable { let status: String; let adminId: UUID; let startedAt: Date
            enum CodingKeys: String, CodingKey { case status; case adminId = "admin_id"; case startedAt = "started_at" } }
        try await supabase.from("intake_calls")
            .update(U(status: "in_progress", adminId: adminId, startedAt: Date()))
            .eq("id", value: callId.uuidString).execute()
    }

    /// Beëindig het gesprek → 'completed'.
    func endIntakeCall(callId: UUID) async throws {
        struct U: Encodable { let status: String; let endedAt: Date
            enum CodingKeys: String, CodingKey { case status; case endedAt = "ended_at" } }
        try await supabase.from("intake_calls")
            .update(U(status: "completed", endedAt: Date()))
            .eq("id", value: callId.uuidString).execute()
    }
}

extension ISO8601DateFormatter {
    /// Twee parsers: mét en zonder fractionele seconden. Supabase levert timestamptz
    /// in beide vormen, afhankelijk van de kolom/precisie.
    static let intakeParsers: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFraction, plain]
    }()
}
