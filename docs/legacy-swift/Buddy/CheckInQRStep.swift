//  CheckInQRStep.swift
//  Verplaatst uit CheckInFlow.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import AVFoundation
import Combine
import CoreLocation
import Vision
import VisionKit

struct QRScanStepView: View {
    let elderlyName: String
    let onScanned: (String) -> Void

    @State private var showManualInput = false
    @State private var manualCode = ""
    @State private var scanned = false

    private var useRealScanner: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        ZStack {
            if useRealScanner {
                DataScannerRepresentable(onScanned: handleScanned)
                    .ignoresSafeArea()
            } else {
                simulatorFallback
            }

            if useRealScanner {
                scannerOverlay
            }
        }
        .sheet(isPresented: $showManualInput) {
            manualInputSheet
        }
    }

    // Overlay op de camera
    private var scannerOverlay: some View {
        VStack {
            HStack {
                Label("Scan de QR-code op de telefoon van \(elderlyName)", systemImage: "qrcode.viewfinder")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(.white)
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(Capsule().fill(.black.opacity(0.55)))
            }
            .padding(.top, BCSpacing.md)

            Spacer()
            finderFrame
            Spacer()

            Button {
                showManualInput = true
            } label: {
                Text("Code niet scanbaar?")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(.white)
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(Capsule().fill(.black.opacity(0.5)))
            }
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var finderFrame: some View {
        ZStack {
            // Hoeken
            ForEach(0..<4, id: \.self) { i in
                CornerBracket()
                    .rotationEffect(.degrees(Double(i) * 90))
                    .frame(width: 240, height: 240)
            }
        }
    }

    // Simulator fallback
    private var simulatorFallback: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()
            VStack(spacing: BCSpacing.md) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(BCColors.primary)
                Text("Camera niet beschikbaar")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Gebruik de simulator-knop om door te gaan.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            BCPrimaryButton(title: "Simuleer QR-scan", icon: "qrcode") {
                handleScanned("buddycare://task/\(UUID().uuidString)")
            }
            BCSecondaryButton(title: "Code handmatig invoeren", icon: "keyboard") {
                showManualInput = true
            }
            Spacer()
        }
        .padding(BCSpacing.lg)
        .background(BCColors.background)
    }

    private var manualInputSheet: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.lg) {
                Text("Vraag \(elderlyName) om de code naast de QR-code op te lezen en voer hem hier in.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, BCSpacing.lg)

                TextField("Code, bijv. 482917", text: $manualCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(BCTypography.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)

                BCPrimaryButton(title: "Bevestig code", icon: "checkmark.circle.fill") {
                    showManualInput = false
                    handleScanned("buddycare://manual/\(manualCode)")
                }
                .disabled(manualCode.count < 4)
                .padding(.horizontal, BCSpacing.lg)

                Spacer()
            }
            .navigationTitle("Code invoeren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { showManualInput = false }.tint(BCColors.primary)
                }
            }
        }
    }

    private func handleScanned(_ payload: String) {
        guard !scanned else { return }
        scanned = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        onScanned(payload)
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScanned: (String) -> Void
        private var fired = false

        init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !fired else { return }
            for item in addedItems {
                if case .barcode(let code) = item, let payload = code.payloadStringValue {
                    fired = true
                    dataScanner.stopScanning()
                    onScanned(payload)
                    return
                }
            }
        }
    }
}

struct CornerBracket: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 28
            let t: CGFloat = 3

            Path { path in
                // Top-left corner (rest is rotated by the parent)
                path.move(to: CGPoint(x: 0, y: len))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: len, y: 0))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: t, lineCap: .round))
            .frame(width: w, height: h)
        }
    }
}
