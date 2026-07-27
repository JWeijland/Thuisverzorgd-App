import Foundation
import CoreLocation

/// Houdt de HUIDIGE locatie van een beschikbare buddy bij, zodat de server kan
/// bepalen of een nieuwe hulpvraag binnen 500 m van waar de buddy nú is valt —
/// ook als de buddy ergens anders dan thuis is.
///
/// Aanpak (batterijvriendelijk):
/// - "Altijd"-toestemming + `startMonitoringSignificantLocationChanges()`: iOS
///   wekt de app ~elke 500 m verplaatsing, ook op de achtergrond / na afsluiten.
/// - Plus een one-shot bij het openen van de app en bij beschikbaar worden.
/// - Schrijven naar Supabase wordt afgeknepen: hooguit eens per 10 min, of zodra
///   de buddy ≥150 m is verplaatst.
final class BuddyLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = BuddyLocationManager()

    private let manager = CLLocationManager()
    private var isTracking = false
    private var lastWriteAt: Date?
    private var lastWrittenCoord: CLLocationCoordinate2D?

    /// Tijdens een lopende taak (buddy onderweg) volgen we nauwkeuriger zodat de
    /// oudere de buddy vloeiend ziet bewegen; daarbuiten zuinig.
    private var highPrecision = false

    /// Persisteer-callback (gezet door AppState): schrijft de positie naar Supabase.
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    // Schrijf-throttle: zuinig in rust, vlotter (maar nog steeds afgeknepen)
    // tijdens een rit, zodat de live kaart soepel oogt zonder de batterij leeg te
    // trekken.
    private var minWriteInterval: TimeInterval { highPrecision ? 25 : 10 * 60 }
    private var minWriteDistance: CLLocationDistance { highPrecision ? 40 : 150 }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Schakelt tussen "zuinig wachten" (significante locatiewijzigingen, ~100 m)
    /// en "nauwkeuriger onderweg" (continue updates met ~40 m filter, ten-meter
    /// nauwkeurigheid). Het nauwkeurige deel draait alléén tijdens de korte rit
    /// naar de oudere, dus de batterij-impact blijft beperkt.
    func setHighPrecision(_ on: Bool) {
        guard highPrecision != on else { return }
        highPrecision = on
        guard isTracking else { return }
        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        if on {
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 40
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = kCLDistanceFilterNone
        }
    }

    /// Start het bijhouden (idempotent). Vraagt toestemming als die er nog niet is.
    func start() {
        guard !isTracking else { return }
        isTracking = true
        switch manager.authorizationStatus {
        case .notDetermined:
            // Eerst "bij gebruik"; na toekenning vragen we door naar "altijd".
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            beginUpdates()
        case .authorizedAlways:
            beginUpdates()
        default:
            break   // geweigerd → niets te doen
        }
    }

    func stop() {
        isTracking = false
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopUpdatingLocation()
        highPrecision = false
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    /// Forceer één verse positie (bijv. bij het openen van de app).
    func requestOneShot() {
        let status = manager.authorizationStatus
        guard isTracking, status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        manager.requestLocation()
    }

    private func beginUpdates() {
        if manager.authorizationStatus == .authorizedAlways {
            // Mag alleen met "Altijd" + UIBackgroundModes=location in Info.plist.
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
        }
        manager.startMonitoringSignificantLocationChanges()
        // Loopt er al een taak (onderweg)? Start dan meteen het nauwkeurigere,
        // continue volgen.
        if highPrecision {
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 40
            manager.startUpdatingLocation()
        }
        manager.requestLocation()   // meteen een eerste positie
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        guard isTracking else { return }
        switch m.authorizationStatus {
        case .authorizedWhenInUse:
            m.requestAlwaysAuthorization()
            beginUpdates()
        case .authorizedAlways:
            beginUpdates()
        default:
            break
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        maybePersist(loc)
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        // Stil: een mislukte fix lossen we op bij de volgende significante wijziging.
    }

    private func maybePersist(_ loc: CLLocation) {
        let now = Date()
        let movedFar: Bool
        if let last = lastWrittenCoord {
            movedFar = CLLocation(latitude: last.latitude, longitude: last.longitude).distance(from: loc) >= minWriteDistance
        } else {
            movedFar = true
        }
        let longEnough = lastWriteAt.map { now.timeIntervalSince($0) >= minWriteInterval } ?? true
        guard movedFar || longEnough else { return }
        lastWriteAt = now
        lastWrittenCoord = loc.coordinate
        onLocationUpdate?(loc.coordinate)
    }
}
