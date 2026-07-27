//  CheckInGPSStep.swift
//  Verplaatst uit CheckInFlow.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

struct GPSVerifyView: View {
    let task: ServiceTask
    let qrPayload: String
    let hasSelfie: Bool
    let selfieImage: UIImage?
    let onComplete: (CheckInRecord) -> Void

    @Environment(AppState.self) private var appState
    @StateObject private var locationManager = CheckInLocationManager()
    @State private var uiState: GPSState = .locating
    private let taskService = TaskService()

    enum GPSState { case locating, withinRange, outOfRange, unavailable }

    var body: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            switch uiState {
            case .locating:
                locatingView
            case .withinRange:
                resultView(
                    icon: "location.fill",
                    iconColor: BCColors.success,
                    title: "Locatie bevestigd",
                    subtitle: locationManager.distanceText,
                    badgeColor: BCColors.success
                )
            case .outOfRange:
                resultView(
                    icon: "location.slash.fill",
                    iconColor: BCColors.warning,
                    title: "Buiten verwacht bereik",
                    subtitle: "\(locationManager.distanceText) van het adres, toch ingecheckt.",
                    badgeColor: BCColors.warning
                )
            case .unavailable:
                resultView(
                    icon: "location.slash",
                    iconColor: BCColors.textTertiary,
                    title: "GPS niet beschikbaar",
                    subtitle: "Locatie kon niet worden bepaald.",
                    badgeColor: BCColors.textTertiary
                )
            }

            Spacer()
        }
        .padding(BCSpacing.lg)
        .onReceive(locationManager.$result) { result in
            guard let result = result else { return }
            finalize(result)
        }
        .onAppear { locationManager.start(taskCoordinate: task.coordinate) }
    }

    private var locatingView: some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(BCColors.primary.opacity(0.08))
                    .frame(width: 120, height: 120)
                BCLoadingDots(dotSize: 12)
            }
            VStack(spacing: BCSpacing.xs) {
                Text("Locatie controleren")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Even geduld…")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
    }

    private func resultView(icon: String, iconColor: Color, title: String, subtitle: String, badgeColor: Color) -> some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.10))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(spacing: BCSpacing.xs) {
                Text(title)
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text(subtitle)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Text("Check-in wordt afgerond…")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
        }
    }

    private func finalize(_ result: LocationResult) {
        let distance = result.distanceMeters
        withAnimation {
            if result.denied {
                uiState = .unavailable
            } else if let d = distance, d <= 500 {
                uiState = .withinRange
            } else {
                uiState = distance != nil ? .outOfRange : .unavailable
            }
        }
        var record = CheckInRecord(
            timestamp: Date(),
            latitude: result.latitude,
            longitude: result.longitude,
            qrPayload: qrPayload,
            hasSelfie: hasSelfie,
            distanceMeters: result.distanceMeters
        )
        Task {
            // Upload selfie naar Supabase Storage (alleen in real mode met echte buddy)
            if !appState.isDemoMode,
               let buddyId = appState.realUserId,
               let image = selfieImage,
               let jpegData = image.jpegData(compressionQuality: 0.75) {
                record.selfieStorageUrl = try? await taskService.uploadCheckInSelfie(
                    imageData: jpegData,
                    taskId: task.id,
                    buddyId: buddyId
                )
            }
            try? await taskService.markArrived(taskId: task.id, selfieUrl: record.selfieStorageUrl)
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete(record)
                }
            }
        }
    }
}

struct LocationResult {
    let latitude: Double?
    let longitude: Double?
    let distanceMeters: Double?
    let denied: Bool
}

// MARK: - Location manager (one-shot)

class CheckInLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var result: LocationResult? = nil
    @Published var distanceText: String = ""

    private let manager = CLLocationManager()
    private var taskCoordinate: CLLocationCoordinate2D? = nil
    private var resolved = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func start(taskCoordinate: CLLocationCoordinate2D? = nil) {
        self.taskCoordinate = taskCoordinate
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            emit(location: nil, denied: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !resolved, let loc = locations.last else { return }
        var distance: Double? = nil
        if let tc = taskCoordinate {
            distance = loc.distance(from: CLLocation(latitude: tc.latitude, longitude: tc.longitude))
            if let d = distance {
                distanceText = d < 1000 ? "\(Int(d.rounded())) m" : String(format: "%.1f km", d / 1000)
            }
        }
        emit(location: loc, denied: false, distance: distance)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        emit(location: nil, denied: false)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            emit(location: nil, denied: true)
        default: break
        }
    }

    private func emit(location: CLLocation?, denied: Bool, distance: Double? = nil) {
        guard !resolved else { return }
        resolved = true
        DispatchQueue.main.async {
            self.result = LocationResult(
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude,
                distanceMeters: distance,
                denied: denied
            )
        }
    }
}

extension CheckInLocationManager {
    func start() { start(taskCoordinate: nil) }
}
