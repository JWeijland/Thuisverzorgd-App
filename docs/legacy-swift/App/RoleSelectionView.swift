import SwiftUI

struct RoleSelectionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            BCColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: BCSpacing.lg) {
                        introBlock
                            .padding(.top, BCSpacing.xl)

                        VStack(spacing: BCSpacing.md) {
                            ForEach([UserRole.elderly, .buddy, .family], id: \.id) { role in
                                RoleCard(role: role) {
                                    // Iedereen stapt direct in. Buddies doorlopen daarna de
                                    // korte onboarding (intake + VOG); cliënten de koppelcode-gate.
                                    enterDirectly(as: role)
                                }
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)

                        trustStrip
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.top, BCSpacing.lg)

                        // Prototype-tekst + demo-snelkoppelingen: alleen tijdens
                        // ontwikkelen, verborgen in de release-build (TestFlight).
                        #if DEBUG
                        prototypeNote
                            .padding(.horizontal, BCSpacing.lg)
                            .padding(.bottom, BCSpacing.xl)
                        #endif
                    }
                }
            }
        }
    }

    /// Ouderen/familie zonder organisatie: meteen de juiste rol in (zelfstandig pad).
    private func enterDirectly(as role: UserRole) {
        appState.currentUserMembership = nil
        appState.selectedOrganization = nil
        appState.pendingRole = nil
        appState.isOnboardingComplete = false
        appState.hasSeenSplash = true
        appState.currentRole = role
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            HStack(spacing: BCSpacing.sm) {
                // Merkteken + woordmerk volgens h2: "thuisverzorgd" in kleine
                // letters, Montserrat Bold, wit op de navy ondergrond.
                BCLogoMark(height: 38, variant: .diapositief)
                Text("thuisverzorgd")
                    .foregroundStyle(.white)
                    .font(BCFont.heading(22, .bold))
                Spacer()
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.vertical, BCSpacing.md)
        }
        .frame(height: 64)
    }

    private var introBlock: some View {
        VStack(spacing: BCSpacing.sm) {
            // Kop met Hulpgroene punt (stijlmiddel 1, Brand Guidelines 3.3).
            BCHeroKop(text: "Welkom bij Thuisverzorgd",
                      font: BCTypography.largeTitle,
                      alignment: .center)
            Text("Hulp om de hoek, met een hart erbij. Kies hieronder hoe u Thuisverzorgd wilt gebruiken.")
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BCSpacing.lg)
        }
    }

    private var trustStrip: some View {
        HStack(spacing: BCSpacing.md) {
            TrustBadge(icon: "checkmark.shield.fill", label: "VOG\ngescreend")
            TrustBadge(icon: "lock.fill", label: "AVG\nveilig")
            TrustBadge(icon: "heart.fill", label: "Vrijwillig\n& gratis")
        }
    }

    private var prototypeNote: some View {
        VStack(spacing: BCSpacing.md) {
            Text("Prototype: selecteer een rol om de bijbehorende app-ervaring te bekijken.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, BCSpacing.lg)

            // Demo shortcuts
            VStack(spacing: BCSpacing.sm) {
                DemoButton(label: "Demo: Buddy (kaart)", icon: "bolt.fill") {
                    appState.isDemoMode = true
                    appState.hasSeenSplash = true
                    appState.isOnboardingComplete = true
                    appState.buddyUser.intakeCompleted = true
                    appState.buddyUser.vogValid = true
                    appState.currentRole = .buddy
                }
                DemoButton(label: "Demo: Buddy via organisatie", icon: "building.2.fill") {
                    appState.activateCordaanDemo(role: .buddy)
                }
                DemoButton(label: "Demo: Cliënt (met koppelcode)", icon: "building.2.fill") {
                    appState.activateCordaanDemo(role: .elderly)
                }
                DemoButton(label: "Admin dashboard", icon: "gearshape.2.fill") {
                    appState.isDemoMode = true
                    appState.hasSeenSplash = true
                    appState.isOnboardingComplete = true
                    appState.currentRole = .admin
                }
            }
        }
    }
}

private struct DemoButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(BCTypography.captionEmphasized)
            }
            .foregroundStyle(BCColors.primary)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Capsule().fill(BCColors.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

private struct RoleCard: View {
    let role: UserRole
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.navy900)
                        .frame(width: 60, height: 60)
                    Image(systemName: role.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.navy900)
                    Text(role.subtitle)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: BCSpacing.sm)
                ZStack {
                    Circle()
                        .fill(BCColors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(BCColors.green600)
                }
            }
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

private struct TrustBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: BCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BCColors.primary)
            Text(label)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BCSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(BCColors.surfaceMuted)
        )
    }
}

#Preview {
    RoleSelectionView()
        .environment(AppState())
}
