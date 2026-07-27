//  BCCards.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct BCHelpHeroCard: View {
    @Environment(\.largeTextEnabled) private var largeText
    var eyebrow: String = "DIRECT GEREGELD"
    var title: String = "Hulp vragen"
    var subtitle: String = "Een buddy uit de buurt komt u helpen."
    var icon: String = "hand.raised.fill"
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.navy900)
                    Image(systemName: icon)
                        .font(.system(size: largeText ? 34 : 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: et.iconBoxSize, height: et.iconBoxSize)

                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrow)
                        .font(BCTypography.captionEmphasized)
                        .tracking(0.8)
                        .foregroundStyle(BCColors.green600)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(title)
                        .font(et.heading)
                        .foregroundStyle(BCColors.navy900)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: BCSpacing.sm)

                ZStack {
                    Circle().fill(BCColors.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: largeText ? 24 : 20, weight: .bold))
                        .foregroundStyle(BCColors.onAccent)
                }
                .frame(width: largeText ? 64 : 56, height: largeText ? 64 : 56)
            }
            .padding(largeText ? BCSpacing.lg : BCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.raised)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

/// Compacte vierkante tegel ("Ook handig" / "Snel regelen") — icoon boven, label onder.
struct BCQuickTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let title: String
    var subtitle: String? = nil
    let icon: String
    var color: Color = BCColors.navy500
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(color.opacity(0.12))
                    AppIcon(name: icon, size: largeText ? 30 : 26, color: color)
                }
                .frame(width: largeText ? 64 : 52, height: largeText ? 64 : 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(largeText ? BCTypography.elderlyButton : BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(largeText ? BCTypography.elderlyCaption : BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
            }
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity, minHeight: largeText ? 150 : 124, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

struct BCCard<Content: View>: View {
    var padding: CGFloat = BCSpacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
    }
}

/// Witte, afgeronde inset-card die een lijst met rijen omsluit (rijen worden
/// gescheiden door `BCHairline`).
struct BCInsetCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous))
            .bcSoftShadow(.card)
    }
}

struct BCEmptyState: View {
    // `icon` blijft in de API voor bestaande call-sites, maar lege schermen
    // tonen de losse pillen die elkaar zoeken, nooit sombere iconen
    // (Brand Guidelines 5.2).
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: BCSpacing.sm) {
            BCPillenPaar()
                .padding(.bottom, BCSpacing.xs)
            Text(title)
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Text(message)
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(BCSpacing.lg)
        .frame(maxWidth: .infinity)
    }
}
