import Foundation
import CoreLocation
import SwiftUI

// ============================================================
// Live-modus: koppelt de UI aan het echte Supabase-project.
//
// Demo-modus (isDemoMode) blijft volledig op mockdata draaien. Zodra een
// gebruiker echt is ingelogd (realUserId != nil en geen demo), schakelt de
// app over op deze live-paden: hulpvragen gaan naar de tasks-tabel en de
// buddy haalt open verzoeken op uit Supabase.
// ============================================================

extension AppState {

    /// True zodra de gebruiker echt is ingelogd (geen demo).
    var isLive: Bool { !isDemoMode && realUserId != nil }

    // MARK: Datumhulp

    static func parseISO(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }

    static func dbTiming(_ timing: TaskTiming) -> (type: String, scheduledAt: Date?) {
        switch timing {
        case .now:
            return ("now", nil)
        case .today(let hour):
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = hour
            comps.minute = 0
            return ("today", Calendar.current.date(from: comps))
        case .scheduled(let date):
            return ("scheduled", date)
        }
    }

    static func timing(fromType type: String, scheduledAt: String?) -> TaskTiming {
        switch type {
        case "scheduled":
            if let s = scheduledAt, let d = parseISO(s) { return .scheduled(date: d) }
            return .now
        case "today":
            if let s = scheduledAt, let d = parseISO(s) {
                return .today(hour: Calendar.current.component(.hour, from: d))
            }
            return .now
        default:
            return .now
        }
    }

    /// Is dit een echt opgeloste coördinaat (dus niet het default Amsterdam-
    /// centrum of (0,0))? Zo bepalen we of we het adres nog moeten geocoderen.
    static func isResolvedCoordinate(_ c: CLLocationCoordinate2D) -> Bool {
        let a = MockData.amsterdamCenter
        let nearDefault = abs(c.latitude - a.latitude) < 0.0005 && abs(c.longitude - a.longitude) < 0.0005
        let isZero = c.latitude == 0 && c.longitude == 0
        return !nearDefault && !isZero
    }

    // MARK: DBTask → ServiceTask

    static func serviceTask(from db: DBTask) -> ServiceTask {
        let coordinate = CLLocationCoordinate2D(
            latitude:  db.elderlyLatitude  ?? MockData.amsterdamCenter.latitude,
            longitude: db.elderlyLongitude ?? MockData.amsterdamCenter.longitude
        )
        return ServiceTask(
            id: db.id,
            elderlyName: db.elderlyFirstName ?? "Iemand in de buurt",
            elderlyAddress: "",
            coordinate: coordinate,
            category: TaskCategory(dbValue: db.category),
            timing: timing(fromType: db.timingType, scheduledAt: db.scheduledAt),
            note: db.note,
            status: TaskStatus(dbValue: db.status),
            createdAt: parseISO(db.createdAt) ?? Date(),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: db.buddyEtaMinutes,
            assignedBuddyId: db.assignedBuddyId,
            elderlyId: db.elderlyId,
            visibility: db.visibility ?? "pool"
        )
    }
}
