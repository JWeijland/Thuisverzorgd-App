//  BCOverlays.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct BCToast: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.vertical, BCSpacing.md)
        .background(
            Capsule(style: .continuous).fill(BCColors.navy900)
        )
        .shadow(color: BCColors.primaryDark.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

/// Een schermvullende, feestelijke bevestiging: een springende cirkel met
/// icoon, uitdijende ringen en haptische feedback. Gebruikt voor belangrijke
/// momenten (aanvraag geplaatst, taak aangenomen/afgerond, nieuwe beoordeling).
struct BCCelebrationOverlay: View {
    var icon: String = "checkmark"
    var title: String
    var subtitle: String
    var accent: Color = BCColors.accent
    var autoDismissAfter: Double? = 2.2
    var onDone: (() -> Void)? = nil

    @State private var circleScale: CGFloat = 0.3
    @State private var circleOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0
    @State private var ring1 = false
    @State private var ring2 = false
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [BCColors.navy900, BCColors.navy700],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: BCSpacing.xl) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.6), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring1 ? 2.3 : 1)
                        .opacity(ring1 ? 0 : 0.6)
                    Circle()
                        .stroke(accent.opacity(0.6), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring2 ? 1.9 : 1)
                        .opacity(ring2 ? 0 : 0.6)
                    Circle()
                        .fill(accent)
                        .frame(width: 130, height: 130)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)
                        .shadow(color: accent.opacity(0.5), radius: 20, x: 0, y: 8)
                    Image(systemName: icon)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(BCColors.onAccent)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                }

                VStack(spacing: BCSpacing.sm) {
                    Text(title)
                        .font(BCTypography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(BCTypography.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(textOpacity)
                .padding(.horizontal, BCSpacing.xl)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            circleScale = 1; circleOpacity = 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.18)) {
            iconScale = 1; iconOpacity = 1
        }
        withAnimation(.easeOut(duration: 1.3).delay(0.2)) { ring1 = true }
        withAnimation(.easeOut(duration: 1.3).delay(0.45)) { ring2 = true }
        withAnimation(.easeIn(duration: 0.3).delay(0.35)) { textOpacity = 1 }
        if let after = autoDismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + after) { onDone?() }
        }
    }
}

/// Het feestelijke vaste-buddy-moment: een groot hart popt in met uitdijende
/// ringen, terwijl kleine hartjes rustig omhoog zweven. Persoonlijker dan de
/// standaard BCCelebrationOverlay — voor het moment waarop iemand een buddy
/// als vaste buddy kiest.
struct BCHeartCelebration: View {
    let buddyName: String
    var subtitle: String = ""
    var autoDismissAfter: Double = 3.0
    var onDone: (() -> Void)? = nil

    @State private var heartScale: CGFloat = 0.2
    @State private var heartOpacity: Double = 0
    @State private var beat = false
    @State private var ring1 = false
    @State private var ring2 = false
    @State private var textOpacity: Double = 0
    @State private var float = false

    /// Vaste configuratie voor de zwevende hartjes (x-offset, vertraging, grootte)
    /// zodat de animatie rustig en voorspelbaar oogt.
    private let particles: [(x: CGFloat, delay: Double, size: CGFloat)] = [
        (-110, 0.30, 16), (-60, 0.55, 12), (-20, 0.40, 20),
        (25, 0.65, 14), (70, 0.35, 18), (115, 0.60, 13),
        (-85, 0.80, 11), (95, 0.85, 15)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [BCColors.navy900, BCColors.navy700],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Zwevende hartjes rond het middelpunt.
            ForEach(Array(particles.enumerated()), id: \.offset) { _, p in
                Image(systemName: "heart.fill")
                    .font(.system(size: p.size))
                    .foregroundStyle(BCColors.danger.opacity(0.85))
                    .offset(x: p.x, y: float ? -240 : 40)
                    .opacity(float ? 0 : 0.9)
                    .animation(.easeOut(duration: 2.2).delay(p.delay), value: float)
            }

            VStack(spacing: BCSpacing.xl) {
                ZStack {
                    Circle()
                        .stroke(BCColors.danger.opacity(0.6), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring1 ? 2.3 : 1)
                        .opacity(ring1 ? 0 : 0.6)
                    Circle()
                        .stroke(BCColors.danger.opacity(0.6), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring2 ? 1.9 : 1)
                        .opacity(ring2 ? 0 : 0.6)
                    Circle()
                        .fill(.white)
                        .frame(width: 130, height: 130)
                        .shadow(color: BCColors.danger.opacity(0.45), radius: 20, x: 0, y: 8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 62, weight: .bold))
                        .foregroundStyle(BCColors.danger)
                        .scaleEffect(beat ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.7), value: beat)
                }
                .scaleEffect(heartScale)
                .opacity(heartOpacity)

                VStack(spacing: BCSpacing.sm) {
                    Text("\(buddyName) is nu uw vaste buddy")
                        .font(BCTypography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(BCTypography.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .opacity(textOpacity)
                .padding(.horizontal, BCSpacing.xl)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            heartScale = 1; heartOpacity = 1
        }
        beat = true
        withAnimation(.easeOut(duration: 1.3).delay(0.2)) { ring1 = true }
        withAnimation(.easeOut(duration: 1.3).delay(0.45)) { ring2 = true }
        withAnimation(.easeIn(duration: 0.3).delay(0.35)) { textOpacity = 1 }
        float = true
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { onDone?() }
    }
}

/// Een icoon dat met een veer naar binnen "popt" met een uitdijende ring —
/// voor inline succesmomenten (bedankt-schermen, taak afgerond).
struct BCPopIcon: View {
    let systemName: String
    var color: Color = BCColors.accent
    var size: CGFloat = 64

    @State private var scale: CGFloat = 0.2
    @State private var ring = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(ring ? 1.3 : 0.7)
                .opacity(ring ? 0 : 0.8)
            Image(systemName: systemName)
                .font(.system(size: size))
                .foregroundStyle(color)
                .scaleEffect(scale)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { scale = 1 }
            withAnimation(.easeOut(duration: 1.0)) { ring = true }
        }
    }
}

/// Rustige "we zoeken een buddy"-animatie: zachte, naar buiten pulserende radar-
/// ringen rond een persoon-icoon. Bewust kalm en traag — geschikt voor het
/// wachtscherm van de hulpvrager.
struct BCBuddySearchPulse: View {
    var size: CGFloat = 104
    var tint: Color = BCColors.primary
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(tint.opacity(0.35), lineWidth: 2)
                    .frame(width: size, height: size)
                    .scaleEffect(animate ? 1.0 : 0.3)
                    .opacity(animate ? 0.0 : 0.55)
                    .animation(
                        .easeOut(duration: 2.6)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.85),
                        value: animate
                    )
            }
            Circle()
                .fill(tint.opacity(0.12))
                .frame(width: size * 0.5, height: size * 0.5)
            Image(systemName: "person.2.fill")
                .font(.system(size: size * 0.22, weight: .semibold))
                .foregroundStyle(tint)
                .scaleEffect(animate ? 1.0 : 0.92)
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: animate)
        }
        .frame(width: size, height: size)
        .onAppear { animate = true }
        .accessibilityLabel("We zoeken een buddy voor u")
    }
}
