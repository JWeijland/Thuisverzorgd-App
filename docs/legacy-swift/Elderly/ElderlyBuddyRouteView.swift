import SwiftUI
import MapKit
import CoreLocation

// ============================================================
// ElderlyBuddyRouteView — de oudere volgt live waar de buddy is
//
// Toont op een kaart het eigen adres én de live-positie van de buddy die
// onderweg is, met de looproute ertussen. De positie komt uit
// appState.buddyLiveLatitude/Longitude (door AppState.startBuddyLiveLocationSync
// elke paar seconden ververst). De route wordt opnieuw berekend als de buddy
// een stukje is opgeschoven.
// ============================================================

struct ElderlyBuddyRouteView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    @State private var camera: MapCameraPosition = .automatic
    @State private var polyline: MKPolyline?
    @State private var etaMinutes: Int?
    @State private var lastRoutedLat: Double?
    @State private var lastRoutedLon: Double?
    @State private var showChat = false

    private var buddyCoordinate: CLLocationCoordinate2D? {
        guard let lat = appState.buddyLiveLatitude, let lon = appState.buddyLiveLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Hemelsbrede afstand buddy → oudere (voor een korte tekstindicatie).
    private var straightLineText: String? {
        guard let b = buddyCoordinate else { return nil }
        let meters = CLLocation(latitude: b.latitude, longitude: b.longitude)
            .distance(from: CLLocation(latitude: task.coordinate.latitude, longitude: task.coordinate.longitude))
        return meters < 1000
            ? "± \(Int((meters / 50).rounded() * 50)) m"
            : String(format: "± %.1f km", meters / 1000).replacingOccurrences(of: ".", with: ",")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                map
                VStack {
                    statusCard
                    messageButton
                    Spacer()
                }
                .padding(BCSpacing.lg)

                if buddyCoordinate == nil {
                    searchingOverlay
                }
            }
            .navigationTitle("Uw buddy onderweg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .onAppear { recomputeRoute(force: true) }
        .onChange(of: appState.buddyLiveLatitude) { _, _ in recomputeRoute(force: false) }
        .onChange(of: appState.buddyLiveLongitude) { _, _ in recomputeRoute(force: false) }
        .sheet(isPresented: $showChat) {
            ConversationView(partnerId: task.assignedBuddyId,
                             partnerName: task.assignedBuddyName ?? "Buddy")
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Bericht sturen naar de buddy die onderweg is (punt 10).
    private var messageButton: some View {
        Button { showChat = true } label: {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "message.fill").font(.system(size: 16, weight: .semibold))
                Text("Stuur \(task.assignedBuddyName ?? "uw buddy") een bericht")
                    .font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.primary))
        }
        .buttonStyle(.plain)
        .padding(.top, BCSpacing.sm)
    }

    // MARK: Kaart

    private var map: some View {
        Map(position: $camera) {
            if let polyline {
                MapPolyline(polyline)
                    .stroke(BCColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            // Thuis van de oudere.
            Annotation(task.elderlyName, coordinate: task.coordinate) {
                ZStack {
                    Circle().fill(BCColors.accent).frame(width: 38, height: 38)
                        .shadow(color: BCColors.primaryDark.opacity(0.2), radius: 4, y: 2)
                    Image(systemName: "house.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
                }
            }
            // Live-positie van de buddy.
            if let b = buddyCoordinate {
                Annotation("Buddy", coordinate: b) {
                    ZStack {
                        Circle().fill(BCColors.primary).frame(width: 40, height: 40)
                            .shadow(color: BCColors.primaryDark.opacity(0.25), radius: 5, y: 2)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .mapControlVisibility(.hidden)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Statuskaart bovenin

    private var statusCard: some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 46, height: 46)
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.assignedBuddyName.map { "\($0) is onderweg" } ?? "Uw buddy is onderweg")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(subtitle)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var subtitle: String {
        if let eta = etaMinutes, let dist = straightLineText {
            return "Nog ± \(eta) min · \(dist) te gaan"
        }
        if let dist = straightLineText { return "\(dist) te gaan" }
        return "We bepalen de locatie…"
    }

    private var searchingOverlay: some View {
        // Laadstand in merkstijl: het logo valt uiteen in drie stuiterende stippen.
        BCLoadingDots(label: "We zoeken de locatie van uw buddy…")
        .padding(BCSpacing.lg)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface.opacity(0.95)))
        .bcSoftShadow(.card)
        .padding(BCSpacing.lg)
    }

    // MARK: Route berekenen

    /// Herberekent de looproute van de buddy naar het adres van de oudere. Doet
    /// dat alleen als de buddy noemenswaardig (≈ 60 m) is opgeschoven, om Apple's
    /// routedienst niet te overvragen.
    private func recomputeRoute(force: Bool) {
        guard let b = buddyCoordinate else { return }
        if !force, let lat = lastRoutedLat, let lon = lastRoutedLon {
            let moved = CLLocation(latitude: b.latitude, longitude: b.longitude)
                .distance(from: CLLocation(latitude: lat, longitude: lon))
            if moved < 60 { return }
        }
        lastRoutedLat = b.latitude
        lastRoutedLon = b.longitude

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: b))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: task.coordinate))
        request.transportType = .walking

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    self.polyline = route.polyline
                    self.etaMinutes = max(1, Int((route.expectedTravelTime / 60).rounded()))
                    self.camera = .rect(route.polyline.boundingMapRect.paddedForBuddyRoute())
                } else {
                    // Geen route? Kader dan in elk geval beide punten in beeld.
                    self.camera = .region(Self.region(a: b, b: self.task.coordinate))
                }
            }
        }
    }

    /// Regio die beide punten ruim omvat (fallback zonder route-lijn).
    private static func region(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: (a.latitude + b.latitude) / 2,
                                            longitude: (a.longitude + b.longitude) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(abs(a.latitude - b.latitude) * 1.6, 0.01),
            longitudeDelta: max(abs(a.longitude - b.longitude) * 1.6, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

private extension MKMapRect {
    /// Iets ruimere uitsnede zodat de route-lijn niet tegen de randen plakt.
    func paddedForBuddyRoute() -> MKMapRect {
        let dx = size.width * 0.30
        let dy = size.height * 0.30
        return insetBy(dx: -dx, dy: -dy)
    }
}
