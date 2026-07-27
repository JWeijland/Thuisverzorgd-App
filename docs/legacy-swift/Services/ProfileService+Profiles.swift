//  ProfileService+Profiles.swift
//  Verplaatst uit ProfileService.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import Supabase

extension ProfileService {

    // MARK: - Voorkeuren (oudere + buddy)

    /// Bewaar oudere-voorkeuren (grote letters / formeel aanspreken).
    func updateElderlyPreferences(elderlyId: UUID, largeText: Bool, prefersFormal: Bool) async throws {
        struct U: Encodable {
            let largeTextEnabled: Bool
            let prefersFormal: Bool
            enum CodingKeys: String, CodingKey {
                case largeTextEnabled = "large_text_enabled"
                case prefersFormal    = "prefers_formal"
            }
        }
        try await supabase.from("elderly_profiles")
            .update(U(largeTextEnabled: largeText, prefersFormal: prefersFormal))
            .eq("id", value: elderlyId.uuidString).execute()
    }

    /// Slaat het adres + de geocodeerde coördinaat van de oudere op, zodat de
    /// druppel op de buddy-kaart op het juiste adres komt te staan in plaats van
    /// op het default-punt. Een gewone UPDATE valt onder de RLS-policy "Elderly
    /// kan eigen profiel updaten"; de rij bestaat altijd al (aangemaakt door de
    /// handle_new_user-trigger bij registratie), dus upsert is niet nodig.
    func updateElderlyLocation(elderlyId: UUID, address: String,
                               latitude: Double?, longitude: Double?) async throws {
        struct U: Encodable {
            let address: String
            let latitude: Double?
            let longitude: Double?
        }
        try await supabase.from("elderly_profiles")
            .update(U(address: address, latitude: latitude, longitude: longitude))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Zorgkring-pivot (fase35): teamvoorkeur van de hulpvrager
    /// ('team' of 'random_only').
    func updateElderlyTeamMode(elderlyId: UUID, teamMode: String) async throws {
        struct U: Encodable {
            let teamMode: String
            enum CodingKeys: String, CodingKey { case teamMode = "team_mode" }
        }
        try await supabase.from("elderly_profiles")
            .update(U(teamMode: teamMode))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Bewaart het geboortejaar van de cliënt (voor de leeftijdsweergave).
    func updateElderlyBirthYear(elderlyId: UUID, birthYear: Int?) async throws {
        struct U: Encodable { let birthYear: Int?; enum CodingKeys: String, CodingKey { case birthYear = "birth_year" } }
        try await supabase.from("elderly_profiles")
            .update(U(birthYear: birthYear))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Bewaart de volledige geboortedatum (dag/maand/jaar) van de cliënt en houdt
    /// het geboortejaar in sync voor de geaggregeerde analytics. Zo klopt de
    /// getoonde leeftijd exact.
    func updateElderlyDateOfBirth(elderlyId: UUID, date: Date?) async throws {
        struct U: Encodable {
            let dateOfBirth: String?
            let birthYear: Int?
            enum CodingKeys: String, CodingKey {
                case dateOfBirth = "date_of_birth"
                case birthYear   = "birth_year"
            }
        }
        let dob = date.map { BCBirthDate.dbString(from: $0) }
        let year = date.map { Calendar.current.component(.year, from: $0) }
        try await supabase.from("elderly_profiles")
            .update(U(dateOfBirth: dob, birthYear: year))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Bewaart het telefoonnummer van de cliënt. Dit staat op de `profiles`-tabel
    /// (kolom phone_number), niet op elderly_profiles. De RLS-policy "Eigen profiel
    /// updaten" laat de ingelogde gebruiker z'n eigen rij bijwerken; de rij bestaat
    /// al (handle_new_user-trigger), dus een gewone UPDATE volstaat.
    func updateElderlyPhoneNumber(elderlyId: UUID, phoneNumber: String?) async throws {
        struct U: Encodable {
            let phoneNumber: String?
            enum CodingKeys: String, CodingKey { case phoneNumber = "phone_number" }
        }
        try await supabase.from("profiles")
            .update(U(phoneNumber: phoneNumber))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Werkt de HUIDIGE locatie van de buddy bij (los van het thuisadres). Bron
    /// voor de 500m-meldingen onderweg (fase27). location_updated_at laat de edge
    /// function verouderde posities negeren.
    func updateBuddyCurrentLocation(buddyId: UUID, latitude: Double, longitude: Double) async throws {
        struct U: Encodable {
            let currentLatitude: Double
            let currentLongitude: Double
            let locationUpdatedAt: Date
            enum CodingKeys: String, CodingKey {
                case currentLatitude   = "current_latitude"
                case currentLongitude  = "current_longitude"
                case locationUpdatedAt = "location_updated_at"
            }
        }
        try await supabase.from("buddy_profiles")
            .update(U(currentLatitude: latitude, currentLongitude: longitude, locationUpdatedAt: Date()))
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Huidige locatie van een buddy ophalen (voor de oudere die live wil zien
    /// waar de buddy onderweg is). buddy_profiles is publiek leesbaar voor matching.
    struct BuddyLiveLocation: Decodable {
        let currentLatitude: Double?
        let currentLongitude: Double?
        let locationUpdatedAt: String?
        enum CodingKeys: String, CodingKey {
            case currentLatitude   = "current_latitude"
            case currentLongitude  = "current_longitude"
            case locationUpdatedAt = "location_updated_at"
        }
    }

    func fetchBuddyCurrentLocation(buddyId: UUID) async throws -> BuddyLiveLocation {
        try await supabase.from("buddy_profiles")
            .select("current_latitude,current_longitude,location_updated_at")
            .eq("id", value: buddyId.uuidString)
            .single()
            .execute()
            .value
    }

    /// Bewaart de volledige geboortedatum (dag/maand/jaar) van de buddy en houdt
    /// het geboortejaar in sync voor de geaggregeerde analytics.
    func updateBuddyDateOfBirth(buddyId: UUID, date: Date?) async throws {
        struct U: Encodable {
            let dateOfBirth: String?
            enum CodingKeys: String, CodingKey { case dateOfBirth = "date_of_birth" }
        }
        let dob = date.map { BCBirthDate.dbString(from: $0) }
        try await supabase.from("buddy_profiles")
            .update(U(dateOfBirth: dob))
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Bewaart de "Over mij"-tekst (bio) van een buddy.
    func updateBuddyBio(buddyId: UUID, bio: String) async throws {
        struct U: Encodable { let bio: String }
        try await supabase.from("buddy_profiles")
            .update(U(bio: bio))
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Bewaart het thuisadres + grove coördinaat van een buddy, zodat de server
    /// "hulpvraag in je buurt"-pushes kan filteren op afstand. De rij bestaat al
    /// (handle_new_user). latitude/longitude mogen nil zijn als geocoderen faalde.
    func updateBuddyLocation(buddyId: UUID, address: String,
                             latitude: Double?, longitude: Double?) async throws {
        struct U: Encodable {
            let address: String
            let latitude: Double?
            let longitude: Double?
        }
        try await supabase.from("buddy_profiles")
            .update(U(address: address, latitude: latitude, longitude: longitude))
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Upload de profielfoto van een buddy naar de privé 'avatars'-bucket.
    ///
    /// PRIVACY: de bucket is niet meer openbaar. We bewaren alléén het pad
    /// (`<uid>.jpg`) op het profiel — geen openbare URL. De foto wordt opgehaald
    /// met een geauthenticeerde download (eigen foto) of een tijdelijke signed URL
    /// (ranglijsten), zodat een profielfoto nooit anoniem/openbaar te benaderen is.
    /// RLS waarborgt dat een buddy alleen z'n eigen `<uid>.jpg` mag schrijven.
    @discardableResult
    func uploadBuddyAvatar(buddyId: UUID, imageData: Data) async throws -> String {
        // Kleine letters: storage-RLS matcht op auth.uid()::text (zie uploadVOGDocument).
        let path = "\(buddyId.uuidString.lowercased()).jpg"
        try await supabase.storage
            .from("avatars")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        try await supabase.from("buddy_profiles")
            .update(["avatar_url": path])
            .eq("id", value: buddyId.uuidString)
            .execute()
        return path
    }

    /// Upload de profielfoto van een hulpvrager (cliënt) naar de privé 'avatars'-
    /// bucket op het deterministische pad `<uid>.jpg`. Dezelfde RLS als bij buddies
    /// (een gebruiker mag alleen z'n eigen `<uid>.jpg` schrijven), dus dit werkt zonder
    /// extra migratie. Het pad volgt uit de user-UUID, dus ophalen kan zonder DB-kolom.
    @discardableResult
    func uploadElderlyAvatar(elderlyId: UUID, imageData: Data) async throws -> String {
        let path = "\(elderlyId.uuidString.lowercased()).jpg"
        try await supabase.storage
            .from("avatars")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Tijdelijke (1 uur) link om de profielfoto van een buddy te tonen in de
    /// ranglijsten. Werkt alleen voor ingelogde gebruikers (bucket is privé).
    func avatarSignedURL(buddyId: UUID) async throws -> URL {
        try await supabase.storage
            .from("avatars")
            .createSignedURL(path: "\(buddyId.uuidString.lowercased()).jpg", expiresIn: 3600)
    }

    /// Bewaart de zichtbaarheidsvoorkeuren van een buddy (punt 13, fase31).
    func updateBuddyVisibility(buddyId: UUID, showsBio: Bool,
                               showsNeighborhood: Bool, showsBirthdate: Bool) async throws {
        struct U: Encodable {
            let showsBio: Bool
            let showsNeighborhood: Bool
            let showsBirthdate: Bool
            enum CodingKeys: String, CodingKey {
                case showsBio          = "shows_bio"
                case showsNeighborhood = "shows_neighborhood"
                case showsBirthdate    = "shows_birthdate"
            }
        }
        try await supabase.from("buddy_profiles")
            .update(U(showsBio: showsBio, showsNeighborhood: showsNeighborhood, showsBirthdate: showsBirthdate))
            .eq("id", value: buddyId.uuidString)
            .execute()
    }

    /// Bewaart de zichtbaarheidsvoorkeuren van een oudere (punt 13, fase31).
    func updateElderlyVisibility(elderlyId: UUID, showsPhone: Bool,
                                 showsAddress: Bool, showsBirthdate: Bool) async throws {
        struct U: Encodable {
            let showsPhone: Bool
            let showsAddress: Bool
            let showsBirthdate: Bool
            enum CodingKeys: String, CodingKey {
                case showsPhone     = "shows_phone"
                case showsAddress   = "shows_address"
                case showsBirthdate = "shows_birthdate"
            }
        }
        try await supabase.from("elderly_profiles")
            .update(U(showsPhone: showsPhone, showsAddress: showsAddress, showsBirthdate: showsBirthdate))
            .eq("id", value: elderlyId.uuidString)
            .execute()
    }

    /// Bewaar de welzijn-services die een buddy wil doen.
    func updateBuddyServices(buddyId: UUID, services: [String]) async throws {
        try await supabase.from("buddy_profiles")
            .update(["preferred_services": services])
            .eq("id", value: buddyId.uuidString).execute()
    }

    // MARK: - Favoriete buddies

    struct FavoriteRow: Decodable {
        let buddyId: UUID
        let buddyName: String
        enum CodingKeys: String, CodingKey {
            case buddyId   = "buddy_id"
            case buddyName = "buddy_name"
        }
    }

    func fetchFavorites(elderlyId: UUID) async throws -> [FavoriteRow] {
        try await supabase.from("favorite_buddies")
            .select("buddy_id,buddy_name")
            .eq("elderly_id", value: elderlyId.uuidString)
            .execute().value
    }

    func addFavorite(elderlyId: UUID, buddyId: UUID, buddyName: String, elderlyName: String = "") async throws {
        struct Insert: Encodable {
            let elderlyId: UUID
            let buddyId: UUID
            let buddyName: String
            let elderlyName: String
            enum CodingKeys: String, CodingKey {
                case elderlyId   = "elderly_id"
                case buddyId     = "buddy_id"
                case buddyName   = "buddy_name"
                case elderlyName = "elderly_name"
            }
        }
        try await supabase.from("favorite_buddies")
            .upsert(Insert(elderlyId: elderlyId, buddyId: buddyId,
                           buddyName: buddyName, elderlyName: elderlyName),
                    onConflict: "elderly_id,buddy_id")
            .execute()
    }

    /// Voor de BUDDY: wie heeft mij als vaste buddy gekozen? (RLS: "Buddy ziet
    /// eigen fans".) elderly_name is gedenormaliseerd zodat geen join nodig is.
    struct FanRow: Decodable {
        let elderlyId: UUID
        let elderlyName: String
        enum CodingKeys: String, CodingKey {
            case elderlyId   = "elderly_id"
            case elderlyName = "elderly_name"
        }
    }

    func fetchFans(buddyId: UUID) async throws -> [FanRow] {
        try await supabase.from("favorite_buddies")
            .select("elderly_id,elderly_name")
            .eq("buddy_id", value: buddyId.uuidString)
            .execute().value
    }

    /// Laat de edge function de buddy verrassen met push + inbox-bericht dat
    /// hij/zij als vaste buddy is gekozen (zie supabase/functions/notify-favorite-buddy).
    func notifyFavoriteBuddy(buddyId: UUID) async throws {
        struct Body: Encodable { let buddyId: String }
        try await supabase.functions.invoke(
            "notify-favorite-buddy",
            options: .init(body: Body(buddyId: buddyId.uuidString))
        )
    }

    func removeFavorite(elderlyId: UUID, buddyId: UUID) async throws {
        try await supabase.from("favorite_buddies")
            .delete()
            .eq("elderly_id", value: elderlyId.uuidString)
            .eq("buddy_id", value: buddyId.uuidString)
            .execute()
    }

    // MARK: - Overgeslagen beoordelingen

    struct SkippedRow: Decodable {
        let taskId: UUID
        enum CodingKeys: String, CodingKey { case taskId = "task_id" }
    }

    func fetchSkippedReviews(reviewerId: UUID) async throws -> [UUID] {
        let rows: [SkippedRow] = try await supabase.from("skipped_reviews")
            .select("task_id")
            .eq("reviewer_id", value: reviewerId.uuidString)
            .execute().value
        return rows.map(\.taskId)
    }

    func addSkippedReview(reviewerId: UUID, taskId: UUID) async throws {
        struct Insert: Encodable {
            let reviewerId: UUID
            let taskId: UUID
            enum CodingKeys: String, CodingKey {
                case reviewerId = "reviewer_id"
                case taskId     = "task_id"
            }
        }
        try await supabase.from("skipped_reviews")
            .upsert(Insert(reviewerId: reviewerId, taskId: taskId), onConflict: "reviewer_id,task_id")
            .execute()
    }

    func removeSkippedReview(reviewerId: UUID, taskId: UUID) async throws {
        try await supabase.from("skipped_reviews")
            .delete()
            .eq("reviewer_id", value: reviewerId.uuidString)
            .eq("task_id", value: taskId.uuidString)
            .execute()
    }
}
