import SwiftUI

/// Geanimeerde openingspagina. Toont kort het getekende merkteken met het
/// woordmerk en een verfijnde, gestaffelde reveal. Eén tik slaat de animatie over en
/// na een paar tellen gaat hij vanzelf door naar het rolkeuze-scherm.
///
/// Respecteert reduce-motion: dan valt alles terug op een rustige fade zonder
/// veer-, teken- of shimmer-effecten. Alle kleuren en fonts lopen via de tokens,
/// dus de splash beweegt mee met het actieve (white-label) thema.
struct SplashView: View {
    let onContinue: () -> Void

    /// Hoe lang de splash blijft staan voordat hij automatisch doorgaat.
    private let autoAdvanceAfter: TimeInterval = 2.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Achtergrond
    @State private var swooshProgress: CGFloat = 0
    @State private var gradientShift: CGFloat = -0.15

    // Logo
    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0

    // Woordmerk + tagline
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 16
    @State private var taglineOpacity: Double = 0

    @State private var hasContinued = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: BCSpacing.lg) {
                logo
                VStack(spacing: BCSpacing.sm) {
                    wordmark
                    Text("Hulp om de hoek,\nmet een hart erbij.")
                        .font(BCTypography.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .opacity(taglineOpacity)
                }
            }
            .padding(.horizontal, BCSpacing.xl)
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { runAnimation() }
        .task {
            try? await Task.sleep(for: .seconds(autoAdvanceAfter))
            advance()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Thuisverzorgd. Hulp om de hoek, met een hart erbij.")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tik om door te gaan")
    }

    // MARK: - Onderdelen

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [BCColors.primary, BCColors.primaryDark],
                startPoint: UnitPoint(x: 0.5 + gradientShift, y: 0),
                endPoint: UnitPoint(x: 0.5 - gradientShift, y: 1)
            )
            .ignoresSafeArea()

            // Zacht in-tekenend swoosh-motief. Accent-kleur van het thema, dus
            // white-label-veilig (geen hardcoded roze).
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    SwooshShape()
                        .trim(from: 0, to: swooshProgress)
                        .stroke(BCColors.accent.opacity(0.5),
                                style: StrokeStyle(lineWidth: 26, lineCap: .round))
                        .frame(width: w * 1.35, height: h * 0.5)
                        .position(x: w * 0.5, y: h * 0.24)
                        .blur(radius: 0.5)
                    SwooshShape()
                        .trim(from: 0, to: swooshProgress)
                        .stroke(.white.opacity(0.10),
                                style: StrokeStyle(lineWidth: 40, lineCap: .round))
                        .frame(width: w * 1.5, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.8)
                        .rotationEffect(.degrees(180))
                }
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
    }

    private var logo: some View {
        // Het getekende merkteken; op de navy gradient hoort diapositief (h2).
        BCLogoMark(height: 120, variant: .diapositief)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
    }

    private var wordmark: some View {
        // Woordmerk volgens h2: altijd "thuisverzorgd" in kleine letters,
        // Montserrat, in wit op de navy ondergrond.
        Text("thuisverzorgd")
            .foregroundStyle(.white)
            .font(BCFont.heading(38, .heavy))
            .opacity(wordmarkOpacity)
            .offset(y: wordmarkOffset)
    }

    // MARK: - Animatie

    private func runAnimation() {
        guard !reduceMotion else {
            // Rustige fade, geen beweging.
            swooshProgress = 1
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1; logoOpacity = 1
                wordmarkOpacity = 1; wordmarkOffset = 0
                taglineOpacity = 1
            }
            return
        }

        // Swoosh tekent zichzelf in en de gradient schuift subtiel (parallax).
        withAnimation(.easeInOut(duration: 1.2)) { swooshProgress = 1 }
        withAnimation(.easeInOut(duration: 2.2)) { gradientShift = 0.15 }

        // Logo veert in.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.66)) {
            logoScale = 1; logoOpacity = 1
        }

        // Woordmerk valt in.
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.32)) {
            wordmarkOpacity = 1; wordmarkOffset = 0
        }
        // Tagline sluit af.
        withAnimation(.easeOut(duration: 0.5).delay(0.62)) { taglineOpacity = 1 }
    }

    private func advance() {
        guard !hasContinued else { return }
        hasContinued = true
        onContinue()
    }
}

/// Vloeiende, dubbele golfvorm voor het decoratieve swoosh-motief op de splash.
private struct SwooshShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: 0, y: h * 0.7))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.35),
                   control1: CGPoint(x: w * 0.18, y: h * 0.75),
                   control2: CGPoint(x: w * 0.34, y: h * 0.32))
        p.addCurve(to: CGPoint(x: w, y: h * 0.55),
                   control1: CGPoint(x: w * 0.7, y: h * 0.4),
                   control2: CGPoint(x: w * 0.86, y: h * 0.7))
        return p
    }
}

#Preview {
    SplashView(onContinue: {})
}
