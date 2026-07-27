import Foundation
import CoreLocation

/// Bepaalt welke buddies in aanmerking komen voor een nieuwe taakaanvraag,
/// en in welke volgorde ze gevraagd moeten worden.
///
/// Volgorde-criteria (in deze prioriteit):
/// 1. Ervaring met de gevraagde TaskCategory (meer voltooide taken = hoger)
/// 2. Afstand tot het adres van de oudere (dichterbij = hoger)
/// 3. Gemiddelde rating (hoger = hoger)
struct MatchingService {

    struct Match: Identifiable {
        let buddy: BuddyUser
        let distanceMeters: Double
        let experienceCount: Int
        let isExperienced: Bool
        var id: UUID { buddy.id }
    }

    /// Vindt en rankt buddies die geschikt zijn voor de taak.
    ///
    /// - Parameters:
    ///   - task: de openstaande taak
    ///   - buddies: alle buddies in het systeem
    func rankBuddies(
        for task: ServiceTask,
        from buddies: [BuddyUser]
    ) -> [Match] {
        let targetLoc = CLLocation(latitude: task.coordinate.latitude, longitude: task.coordinate.longitude)
        let allowedServiceNames = BuddyServiceCatalog.serviceNames(for: task.category)

        let matches: [Match] = buddies.compactMap { buddy in
            // 1. Moet beschikbaar zijn en taken mogen aannemen (VOG + intake)
            guard buddy.isAvailableNow, buddy.canAcceptTasks else { return nil }

            // 2. Voorkeuren-filter — alleen toepassen als de buddy voorkeuren heeft opgegeven
            if !buddy.preferredServices.isEmpty {
                let overlap = buddy.preferredServices.intersection(allowedServiceNames)
                guard !overlap.isEmpty else { return nil }
            }

            // 3. Afstand-filter (eigen maxDistanceKm van de buddy)
            let buddyLoc = CLLocation(latitude: buddy.coordinate.latitude, longitude: buddy.coordinate.longitude)
            let distance = targetLoc.distance(from: buddyLoc)
            let maxMeters = Double(buddy.maxDistanceKm) * 1000.0
            guard distance <= maxMeters else { return nil }

            let exp = buddy.completedTasksByCategory[task.category] ?? 0
            return Match(
                buddy: buddy,
                distanceMeters: distance,
                experienceCount: exp,
                isExperienced: exp >= 3
            )
        }

        // Sorteer: ervaring desc → afstand asc → rating desc
        return matches.sorted { a, b in
            if a.experienceCount != b.experienceCount {
                return a.experienceCount > b.experienceCount
            }
            if a.distanceMeters != b.distanceMeters {
                return a.distanceMeters < b.distanceMeters
            }
            return a.buddy.ratingAverage > b.buddy.ratingAverage
        }
    }

    /// Stuurt mock-push aan alle matchende buddies wanneer een taak wordt aangemaakt.
    func notifyMatchedBuddies(
        matches: [Match],
        task: ServiceTask,
        push: PushService = MockPushService()
    ) {
        for match in matches {
            let distKm = match.distanceMeters / 1000.0
            push.send(notification: .newTaskInArea(
                elderlyName: task.elderlyName,
                distanceKm: distKm
            ))
        }
    }
}
