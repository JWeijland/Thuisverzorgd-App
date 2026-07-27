import Foundation

enum BuddieNotification {
    case newTaskInArea(elderlyName: String, distanceKm: Double)
    case priorityFavorite(elderlyName: String)
    case taskAccepted(buddyName: String, etaMinutes: Int)
    case taskReassigned(elderlyName: String)
    case buddyArrived(buddyName: String)
    case taskCompleted
    case sosTriggered(elderlyName: String)
    case familyReviewReminder(elderlyName: String)

    var title: String {
        switch self {
        case .newTaskInArea(let name, let dist):
            return "\(name) zoekt gezelschap, \(String(format: "%.1f", dist)) km bij je vandaan"
        case .priorityFavorite(let name):
            return "\(name) vraagt hulp! Jij hebt 5 min voorrang."
        case .taskAccepted(let buddy, let eta):
            return "\(buddy) komt over \(eta) min."
        case .taskReassigned(let name):
            return "De buddy van \(name) is verhinderd. We zoeken iemand anders."
        case .buddyArrived(let buddy):
            return "\(buddy) staat voor de deur."
        case .taskCompleted:
            return "Bezoek afgerond. Bekijk het verslag."
        case .sosTriggered(let name):
            return "🚨 SOS van \(name), bel direct."
        case .familyReviewReminder(let name):
            return "\(name) heeft het bezoek nog niet beoordeeld. Wil jij even een beoordeling achterlaten?"
        }
    }

    var icon: String {
        switch self {
        case .newTaskInArea: return "mappin.circle.fill"
        case .priorityFavorite: return "heart.fill"
        case .taskAccepted: return "person.fill.checkmark"
        case .taskReassigned: return "arrow.triangle.2.circlepath"
        case .buddyArrived: return "door.sliding.open"
        case .taskCompleted: return "checkmark.seal.fill"
        case .sosTriggered: return "exclamationmark.triangle.fill"
        case .familyReviewReminder: return "star.bubble.fill"
        }
    }
}
