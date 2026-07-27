import SwiftUI
import MapKit
import CoreLocation

/// Kaart voor de oudere (of familielid): waar zijn er buddies beschikbaar?
/// Toont alleen buddies die op "beschikbaar" staan. Zodra echte buddies zich
/// aanmelden en beschikbaar zetten, verschijnen ze hier vanzelf.
struct ElderlyBuddyMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Voor wie wordt de hulp aangevraagd (familielid kan namens een oudere).
    var onBehalfOf: ElderlyUser? = nil

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedBuddy: BuddyUser? = nil
    @State private var showRequestFlow = false

    init(onBehalfOf: ElderlyUser? = nil) {
        self.onBehalfOf = onBehalfOf
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: onBehalfOf?.coordinate ?? MockData.amsterdamCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }

    private var center: CLLocationCoordinate2D {
        onBehalfOf?.coordinate ?? appState.elderlyUser.coordinate
    }

    /// Beschikbare buddies die ook echt taken mogen aannemen (VOG + intake rond).
    private var availableBuddies: [BuddyUser] {
        appState.allBuddies.filter { $0.isAvailableNow && $0.canAcceptTasks }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: Binding(
                get: { selectedBuddy?.id },
                set: { id in selectedBuddy = availableBuddies.first { $0.id == id } }
            )) {
                ForEach(availableBuddies) { buddy in
                    Annotation(buddy.firstName, coordinate: buddy.coordinate) {
                        BuddyMapPin(buddy: buddy, isSelected: selectedBuddy?.id == buddy.id)
                    }
                    .tag(buddy.id)
                }
            }
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()

            topBar
                .padding(.horizontal, BCSpacing.md)
                .padding(.top, BCSpacing.sm)

            if availableBuddies.isEmpty {
                emptyState
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, 90)
            }
        }
        .sheet(item: $selectedBuddy) { buddy in
            BuddyPreviewSheet(buddy: buddy, distanceText: distanceText(to: buddy)) {
                selectedBuddy = nil
                showRequestFlow = true
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRequestFlow) {
            if let elderly = onBehalfOf {
                RequestHelpFlow(onBehalfOf: elderly)
            } else {
                RequestHelpFlow()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: BCSpacing.sm) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BCColors.navy900)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(BCColors.surface))
                    .bcSoftShadow(.raised)
            }
            .buttonStyle(.plain)

            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                Text("Buddies in de buurt")
                    .font(BCFont.heading(15, .bold))
                    .foregroundStyle(BCColors.navy900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: BCSpacing.xs)
                BCStatusPill(label: "\(availableBuddies.count) beschikbaar",
                             color: availableBuddies.isEmpty ? BCColors.textTertiary : BCColors.success)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Capsule(style: .continuous).fill(BCColors.surface))
            .bcSoftShadow(.raised)
        }
    }

    private var emptyState: some View {
        BCCard {
            VStack(spacing: BCSpacing.sm) {
                // Lege staat met de losse pillen die elkaar zoeken, geen somber icoon
                // (Brand Guidelines 5.2).
                BCPillenPaar()
                    .padding(.vertical, BCSpacing.sm)
                Text("Nog geen buddies beschikbaar")
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Zodra buddies in de buurt zich beschikbaar zetten, verschijnen ze hier op de kaart. U kunt altijd een hulpaanvraag plaatsen, we zoeken er dan een voor u.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                BCPrimaryButton(title: "Hulp vragen", icon: "hand.raised.fill") {
                    showRequestFlow = true
                }
            }
        }
    }

    private func distanceText(to buddy: BuddyUser) -> String {
        let from = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let to = CLLocation(latitude: buddy.coordinate.latitude, longitude: buddy.coordinate.longitude)
        let meters = from.distance(from: to)
        if meters < 1000 {
            return "± \(Int((meters / 100).rounded() * 100)) m"
        }
        return String(format: "± %.1f km", meters / 1000).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Buddy-pin op de kaart

private struct BuddyMapPin: View {
    let buddy: BuddyUser
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(BCColors.success)
                    .frame(width: isSelected ? 52 : 44, height: isSelected ? 52 : 44)
                    .shadow(color: BCColors.primaryDark.opacity(0.25), radius: 6, x: 0, y: 3)
                Text(String(buddy.firstName.prefix(1)))
                    .font(BCTypography.headline)
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(BCColors.success)
                .frame(width: 12, height: 8)
        }
    }

    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
            return p
        }
    }
}

// MARK: - Voorvertoning van een buddy

private struct BuddyPreviewSheet: View {
    let buddy: BuddyUser
    let distanceText: String
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.success.opacity(0.14)).frame(width: 64, height: 64)
                    Text(String(buddy.firstName.prefix(1)))
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.success)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(buddy.firstName)
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    HStack(spacing: BCSpacing.sm) {
                        if buddy.ratingAverage > 0 {
                            Label(String(format: "%.1f", buddy.ratingAverage).replacingOccurrences(of: ".", with: ","),
                                  systemImage: "star.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.warning)
                        }
                        Label(distanceText, systemImage: "location.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
                Spacer()
            }

            if !buddy.bio.isEmpty {
                Text(buddy.bio)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            BCPrimaryButton(title: "Hulp vragen", icon: "hand.raised.fill", action: onRequest)
        }
        .padding(BCSpacing.lg)
        .background(BCColors.background.ignoresSafeArea())
    }
}

#Preview {
    ElderlyBuddyMapView().environment(AppState())
}
