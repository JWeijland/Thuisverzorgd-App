//  CheckInSelfieStep.swift
//  Verplaatst uit CheckInFlow.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

struct SelfieStepView: View {
    let onConfirmed: (UIImage) -> Void

    @State private var capturedImage: UIImage? = nil
    @State private var showingCamera = false
    @State private var analyzing = false

    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.xl) {
                VStack(spacing: BCSpacing.sm) {
                    Image(systemName: "faceid")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(BCColors.primary)
                    Text("Selfie voor check-in")
                        .font(BCTypography.title)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Eenmalig per bezoek. Bevestigt dat jij het bent die incheckt.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, BCSpacing.lg)

                if analyzing {
                    analyzingView
                } else if let img = capturedImage {
                    confirmedView(img)
                } else {
                    cameraPrompt
                }

                Spacer()
            }
            .padding(.horizontal, BCSpacing.lg)
        }
        .sheet(isPresented: $showingCamera) {
            FrontCameraView { image in
                showingCamera = false
                capturedImage = image
                startAnalysis()
            }
        }
    }

    private var cameraPrompt: some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack {
                Circle()
                    .fill(BCColors.surface)
                    .frame(width: 160, height: 160)
                    .overlay(Circle().stroke(BCColors.border, lineWidth: 1.5))
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.textTertiary)
            }
            BCPrimaryButton(title: "Neem selfie", icon: "camera.fill") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                } else {
                    // Simulator: simuleer direct
                    capturedImage = UIImage(systemName: "person.crop.circle.fill")
                    startAnalysis()
                }
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: BCSpacing.md) {
            ZStack {
                Circle()
                    .fill(BCColors.primary.opacity(0.08))
                    .frame(width: 160, height: 160)
                BCLoadingDots(dotSize: 12)
            }
            Text("Gezicht herkennen…")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
        }
    }

    private func confirmedView(_ img: UIImage) -> some View {
        VStack(spacing: BCSpacing.lg) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BCColors.success, lineWidth: 3))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(BCColors.success)
                    .background(Circle().fill(BCColors.background).padding(2))
            }
            Text("Gezicht herkend")
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.success)
            VStack(spacing: BCSpacing.sm) {
                BCCTAButton(title: "Bevestigen & doorgaan", icon: "arrow.right") {
                    onConfirmed(img)
                }
                BCSecondaryButton(title: "Opnieuw nemen", icon: "arrow.counterclockwise") {
                    capturedImage = nil
                }
            }
        }
    }

    private func startAnalysis() {
        analyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            analyzing = false
        }
    }
}

struct FrontCameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
    }
}
