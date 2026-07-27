//  BCBadges.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct BCStatusPill: View {
    let label: String
    let color: Color
    var showDot: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if showDot {
                Circle().fill(color).frame(width: 7, height: 7)
            }
            Text(label)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous).fill(color.opacity(0.12))
        )
    }
}

struct BCRatingStars: View {
    // Waardering als kringstippen, geen sterren (Brand Guidelines 5.2):
    // vol = Hulpgroen, half = zacht groen, leeg = een lichte rand-stip.
    let value: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: max(2, size * 0.3)) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: size * 0.85, height: size * 0.85)
            }
            Text(String(format: "%.1f", value))
                .font(BCFont.heading(size, .semibold))
                .foregroundStyle(BCColors.textPrimary)
                .padding(.leading, 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "Waardering %.1f van 5", value))
    }

    private func dotColor(for index: Int) -> Color {
        if value >= Double(index) + 0.75 { return BCColors.accent }
        if value >= Double(index) + 0.25 { return BCColors.accent.opacity(0.45) }
        return BCColors.border
    }
}

struct BCProgressBar: View {
    let value: Double     // 0.0–1.0
    var label: String? = nil
    var color: Color = BCColors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            if let label {
                Text(label)
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.18))
                        .frame(height: 8)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct BCVOGBadge: View {
    var expiresAt: Date? = nil
    @State private var showVOGInfo = false

    var body: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BCColors.success)
            Text("VOG geverifieerd")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.success)
            Button {
                showVOGInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Wat is een VOG? Meer informatie")
        }
        .sheet(isPresented: $showVOGInfo) {
            VOGInfoSheet()
        }
    }
}

struct VOGInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(BCColors.success)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, BCSpacing.md)

                    Text("Wat is een VOG?")
                        .font(BCTypography.title2)
                        .foregroundStyle(BCColors.textPrimary)

                    Text("Een Verklaring Omtrent het Gedrag (VOG) is een document waaruit blijkt dat iemands gedrag uit het verleden geen bezwaar vormt voor het uitvoeren van een specifieke taak of functie.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)

                    Text("Elke buddy bij Thuisverzorgd heeft een geldige VOG. Deze wordt elke \(Config.vogRenewalYears) jaar vernieuwd en gecontroleerd door Thuisverzorgd.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("VOG Informatie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }
}

/// Kleine vertrouwens-strip (AVG / VOG / Reviews) als rustige witte balk.
struct BCTrustStrip: View {
    struct Item { let icon: String; let label: String }
    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Rectangle().fill(BCColors.border).frame(width: 1, height: 28)
                }
                VStack(spacing: 5) {
                    Image(systemName: item.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(BCColors.accentDark)
                    Text(item.label)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
    }
}
