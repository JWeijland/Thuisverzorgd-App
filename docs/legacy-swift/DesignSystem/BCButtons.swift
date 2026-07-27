//  BCButtons.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct BCPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    var isLoading: Bool = false
    /// Hoekradius — standaard rond (lg). Geef bijv. `BCRadius.sm` voor een
    /// strakkere, vierkantere opslaan-knop.
    var cornerRadius: CGFloat = BCRadius.lg
    /// Compactere hoogte voor secundaire acties (opslaan) i.p.v. de 72pt CTA.
    var height: CGFloat = 72
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, BCSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(BCColors.primary)
            )
            .bcSoftShadow(.subtle)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

/// Groene "begin"-knop voor de belangrijkste actie ("Begin hier", "Taak aannemen").
struct BCCTAButton: View {
    let title: String
    var icon: String? = "arrow.right"
    var iconLeading: Bool = false
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if isLoading {
                    ProgressView().tint(BCColors.onAccent)
                } else {
                    if iconLeading, let icon {
                        Image(systemName: icon).font(.system(size: 18, weight: .bold))
                    }
                    Text(title).font(BCTypography.bodyEmphasized)
                    if !iconLeading, let icon {
                        Image(systemName: icon).font(.system(size: 18, weight: .bold))
                    }
                }
            }
            .foregroundStyle(BCColors.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 72)
            .padding(.horizontal, BCSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.accent)
            )
            .bcSoftShadow(.subtle)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

struct BCSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(BCColors.primary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 72)
            .padding(.horizontal, BCSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(BCColors.primary.opacity(0.4), lineWidth: 1.5)
            )
            .bcSoftShadow(.subtle)
        }
        .buttonStyle(.plain)
    }
}

/// Plain "Uitloggen"-knop onderaan elk profiel.
struct BCSignOutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.sm) {
                AppIcon(name: "tv-uitloggen", size: 18)
                Text("Uitloggen")
            }
            .font(BCTypography.bodyEmphasized)
            .foregroundStyle(BCColors.primary)
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.plain)
    }
}
