import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

// MARK: - Flow orchestrator

struct CheckInFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    let onComplete: (CheckInRecord) -> Void

    @State private var step: Step = .selfie
    @State private var selfieConfirmed = false
    @State private var capturedSelfie: UIImage? = nil
    @State private var scannedQR: String? = nil

    enum Step { case selfie, qr, gps, done }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                BCColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.top, BCSpacing.md)
                        .padding(.bottom, BCSpacing.sm)

                    Group {
                        switch step {
                        case .selfie:
                            SelfieStepView(onConfirmed: handleSelfieConfirmed)
                        case .qr:
                            QRScanStepView(elderlyName: task.elderlyName, onScanned: handleQRScanned)
                        case .gps:
                            GPSVerifyView(
                                task: task,
                                qrPayload: scannedQR ?? "mock://checkin",
                                hasSelfie: selfieConfirmed,
                                selfieImage: capturedSelfie,
                                onComplete: handleGPSDone
                            )
                        case .done:
                            CheckInSuccessView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.35), value: step)
                }
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .selfie || step == .qr {
                        Button("Annuleer") { dismiss() }
                            .tint(BCColors.primary)
                    }
                }
            }
        }
    }

    // MARK: - Step handlers

    private func handleSelfieConfirmed(image: UIImage) {
        capturedSelfie = image
        selfieConfirmed = true
        withAnimation { step = .qr }
    }

    private func handleQRScanned(_ payload: String) {
        scannedQR = payload
        withAnimation { step = .gps }
    }

    private func handleGPSDone(_ record: CheckInRecord) {
        withAnimation { step = .done }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onComplete(record)
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        let steps: [Step] = [.selfie, .qr, .gps]
        let currentIndex = steps.firstIndex(of: step) ?? 0

        return HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i <= currentIndex ? BCColors.primary : BCColors.border)
                    .frame(height: 4)
                    .animation(.easeInOut, value: step)
            }
        }
        .padding(.horizontal, BCSpacing.xl)
    }
}

extension CheckInFlowView.Step {
    var title: String {
        switch self {
        case .selfie: return "Selfie"
        case .qr:     return "QR-code"
        case .gps:    return "Locatie"
        case .done:   return "Ingecheckt"
        }
    }
}

