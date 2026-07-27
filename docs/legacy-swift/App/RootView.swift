import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Group {
                if !appState.hasSeenSplash {
                    // Geanimeerde openingspagina — altijd als eerste bij het opstarten.
                    // Het herstellen van een sessie loopt ondertussen op de achtergrond.
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            appState.hasSeenSplash = true
                        }
                    }
                } else if appState.isInitializing {
                    initLoadingScreen
                } else if appState.showLogin {
                    LoginView()
                } else {
                    Group {
                        switch appState.currentRole {
                        case .none:
                            RoleSelectionView()
                        case .elderly:
                            ElderlyTabView()
                        case .buddy:
                            BuddyTabView()
                        case .family:
                            FamilyTabView()
                        case .admin:
                            AdminTabView()
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appState.currentRole)
            .animation(.easeInOut(duration: 0.35), value: appState.hasSeenSplash)
            .animation(.easeInOut(duration: 0.2), value: appState.isInitializing)
            .animation(.easeInOut(duration: 0.25), value: appState.showLogin)

            // Global toast overlay
            if let toast = appState.toastMessage {
                VStack {
                    Spacer()
                    BCToast(message: toast.text, icon: toast.icon)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
                .animation(.spring(response: 0.35), value: appState.toastMessage != nil)
            }
        }
        .animation(.spring(response: 0.35), value: appState.toastMessage != nil)
        .task { await appState.initialize() }
        .sheet(isPresented: Binding(
            get: { shouldShowConsent },
            set: { _ in }
        )) {
            ConsentSheet()
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled()
        }
    }

    /// Eenmalig toestemmingsscherm zodra iemand in een rol zit en nog geen keuze maakte.
    private var shouldShowConsent: Bool {
        appState.hasSeenSplash
            && !appState.isInitializing
            && !appState.showLogin
            && !appState.consentDecided
            && (appState.currentRole == .elderly
                || appState.currentRole == .buddy
                || appState.currentRole == .family)
    }

    private var initLoadingScreen: some View {
        ZStack {
            BCColors.primary.ignoresSafeArea()
            VStack(spacing: BCSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(BCColors.accent.opacity(0.18))
                        .frame(width: 96, height: 96)
                    Image(systemName: "house.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(BCColors.accent)
                }
                BCLoadingDots(label: "Even geduld...", onDark: true)
            }
        }
    }
}

// MARK: - Toestemmingsscherm (opt-in, intrekbaar)

struct ConsentSheet: View {
    @Environment(AppState.self) private var appState
    // Opt-in: niet vooraf aangevinkt.
    @State private var productAnalytics = false
    @State private var researchInsights = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                    Text("Mogen we hiervoor je toestemming?")
                        .font(BCTypography.title3)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Jij beslist. We slaan nooit je naam, adres of gezondheidsgegevens op voor analyse, en delen alleen anonieme, geaggregeerde cijfers. Je kunt dit later altijd wijzigen.")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                }

                consentRow(
                    isOn: $productAnalytics,
                    icon: "chart.bar.fill",
                    title: "Help de app verbeteren",
                    subtitle: "Anonieme gebruiksstatistieken om Thuisverzorgd beter te maken."
                )
                consentRow(
                    isOn: $researchInsights,
                    icon: "building.2.fill",
                    title: "Draag bij aan welzijnsinzichten",
                    subtitle: "Geaggregeerde, anonieme inzichten over welzijn in de buurt, nooit herleidbaar tot jou."
                )

                BCCTAButton(title: "Opslaan", icon: "checkmark", iconLeading: true) {
                    appState.recordConsent(
                        productAnalytics: productAnalytics,
                        researchInsights: researchInsights
                    )
                }

                Button {
                    appState.recordConsent(productAnalytics: false, researchInsights: false)
                } label: {
                    Text("Liever niet, sla niets op")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private func consentRow(isOn: Binding<Bool>, icon: String, title: String, subtitle: String) -> some View {
        BCCard {
            HStack(alignment: .top, spacing: BCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(subtitle)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: BCSpacing.sm)
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(BCColors.accent)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
