import UIKit
import UserNotifications
import Supabase

// ============================================================
// Pushnotificaties (APNs)
//
// Flow:
//  1. Na een succesvolle login vraagt de app toestemming en registreert
//     zich bij APNs (registerForPushNotifications).
//  2. Apple levert een device token aan in de AppDelegate.
//  3. Zodra we zowel een token als een ingelogde gebruiker hebben, wordt het
//     token (met rol) opgeslagen in de Supabase-tabel device_tokens.
//  4. De Edge Function "notify-new-task" leest die tabel en stuurt bij een
//     nieuw open hulpverzoek een push naar alle buddies.
// ============================================================

// MARK: - AppDelegate (alleen voor remote-notification callbacks)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Apple levert het device token aan.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await PushManager.shared.didReceive(token: token) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] Registratie bij APNs mislukt: \(error.localizedDescription)")
    }

    // Toon de melding ook als de app op de voorgrond staat.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

// MARK: - PushManager

@MainActor
final class PushManager {
    static let shared = PushManager()
    private init() {}

    private var token: String?
    private var userId: UUID?
    private var role: String?

    /// Vraagt notificatie-toestemming en registreert bij APNs.
    /// Roep dit aan na een succesvolle login.
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error { print("[Push] Toestemming-fout: \(error.localizedDescription)") }
            guard granted else {
                print("[Push] Gebruiker gaf geen toestemming voor notificaties.")
                return
            }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Door de AppDelegate aangeroepen zodra het APNs-token binnen is.
    func didReceive(token: String) async {
        self.token = token
        await uploadIfPossible()
    }

    /// Door AppState aangeroepen zodra de gebruiker is ingelogd.
    func setUser(userId: UUID, role: String) async {
        self.userId = userId
        self.role = role
        await uploadIfPossible()
    }

    /// Bij uitloggen: verwijder het token van dit toestel zodat de gebruiker
    /// geen pushes meer krijgt en een volgende gebruiker schoon begint.
    func clearOnSignOut() async {
        if let token {
            try? await DeviceTokenService().delete(token: token)
        }
        userId = nil
        role = nil
    }

    private func uploadIfPossible() async {
        guard let token, let userId, let role else { return }
        do {
            try await DeviceTokenService().upsert(userId: userId, token: token, role: role)
            print("[Push] Device token opgeslagen voor rol \(role).")
        } catch {
            print("[Push] Opslaan device token mislukt: \(error)")
        }
    }
}

// MARK: - DeviceTokenService (Supabase)

struct DeviceTokenService {

    private struct Row: Encodable {
        let userId: UUID
        let token: String
        let platform: String
        let role: String
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case token, platform, role
        }
    }

    /// Slaat het token op (of werkt het bij als het al bestaat — conflict op token).
    func upsert(userId: UUID, token: String, role: String) async throws {
        try await supabase
            .from("device_tokens")
            .upsert(Row(userId: userId, token: token, platform: "ios", role: role), onConflict: "token")
            .execute()
    }

    func delete(token: String) async throws {
        try await supabase
            .from("device_tokens")
            .delete()
            .eq("token", value: token)
            .execute()
    }
}
