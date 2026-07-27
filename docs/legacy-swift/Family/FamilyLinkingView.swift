import SwiftUI

struct FamilyLinkingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var code: String = ""
    @State private var isVerifying: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var linkedName: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                BCNavBar(title: "Koppelen", subtitle: "Verbind met een oudere")

                if showSuccess {
                    successView
                } else {
                    ScrollView {
                        VStack(spacing: BCSpacing.xl) {
                            VStack(spacing: BCSpacing.sm) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 56, weight: .semibold))
                                    .foregroundStyle(BCColors.primary)
                                    .padding(.top, BCSpacing.xl)

                                BCHeroKop(
                                    text: "Koppel met een oudere",
                                    font: BCTypography.title2,
                                    alignment: .center
                                )

                                Text("Voer de 6-cijferige code in die op de welkomstkaart staat, of scan de QR-code.")
                                    .font(BCTypography.body)
                                    .foregroundStyle(BCColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, BCSpacing.lg)
                            }

                            VStack(spacing: BCSpacing.md) {
                                // Big digit display
                                CodeInputView(code: $code)

                                if showError {
                                    Text("Code niet herkend. Controleer de code en probeer opnieuw.")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.danger)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, BCSpacing.lg)

                            BCSecondaryButton(title: "Scan QR-code op welkomstkaart", icon: "qrcode.viewfinder") {
                                // Mock: pretend QR was scanned
                                code = "123456"
                            }
                            .padding(.horizontal, BCSpacing.lg)

                            BCPrimaryButton(
                                title: isVerifying ? "Verifiëren…" : "Koppelen",
                                icon: "checkmark.circle.fill",
                                isLoading: isVerifying
                            ) {
                                verify()
                            }
                            .opacity(code.count == 6 ? 1.0 : 0.4)
                            .disabled(code.count < 6 || isVerifying)
                            .padding(.horizontal, BCSpacing.lg)

                            #if DEBUG
                            Text("Testcodes: 123456 (moeder Riet) of 654321 (vader Henk)")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                                .multilineTextAlignment(.center)
                            #endif

                            Divider().padding(.horizontal, BCSpacing.lg)

                            VStack(spacing: BCSpacing.sm) {
                                Text("Is uw naaste nog niet aangemeld?")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                Text("Vraag uw naaste om zich in de app te registreren. Daarna vinden zij op hun profiel een persoonlijke koppelcode, die zij met u delen om hier in te voeren.")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }
                        .padding(.bottom, BCSpacing.xl)
                    }
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }

    private var successView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(BCColors.success)

            VStack(spacing: BCSpacing.sm) {
                Text("Gekoppeld!")
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)
                Text("U bent nu gekoppeld aan \(linkedName).")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                Text("U ontvangt meldingen wanneer er een buddy wordt geboekt.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)
            }

            Spacer()

            BCPrimaryButton(title: "Naar overzicht", icon: "house.fill") {
                dismiss()
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private func verify() {
        isVerifying = true
        showError = false

        if appState.isLive {
            // Live: code echt inwisselen tegen Supabase (RPC redeem_linking_code).
            Task {
                let name = await appState.linkElderlyLive(code: code)
                await MainActor.run {
                    isVerifying = false
                    if let name {
                        linkedName = name
                        showSuccess = true
                    } else {
                        showError = true
                        code = ""
                    }
                }
            }
        } else {
            // Demo: lokale testcodes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isVerifying = false
                if let name = appState.linkElderly(code: code) {
                    linkedName = name
                    showSuccess = true
                } else {
                    showError = true
                    code = ""
                }
            }
        }
    }
}

// MARK: - 6-digit code input

private struct CodeInputView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field
            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    code = String(filtered.prefix(6))
                }
            ))
            .keyboardType(.numberPad)
            .focused($isFocused)
            .opacity(0)
            .frame(width: 1, height: 1)

            // Visual digit boxes
            HStack(spacing: BCSpacing.sm) {
                ForEach(0..<6) { i in
                    DigitBox(
                        digit: i < code.count ? String(code[code.index(code.startIndex, offsetBy: i)]) : "",
                        isActive: isFocused && i == code.count
                    )
                    .onTapGesture { isFocused = true }
                }
            }
        }
    }
}

private struct DigitBox: View {
    let digit: String
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(BCColors.surface)
                .frame(width: 48, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .stroke(isActive ? BCColors.primary : (digit.isEmpty ? BCColors.border : BCColors.primary.opacity(0.4)), lineWidth: isActive ? 2 : 1)
                )
            Text(digit)
                .font(BCTypography.title)
                .foregroundStyle(BCColors.textPrimary)
        }
    }
}

#Preview {
    FamilyLinkingView().environment(AppState())
}
