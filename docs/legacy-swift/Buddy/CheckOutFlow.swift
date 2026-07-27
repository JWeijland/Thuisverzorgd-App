//  CheckOutFlow.swift
//  Verplaatst uit CheckInFlow.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

/// Aan het einde van het bezoek scant de buddy nogmaals de QR-code van de
/// hulpvrager om uit te checken. Pas daarna wordt de taak afgerond en verdwijnt
/// de hulpvraag van de kaart. Er is bewust geen demo-overslag: uitchecken
/// vereist een echte scan.
struct CheckOutFlowView: View {
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask
    let onComplete: () -> Void

    @State private var scanned = false

    var body: some View {
        NavigationStack {
            ZStack {
                BCColors.background.ignoresSafeArea()
                if scanned {
                    CheckOutSuccessView()
                } else {
                    VStack(spacing: 0) {
                        Text("Scan de QR-code van \(task.elderlyName) om uit te checken en het bezoek af te ronden.")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.md)
                        QRScanStepView(elderlyName: task.elderlyName) { _ in
                            handleScanned()
                        }
                    }
                }
            }
            .navigationTitle("Uitchecken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !scanned {
                        Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                    }
                }
            }
        }
    }

    private func handleScanned() {
        guard !scanned else { return }
        withAnimation { scanned = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            onComplete()
        }
    }
}

struct CheckOutSuccessView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BCColors.success.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.success)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            VStack(spacing: BCSpacing.xs) {
                BCHeroKop(text: "Uitgecheckt", font: BCTypography.title, alignment: .center)
                Text("Het bezoek wordt afgerond.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
            .opacity(opacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct CheckInSuccessView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BCColors.success.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.success)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            VStack(spacing: BCSpacing.xs) {
                BCHeroKop(text: "Ingecheckt", font: BCTypography.title, alignment: .center)
                Text("Taak wordt gestart.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
            }
            .opacity(opacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
