import Foundation

// MARK: - SMS

protocol SMSService {
    func sendSMS(to phoneNumber: String, message: String)
}

// TODO[real-integration]: Replace with Twilio SMS API
struct MockSMSService: SMSService {
    func sendSMS(to phoneNumber: String, message: String) {
        print("[MockSMS] To: \(phoneNumber) — \(message)")
    }
}

// MARK: - Push

protocol PushService {
    func send(notification: BuddieNotification)
}

// TODO[real-integration]: Replace with APNs/OneSignal
struct MockPushService: PushService {
    func send(notification: BuddieNotification) {
        print("[MockPush] \(notification.title)")
    }
}

