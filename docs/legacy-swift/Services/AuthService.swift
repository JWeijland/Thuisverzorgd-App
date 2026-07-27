import Foundation
import Supabase

@Observable
final class AuthService {

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentUserId: UUID? = nil
    var currentUserEmail: String? = nil
    var isLoggedIn: Bool { currentUserId != nil }

    // MARK: - App start — herstel bestaande sessie

    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id
            currentUserEmail = session.user.email
        } catch {
            // Geen actieve sessie — gebruiker moet inloggen
            currentUserId = nil
            currentUserEmail = nil
        }
    }

    // MARK: - Registratie (e-mail + wachtwoord)

    /// Returns `true` when Supabase requires email confirmation (session is nil after sign-up).
    @discardableResult
    func signUp(
        email: String,
        password: String,
        role: String,
        firstName: String,
        lastName: String,
        phoneNumber: String? = nil,
        gender: String? = nil,
        birthYear: Int? = nil,
        postcode4: String? = nil,
        organizationKey: String? = nil
    ) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        // Demografie gaat mee als user-metadata. De DB-trigger
        // (zie MEGA_PROMPT_DATA_PRIVACY_LAAG.md) schrijft dit naar profiles.
        var metadata: [String: AnyJSON] = [
            "role":       .string(role),
            "first_name": .string(firstName),
            "last_name":  .string(lastName)
        ]
        if let gender { metadata["gender"] = .string(gender) }
        if let birthYear { metadata["birth_year"] = .double(Double(birthYear)) }
        if let postcode4, !postcode4.isEmpty { metadata["postcode4"] = .string(postcode4) }
        // White-label: de gekozen vrijwilligersorganisatie (thema-sleutel). De
        // DB-trigger schrijft dit naar profiles.organization_key.
        if let organizationKey, !organizationKey.isEmpty {
            metadata["organization_key"] = .string(organizationKey)
        }

        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )

        if response.session != nil {
            currentUserId = response.user.id
            return false
        } else {
            // Email confirmation required — user exists but no active session yet
            return true
        }
    }

    // MARK: - Inloggen (e-mail + wachtwoord)

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        currentUserId = session.user.id
        currentUserEmail = session.user.email
    }

    // MARK: - Wachtwoord opnieuw instellen (stuurt reset-mail)

    func sendPasswordReset(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - SMS OTP (aanbevolen voor ouderen)

    func sendOTP(phoneNumber: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.signInWithOTP(phone: phoneNumber)
    }

    func verifyOTP(phoneNumber: String, token: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.verifyOTP(
            phone: phoneNumber,
            token: token,
            type: .sms
        )
        currentUserId = session.user.id
    }

    // MARK: - Apple Sign-In

    func signInWithApple(identityToken: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: identityToken)
        )
        currentUserId = session.user.id
    }

    // MARK: - Uitloggen

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUserId = nil
        currentUserEmail = nil
    }

    // MARK: - Foutafhandeling helper

    func withErrorHandling(_ block: () async throws -> Void) async {
        do {
            try await block()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
