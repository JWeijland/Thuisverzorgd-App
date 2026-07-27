//  BCNavigation.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct BCNavBar: View {
    let title: String
    var subtitle: String? = nil
    var backAction: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            HStack(alignment: .bottom, spacing: BCSpacing.sm) {
                if let backAction {
                    Button(action: backAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Terug")
                }
                VStack(alignment: .leading, spacing: 0) {
                    if let subtitle {
                        Text(subtitle)
                            .font(BCTypography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    Text(title)
                        .font(BCTypography.titleEmphasized)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: BCSpacing.sm)
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BCColors.accent)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.sm)
        }
        .frame(height: 56)
    }
}

struct BCSectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            if let trailing, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailing)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct BCOnboardingPhoneFooter: View {
    var body: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: "phone.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BCColors.primary)
            Text("Hulp nodig? Bel ons: \(Config.supportPhoneNumber)")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
        }
        .padding(.vertical, BCSpacing.sm)
        .frame(maxWidth: .infinity)
    }
}

/// Een platte schakelaar-rij zonder kaartomlijsting. Bedoeld om meerdere
/// onder elkaar te zetten, gescheiden door dunne lijnen — rustiger dan losse
/// vakjes per instelling.
struct BCInlineToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool
    var tint: Color = BCColors.primary

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: BCSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BCColors.textSecondary)
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .tint(tint)
        .padding(.vertical, BCSpacing.sm)
    }
}

/// Een rustige, inklapbare sectie met alleen een titelregel en scheidingslijn.
/// Goed voor secundaire instellingen die je onderaan een pagina subtiel wil
/// aanbieden zonder dat ze visueel domineren.
struct BCDisclosureSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    var footnote: String? = nil
    @State private var expanded: Bool
    private let content: Content

    init(_ title: String,
         icon: String? = nil,
         footnote: String? = nil,
         initiallyExpanded: Bool = false,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.footnote = footnote
        self._expanded = State(initialValue: initiallyExpanded)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
            } label: {
                HStack(spacing: BCSpacing.sm) {
                    if let icon {
                        AppIcon(name: icon, size: 17, color: BCColors.textTertiary)
                            .frame(width: 22)
                    }
                    Text(title)
                        .font(BCTypography.captionEmphasized)
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(BCColors.textTertiary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
                .padding(.vertical, BCSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 0) {
                    content
                    if let footnote {
                        Text(footnote)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, BCSpacing.xs)
                            .padding(.bottom, BCSpacing.sm)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
        }
    }
}
