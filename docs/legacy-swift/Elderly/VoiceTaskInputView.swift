import SwiftUI

/// Spraak-inspraak modal voor ouderen — geduldig, groot, met live transcript.
///
/// Tap-to-start, tap-to-stop. Stopt automatisch na 3s stilte. Toont een
/// pulserende microfoon en het volume-niveau zodat de oudere ziet dat
/// de app luistert.
struct VoiceTaskInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.largeTextEnabled) private var largeText

    @State private var speech = SpeechService()

    /// Wordt aangeroepen wanneer de oudere de getranscribeerde tekst accepteert.
    let onAccept: (String) -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.lg) {
                instructions
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                Spacer(minLength: 0)

                micButton

                stateLabel
                    .padding(.horizontal, BCSpacing.lg)

                Spacer(minLength: 0)

                transcriptBox
                    .padding(.horizontal, BCSpacing.lg)

                actionButtons
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.bottom, BCSpacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Spreek uw vraag in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") {
                        speech.reset()
                        dismiss()
                    }
                    .tint(BCColors.primary)
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(speech.state == .listening)
    }

    // MARK: - Pieces

    private var instructions: some View {
        VStack(spacing: BCSpacing.xs) {
            Text("Vertel rustig wat u nodig heeft")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Bijvoorbeeld: \u{201C}ik kan niet naar de supermarkt lopen\u{201D}")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var micButton: some View {
        Button(action: toggleListening) {
            ZStack {
                // Pulse ring tijdens luisteren
                if speech.state == .listening {
                    Circle()
                        .stroke(BCColors.primary.opacity(0.35), lineWidth: 6)
                        .frame(width: 220, height: 220)
                        .scaleEffect(1.0 + CGFloat(speech.inputLevel) * 0.25)
                        .opacity(0.6 + Double(speech.inputLevel) * 0.4)
                        .animation(.easeOut(duration: 0.15), value: speech.inputLevel)

                    Circle()
                        .stroke(BCColors.primary.opacity(0.15), lineWidth: 10)
                        .frame(width: 260, height: 260)
                        .scaleEffect(1.0 + CGFloat(speech.inputLevel) * 0.15)
                        .animation(.easeOut(duration: 0.25), value: speech.inputLevel)
                }

                Circle()
                    .fill(micColor)
                    .frame(width: 160, height: 160)
                    .shadow(color: micColor.opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: micSymbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(isButtonDisabled)
        .accessibilityLabel(accessibilityLabel)
        .sensoryFeedback(.impact(weight: .medium), trigger: speech.state == .listening)
    }

    private var stateLabel: some View {
        Text(stateText)
            .font(et.body)
            .foregroundStyle(stateColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: speech.state)
    }

    private var transcriptBox: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            Text("Wat we horen:")
                .font(et.caption)
                .foregroundStyle(BCColors.textSecondary)
            Text(speech.transcript.isEmpty ? "…" : "\u{201C}\(speech.transcript)\u{201D}")
                .font(BCFont.body(largeText ? 26 : 22, .regular))
                .foregroundStyle(speech.transcript.isEmpty ? BCColors.textTertiary : BCColors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .multilineTextAlignment(.leading)
                .padding(BCSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                        .fill(BCColors.surface)
                )
                .bcSoftShadow(.card)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: BCSpacing.sm) {
            BCCTAButton(
                title: "Gebruik deze tekst",
                icon: "checkmark",
                fullWidth: true
            ) {
                let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                onAccept(text)
                speech.reset()
                dismiss()
            }
            .opacity(canAccept ? 1.0 : 0.45)
            .disabled(!canAccept)

            BCSecondaryButton(
                title: speech.transcript.isEmpty ? "Opnieuw beginnen" : "Wis en probeer opnieuw",
                icon: "arrow.counterclockwise",
                fullWidth: true
            ) {
                speech.reset()
            }
            .opacity(canReset ? 1.0 : 0.45)
            .disabled(!canReset)
        }
    }

    // MARK: - Logic / derived

    private func toggleListening() {
        switch speech.state {
        case .listening:
            speech.stop()
        case .idle, .done, .error, .denied, .unavailable:
            speech.start()
        case .authorizing, .processing:
            break
        }
    }

    private var canAccept: Bool {
        let trimmed = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && (speech.state == .done || speech.state == .idle)
    }

    private var canReset: Bool {
        switch speech.state {
        case .listening, .authorizing, .processing: return false
        default: return !speech.transcript.isEmpty || stateHasError
        }
    }

    private var stateHasError: Bool {
        if case .error = speech.state { return true }
        if case .denied = speech.state { return true }
        if case .unavailable = speech.state { return true }
        return false
    }

    private var isButtonDisabled: Bool {
        switch speech.state {
        case .authorizing, .processing: return true
        case .denied, .unavailable: return true
        default: return false
        }
    }

    private var micSymbol: String {
        switch speech.state {
        case .listening: return "stop.fill"
        case .processing, .authorizing: return "ellipsis"
        case .denied, .unavailable: return "mic.slash.fill"
        default: return "mic.fill"
        }
    }

    private var micColor: Color {
        switch speech.state {
        case .listening: return BCColors.danger
        case .denied, .unavailable, .error: return BCColors.textTertiary
        case .done: return BCColors.success
        default: return BCColors.primary
        }
    }

    private var stateText: String {
        switch speech.state {
        case .idle: return "Tik op de microfoon en begin met praten"
        case .authorizing: return "Microfoon voorbereiden\u{2026}"
        case .listening: return "Ik luister\u{2026} (tik nogmaals om te stoppen)"
        case .processing: return "Een momentje\u{2026}"
        case .done: return "Klaar, controleer of de tekst klopt"
        case .denied(let reason): return reason
        case .unavailable(let reason): return reason
        case .error(let message): return message
        }
    }

    private var stateColor: Color {
        switch speech.state {
        case .listening: return BCColors.danger
        case .done: return BCColors.success
        case .denied, .unavailable, .error: return BCColors.danger
        default: return BCColors.textSecondary
        }
    }

    private var accessibilityLabel: String {
        switch speech.state {
        case .listening: return "Stop met luisteren"
        case .idle, .done, .error: return "Begin met inspreken"
        default: return "Microfoon"
        }
    }
}

#Preview {
    VoiceTaskInputView(onAccept: { _ in })
}
