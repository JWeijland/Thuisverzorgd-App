//  ElderlySheets.swift
//  Verplaatst uit ElderlyHomeView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import CoreImage

struct BuddyMessageComposeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.largeTextEnabled) private var largeText
    let buddyName: String?
    let onSend: (String) -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    /// Kant-en-klare zinnen zodat de oudere niet veel hoeft te typen.
    private let suggestions = [
        "Ik ben thuis, u kunt aanbellen.",
        "Kunt u iets later komen?",
        "Tot zo, fijn dat u komt!",
        "Wilt u mij even bellen?"
    ]

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    Text(buddyName.map { "Stuur \($0) een bericht" } ?? "Stuur uw buddy een bericht")
                        .font(et.heading)
                        .foregroundStyle(BCColors.textPrimary)

                    TextField("Typ hier uw bericht…", text: $text, axis: .vertical)
                        .font(et.body)
                        .lineLimit(4...10)
                        .focused($focused)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surfaceMuted))
                        .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))

                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        Text("Snel kiezen")
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                        ForEach(suggestions, id: \.self) { s in
                            Button {
                                text = s
                                focused = false
                            } label: {
                                HStack(spacing: BCSpacing.sm) {
                                    Image(systemName: "text.bubble")
                                        .foregroundStyle(BCColors.primary)
                                    Text(s)
                                        .font(et.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(BCSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                                .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    BCPrimaryButton(title: "Versturen", icon: "paperplane.fill") {
                        onSend(trimmed)
                        dismiss()
                    }
                    .opacity(trimmed.isEmpty ? 0.45 : 1)
                    .disabled(trimmed.isEmpty)
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Bericht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
            .onAppear { focused = true }
        }
    }
}

struct ElderlyQRCodeSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var qrPayload: String {
        if let task = appState.activeTaskForElderly {
            return "buddycare://task/\(task.id.uuidString)"
        }
        return "buddycare://checkin/\(UUID().uuidString)"
    }

    private var buddyName: String? {
        appState.activeTaskForElderly?.assignedBuddyName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.xl) {
                Spacer()

                VStack(spacing: BCSpacing.sm) {
                    Text("Laat de buddy dit scannen")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    if let name = buddyName {
                        Text("Houd uw telefoon voor \(name) zodat hij/zij de QR-code kan inscannen.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Houd uw telefoon voor de buddy zodat hij/zij de QR-code kan inscannen.")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if let qrImage = makeQRImage(payload: qrPayload) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding(BCSpacing.lg)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(.white))
                        .bcSoftShadow(.card)
                }

                Spacer()
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("QR-code voor buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private func makeQRImage(payload: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
