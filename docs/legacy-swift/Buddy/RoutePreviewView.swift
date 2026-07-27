import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Route preview (in-app)
//
// Toont een routebeschrijving naar het adres van de oudere ín de app, in de
// huisstijl van Thuisverzorgd: een kaart met de looproute-lijn in navy, een
// kaartje met afstand + reistijd, en een nette stap-voor-stap lijst.
//
// Let op: Apple's MKDirections kent geen aparte fiets-route. Voor de korte
// afstanden in de buurt is de looproute praktisch gelijk aan de fietsroute,
// dus we tekenen de looproute en passen bij "Fietsen" alleen de reistijd-
// schatting aan. Voor échte turn-by-turn navigatie draagt de knop onderaan
// over aan Apple Maps.

enum RouteTravelMode: String, CaseIterable, Identifiable {
    case walking
    case cycling

    var id: String { rawValue }
    var label: String { self == .walking ? "Lopen" : "Fietsen" }
    var icon: String { self == .walking ? "figure.walk" : "bicycle" }

    /// Gemiddelde snelheid in meter/seconde voor de reistijd-schatting.
    /// Lopen ≈ 5 km/u, fietsen ≈ 15 km/u.
    var metersPerSecond: Double { self == .walking ? 1.39 : 4.17 }
}

struct RoutePreviewView: View {
    let task: ServiceTask

    @StateObject private var planner = RoutePlanner()
    @State private var mode: RouteTravelMode = .walking
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: BCSpacing.md) {
            summaryCard
            mapCard
            stepsCard
            BCSecondaryButton(title: "Open route in Kaart", icon: "map.fill") {
                openRouteInMaps(to: task)
            }
        }
        .onAppear { planner.start(destination: task.coordinate) }
        .onChange(of: planner.distanceMeters) { _, _ in
            // Zodra een route berekend is, kadreren we de kaart om de hele route.
            if let rect = planner.routeRect { camera = .rect(rect.paddedForRoute()) }
        }
    }

    // MARK: Samenvatting (afstand + tijd + modus-schakelaar)

    private var summaryCard: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                modePicker

                HStack(spacing: BCSpacing.sm) {
                    statBox(
                        label: "Afstand",
                        value: planner.distanceText,
                        icon: "ruler",
                        color: BCColors.textPrimary
                    )
                    Divider().frame(height: 40)
                    statBox(
                        label: "Reistijd",
                        value: planner.travelTimeText(for: mode),
                        icon: mode.icon,
                        color: BCColors.primary
                    )
                }
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: BCSpacing.xs) {
            ForEach(RouteTravelMode.allCases) { option in
                let selected = option == mode
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    mode = option
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(option.label)
                            .font(BCTypography.captionEmphasized)
                    }
                    .foregroundStyle(selected ? .white : BCColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selected ? BCColors.primary : BCColors.surfaceMuted)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.label)\(selected ? ", geselecteerd" : "")")
            }
        }
    }

    private func statBox(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color.opacity(0.7))
                Text(value)
                    .font(BCTypography.title3)
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Kaart met route-lijn

    private var mapCard: some View {
        Map(position: $camera) {
            if let polyline = planner.routePolyline {
                MapPolyline(polyline)
                    .stroke(BCColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            Annotation(task.elderlyName, coordinate: task.coordinate) {
                ZStack {
                    Circle()
                        .fill(BCColors.accent)
                        .frame(width: 38, height: 38)
                        .shadow(color: BCColors.primaryDark.opacity(0.2), radius: 4, y: 2)
                    Image(systemName: "house.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
                }
            }
            UserAnnotation()
        }
        .mapControlVisibility(.hidden)
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous))
        .bcSoftShadow(.card)
        .overlay(alignment: .center) {
            if planner.isLoading {
                ProgressView()
                    .padding(BCSpacing.md)
                    .background(Capsule().fill(BCColors.surface.opacity(0.9)))
            }
        }
    }

    // MARK: Stap-voor-stap lijst

    @ViewBuilder
    private var stepsCard: some View {
        if let message = planner.errorMessage {
            BCCard {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(BCColors.warning)
                    Text(message)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
        } else if !planner.steps.isEmpty {
            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    Label("Routebeschrijving", systemImage: "list.bullet")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)

                    ForEach(Array(planner.steps.enumerated()), id: \.offset) { index, step in
                        routeStepRow(index: index, step: step, isLast: index == planner.steps.count - 1)
                    }
                }
            }
        }
    }

    private func routeStepRow(index: Int, step: RouteStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isLast ? BCColors.accent : BCColors.primaryMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: isLast ? "flag.checkered" : "arrow.turn.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isLast ? BCColors.navy900 : BCColors.primary)
                }
                if !isLast {
                    Rectangle()
                        .fill(BCColors.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(minHeight: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.instruction)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let distance = step.distanceText {
                    Text(distance)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
            .padding(.bottom, isLast ? 0 : BCSpacing.sm)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Route step model

struct RouteStep {
    let instruction: String
    let distanceMeters: Double

    var distanceText: String? {
        guard distanceMeters > 0 else { return nil }
        return distanceMeters < 1000
            ? "\(Int(distanceMeters.rounded())) m"
            : String(format: "%.1f km", distanceMeters / 1000)
    }
}

// MARK: - Route planner (locatie + MKDirections)

@MainActor
final class RoutePlanner: NSObject, ObservableObject {
    @Published var steps: [RouteStep] = []
    @Published var routePolyline: MKPolyline?
    @Published var routeRect: MKMapRect?
    @Published var distanceMeters: Double = 0
    @Published var walkingTime: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private var destination: CLLocationCoordinate2D?
    private var didRequestRoute = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func start(destination: CLLocationCoordinate2D) {
        self.destination = destination
        isLoading = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            // Geen toestemming: toon alleen de bestemming, geen route.
            isLoading = false
            errorMessage = "Zet locatie aan om de route te zien. Je kunt de route ook direct in Kaart openen."
        }
    }

    // MARK: Afgeleide tekst

    var distanceText: String {
        guard distanceMeters > 0 else { return "—" }
        return distanceMeters < 1000
            ? "\(Int(distanceMeters.rounded())) m"
            : String(format: "%.1f km", distanceMeters / 1000)
    }

    func travelTimeText(for mode: RouteTravelMode) -> String {
        guard distanceMeters > 0 else { return "—" }
        // Lopen: gebruik de echte reistijd van Apple. Fietsen: schat o.b.v. afstand.
        let seconds = mode == .walking && walkingTime > 0
            ? walkingTime
            : distanceMeters / mode.metersPerSecond
        let minutes = max(1, Int((seconds / 60).rounded()))
        return "\(minutes) min"
    }

    // MARK: Route berekenen

    private func computeRoute(from source: CLLocationCoordinate2D) {
        guard let destination else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                guard let route = response?.routes.first else {
                    self.errorMessage = "We konden geen route berekenen. Open de route in Kaart."
                    return
                }
                self.routePolyline = route.polyline
                self.routeRect = route.polyline.boundingMapRect
                self.distanceMeters = route.distance
                self.walkingTime = route.expectedTravelTime
                self.steps = route.steps
                    .map { RouteStep(instruction: $0.instructions, distanceMeters: $0.distance) }
                    .filter { !$0.instruction.isEmpty }
            }
        }
    }
}

extension RoutePlanner: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            guard !self.didRequestRoute else { return }
            self.didRequestRoute = true
            self.computeRoute(from: loc.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = "Locatie niet beschikbaar. Open de route in Kaart."
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.isLoading = false
                self.errorMessage = "Zet locatie aan om de route te zien. Je kunt de route ook direct in Kaart openen."
            default:
                break
            }
        }
    }
}

// MARK: - Map rect helper

private extension MKMapRect {
    /// Iets ruimere uitsnede zodat de route-lijn niet tegen de randen plakt.
    func paddedForRoute() -> MKMapRect {
        let dx = size.width * 0.25
        let dy = size.height * 0.25
        return insetBy(dx: -dx, dy: -dy)
    }
}

#Preview {
    ScrollView {
        RoutePreviewView(task: MockData.openTasks.first!)
            .padding()
    }
    .background(BCColors.background)
    .environment(AppState())
}
