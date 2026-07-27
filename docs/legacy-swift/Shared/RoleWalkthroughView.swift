import SwiftUI

// ============================================================
// RoleWalkthroughView — "Hoe het werkt"-carrousel (punt 9, feedback batch 2)
//
// Toont per rol een paar schermen met een nagebootste knop, een pijltje ernaartoe
// en een korte uitleg. "Overslaan" en "Klaar" sluiten de rondleiding. Respecteert
// Reduce Motion. Wordt 1 keer getoond na de registratie (zie de tab-views).
// ============================================================

struct RoleWalkthroughView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let role: UserRole
    let onFinish: () -> Void

    @State private var index = 0

    private var steps: [WalkthroughStep] { RoleWalkthrough.steps(for: role) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [BCColors.navy700, BCColors.navy900],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if steps.isEmpty {
                    // Leeg moment: de losse pillen als vriendelijke illustratie (5.2).
                    Spacer()
                    BCPillenPaar()
                    Spacer()
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { i, step in
                            page(step).tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: index)
                }
                dots
                bottomBar
            }
        }
    }

    // MARK: Bovenbalk (Overslaan)

    private var topBar: some View {
        HStack {
            Text("Hoe het werkt")
                .font(BCTypography.captionEmphasized)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Button("Overslaan") { onFinish() }
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.lg)
    }

    // MARK: Eén stap

    private func page(_ step: WalkthroughStep) -> some View {
        VStack(spacing: BCSpacing.lg) {
            Spacer()
            VStack(spacing: BCSpacing.sm) {
                Text(step.title)
                    .font(BCFont.heading(24, .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(step.text)
                    .font(BCTypography.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, BCSpacing.lg)

            Spacer()

            // Callout: pijltje naar de nagebootste knop.
            VStack(spacing: BCSpacing.sm) {
                if step.arrow == .down {
                    arrow(systemName: "arrow.down")
                }
                mockButton(step)
                if step.arrow == .up {
                    arrow(systemName: "arrow.up")
                }
            }
            Spacer()
        }
    }

    private func arrow(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(BCColors.accent)
            .modifier(BounceModifier(active: !reduceMotion,
                                     up: systemName == "arrow.up"))
    }

    /// Nagebootste versie van de bedoelde knop (zoals in de app).
    private func mockButton(_ step: WalkthroughStep) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(BCColors.surface).frame(width: 64, height: 64)
                    .shadow(color: BCColors.primaryDark.opacity(0.25), radius: 8, y: 4)
                Circle().stroke(step.tint, lineWidth: 2).frame(width: 64, height: 64)
                if step.iconIsAsset {
                    Image(step.icon).renderingMode(.original).resizable().scaledToFit()
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(step.tint)
                }
            }
            Text(step.buttonLabel)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.navy900)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Capsule().fill(BCColors.surface))
        }
    }

    // MARK: Pagina-stipjes

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(steps.indices, id: \.self) { i in
                Circle()
                    .fill(i == index ? BCColors.accent : Color.white.opacity(0.3))
                    .frame(width: i == index ? 9 : 7, height: i == index ? 9 : 7)
            }
        }
        .padding(.bottom, BCSpacing.md)
    }

    // MARK: Onderbalk

    private var bottomBar: some View {
        HStack(spacing: BCSpacing.sm) {
            if index > 0 {
                Button {
                    withAnimation { index -= 1 }
                } label: {
                    Text("Terug")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().stroke(.white.opacity(0.4), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            Button {
                if index >= steps.count - 1 {
                    onFinish()
                } else {
                    withAnimation { index += 1 }
                }
            } label: {
                Text(index >= steps.count - 1 ? "Klaar" : "Volgende")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(BCColors.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.xl)
    }
}

/// Subtiele op-en-neer beweging van het pijltje (uit bij Reduce Motion).
private struct BounceModifier: ViewModifier {
    let active: Bool
    let up: Bool
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .offset(y: active ? (animate ? (up ? -6 : 6) : 0) : 0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}

// MARK: - Presentatie (1 keer na registratie, opnieuw op te roepen vanuit profiel)

private struct RoleWalkthroughModifier: ViewModifier {
    @Environment(AppState.self) private var appState
    let role: UserRole
    @State private var show = false

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $show) {
                RoleWalkthroughView(role: role) {
                    appState.markWalkthroughSeen(role)
                    show = false
                }
            }
            .onAppear { maybeAutoShow() }
            .onChange(of: appState.isOnboardingComplete) { _, _ in maybeAutoShow() }
            .onChange(of: appState.consentDecided) { _, _ in maybeAutoShow() }
            .onChange(of: appState.elderlyHasLinkingCode) { _, _ in maybeAutoShow() }
            .onChange(of: appState.walkthroughReplay) { _, r in
                if r == role { show = true }
            }
    }

    /// Toont de rondleiding automatisch zodra de gebruiker echt in de app zit
    /// (onboarding klaar, toestemming gemaakt, en voor ouderen: koppelcode-gate
    /// gepasseerd) en de rondleiding voor deze rol nog niet is gezien.
    private func maybeAutoShow() {
        guard appState.isOnboardingComplete,
              appState.consentDecided,
              !appState.hasSeenWalkthrough(role) else { return }
        if role == .elderly && !appState.elderlyHasLinkingCode { return }
        // Even wachten zodat een eventueel sluitende onboarding/consent-sheet klaar is.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard !appState.hasSeenWalkthrough(role), appState.isOnboardingComplete else { return }
            show = true
        }
    }
}

extension View {
    /// Toont de "hoe het werkt"-rondleiding voor deze rol (punt 9).
    func roleWalkthrough(_ role: UserRole) -> some View {
        modifier(RoleWalkthroughModifier(role: role))
    }
}

#Preview {
    RoleWalkthroughView(role: .buddy) {}
}
