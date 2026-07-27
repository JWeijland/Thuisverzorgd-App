import SwiftUI

struct ElderlyTabView: View {
    @Environment(AppState.self) private var appState
    // Team-onboarding (zorgkring-pivot §1.1): éénmalige begeleide keuze
    // team of losse buddies, ná de bestaande gates.
    @State private var showTeamSetup = false

    var body: some View {
        @Bindable var state = appState
        ZStack(alignment: .bottom) {
            TabView(selection: $state.elderlyTabSelection) {
                // Fase36: de kaart is de voorpagina (customer journey JW11) —
                // buddies in de buurt + de eigen zorgkring prominent onderaan.
                ElderlyMapHomeView()
                    .tag(0)
                    .tabItem {
                        Label("Kaart", systemImage: "map.fill")
                    }

                ElderlyHomeView()
                    .tag(1)
                    .tabItem {
                        Label("Hulp", systemImage: "house.fill")
                    }

                MyBuddiesView()
                    .tag(2)
                    .tabItem {
                        Label("Buddies", systemImage: "person.2.fill")
                    }

                ElderlyProfileView()
                    .tag(3)
                    .tabItem {
                        Label("Profiel", systemImage: "person.crop.circle")
                    }
            }
            .tint(BCColors.primary)
            .environment(\.largeTextEnabled, appState.largeTextEnabled)
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showSOS },
            set: { appState.showSOS = $0 })
        ) {
            SOSView()
        }
        // Koppelcode-gate voorlopig uitgeschakeld: de cliënt komt direct in de
        // app, zonder eerst een koppelcode (bijv. ZEIST2026) in te vullen.
        // ClientOnboardingFlow hieronder blijft bestaan om de gate later
        // eenvoudig weer aan te zetten.
        // Punt 9: "hoe het werkt"-rondleiding, 1 keer na de registratie.
        .roleWalkthrough(.elderly)
        // Zorgkring-pivot §1.1: nieuwe hulpvragers kiezen éénmalig tussen een
        // vast team of losse buddies. De keuze wordt per gebruiker bewaard.
        .fullScreenCover(isPresented: $showTeamSetup) {
            TeamSetupFlow(onDone: { markTeamChoiceMade() })
                .environment(\.largeTextEnabled, appState.largeTextEnabled)
        }
        .task {
            await appState.loadCareTeams()
            evaluateTeamSetupGate()
        }
        .onChange(of: appState.isOnboardingComplete) { _, _ in
            evaluateTeamSetupGate()
        }
    }

    // MARK: - Team-onboarding gate

    /// Sleutel per gebruiker, zodat de keuze éénmalig is en niet meereist
    /// naar een ander account op hetzelfde toestel.
    private var teamChoiceKey: String {
        let uid = appState.realUserId?.uuidString ?? appState.elderlyUser.id.uuidString
        return "elderly.teamChoiceMade.\(uid)"
    }

    private func evaluateTeamSetupGate() {
        guard appState.currentRole == .elderly,
              appState.isOnboardingComplete,
              appState.careTeam(for: appState.elderlyUser) == nil,
              appState.elderlyTeamMode != "random_only",
              !UserDefaults.standard.bool(forKey: teamChoiceKey) else { return }
        showTeamSetup = true
    }

    private func markTeamChoiceMade() {
        UserDefaults.standard.set(true, forKey: teamChoiceKey)
        showTeamSetup = false
    }
}

// MARK: - Team-onboarding (zorgkring)

/// Begeleide keuze voor nieuwe hulpvragers: een vast team van buddies
/// (zorgkring) of liever losse buddies. Grote knoppen, warme taal — in de
/// stijl van ClientOnboardingFlow hierboven.
struct TeamSetupFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    /// Start direct bij de teamgrootte (conversie vanuit "losse buddies").
    let startAtSize: Bool
    /// Wordt aangeroepen zodra de flow klaar is (keuze gemaakt of gestart).
    let onDone: () -> Void
    /// Alleen gezet bij de conversie-flow: sluiten zonder keuze.
    let onCancel: (() -> Void)?

    @State private var step: Int
    @State private var minSize: Int = 3
    @State private var maxSize: Int = 5

    init(startAtSize: Bool = false, onDone: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.startAtSize = startAtSize
        self.onDone = onDone
        self.onCancel = onCancel
        _step = State(initialValue: startAtSize ? 1 : 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                if let onCancel {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(BCColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(BCColors.surfaceMuted))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, BCSpacing.md)
                    .accessibilityLabel("Sluiten")
                }

                switch step {
                case 0: choiceStep
                case 1: sizeStep
                case 2: confirmStep
                default: doneStep
                }
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
        .background(BCColors.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private func header(icon: String) -> some View {
        ZStack {
            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 88, height: 88)
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(BCColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, onCancel == nil ? BCSpacing.xl : 0)
    }

    // STAP 1 — team of losse buddies
    private var choiceStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.lg) {
            header(icon: "person.3.fill")

            Text("Een vast team van buddies om u heen")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)

            Text("Een klein groepje vaste buddies leert u echt kennen. Zij verdelen de bezoeken onderling, zodat er altijd een vertrouwd gezicht voor u klaarstaat.")
                .font(et.body)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BCCTAButton(title: "Ja, bouw mijn team", icon: "heart.fill") {
                step = 1
            }

            BCSecondaryButton(title: "Liever losse buddies", icon: "person.2.fill") {
                appState.setElderlyTeamMode("random_only")
                onDone()
            }

            Text("Kiest u voor losse buddies? Geen zorgen: u kunt later altijd alsnog een team starten via het tabblad Buddies.")
                .font(et.caption)
                .foregroundStyle(BCColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // STAP 2 — gewenste teamgrootte
    private var sizeStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.lg) {
            header(icon: "person.2.badge.plus.fill")

            Text("Hoe groot mag uw team zijn?")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)

            Text("Met het minimum kan uw team van start. We zoeken door tot het maximum, zodat de bezoeken goed te verdelen zijn.")
                .font(et.body)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    HStack(spacing: BCSpacing.sm) {
                        Text("Minimaal")
                            .font(et.body)
                            .foregroundStyle(BCColors.textPrimary)
                        Spacer()
                        Text("\(minSize)")
                            .font(et.button)
                            .foregroundStyle(BCColors.primary)
                            .frame(minWidth: 32)
                        Stepper("", value: $minSize, in: 1...6)
                            .labelsHidden()
                            .onChange(of: minSize) { _, newValue in
                                if maxSize < newValue { maxSize = newValue }
                            }
                    }
                    Divider()
                    HStack(spacing: BCSpacing.sm) {
                        Text("Maximaal")
                            .font(et.body)
                            .foregroundStyle(BCColors.textPrimary)
                        Spacer()
                        Text("\(maxSize)")
                            .font(et.button)
                            .foregroundStyle(BCColors.primary)
                            .frame(minWidth: 32)
                        Stepper("", value: $maxSize, in: minSize...8)
                            .labelsHidden()
                    }
                }
            }

            Text("Met minimaal \(minSize) \(minSize == 1 ? "buddy" : "buddies") kan uw team beginnen. We zoeken door tot \(maxSize) buddies.")
                .font(et.caption)
                .foregroundStyle(BCColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            BCCTAButton(title: "Volgende", icon: "arrow.right") {
                step = 2
            }
            if !startAtSize {
                BCSecondaryButton(title: "Terug", icon: "chevron.left") {
                    step = 0
                }
            }
        }
    }

    // STAP 3 — bevestigen en starten
    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.lg) {
            header(icon: "checkmark.seal.fill")

            Text("Klopt dit zo?")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)

            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    Label("Een vast team van buddies", systemImage: "person.3.fill")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Divider()
                    Label("Minimaal \(minSize), maximaal \(maxSize) buddies", systemImage: "person.2.badge.plus.fill")
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                }
            }

            Text("Buddies bij u in de buurt krijgen een uitnodiging. U beslist daarna zelf wie er in uw team komt.")
                .font(et.body)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BCCTAButton(title: "Start mijn team", icon: "heart.fill") {
                appState.startTeamFormation(minSize: minSize, maxSize: maxSize)
                step = 3
            }
            BCSecondaryButton(title: "Terug", icon: "chevron.left") {
                step = 1
            }
        }
    }

    // AFSLUITSCHERM — werving gestart
    private var doneStep: some View {
        VStack(alignment: .leading, spacing: BCSpacing.lg) {
            header(icon: "person.2.wave.2.fill")

            Text("We zoeken nu buddies bij u in de buurt")
                .font(et.heading)
                .foregroundStyle(BCColors.textPrimary)

            Text("U krijgt bericht zodra uw team er staat. Daarna mag u zelf bekijken en kiezen wie er in uw team komt.")
                .font(et.body)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BCCTAButton(title: "Klaar", icon: "checkmark") {
                onDone()
            }
        }
    }
}

// MARK: - Client onboarding (koppelcode-gate)

/// Aanmelden als cliënt is bewust laagdrempelig, maar vereist een koppelcode die
/// je krijgt via je gemeente, zorgverzekeraar of werkgever. Een demo-knop omzeilt dit.
struct ClientOnboardingFlow: View {
    @Environment(AppState.self) private var appState

    @State private var code: String = ""
    @State private var errorText: String? = nil
    @State private var acceptedPartner: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 88, height: 88)
                    Image(systemName: "house.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BCSpacing.xl)

                Text("Welkom bij Thuisverzorgd")
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)

                Text("Vul de koppelcode in die u heeft gekregen van uw gemeente, zorgverzekeraar of werkgever. Daarmee krijgt u toegang tot vrijwilligers (Buddies) bij u in de buurt, gratis en zonder gedoe.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        Text("Koppelcode")
                            .font(BCTypography.captionEmphasized)
                            .foregroundStyle(BCColors.textSecondary)
                        TextField("Bijv. ZEIST2026", text: $code)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                            .padding(BCSpacing.md)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surfaceMuted))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .stroke(errorText == nil ? BCColors.border : BCColors.danger, lineWidth: 1))
                            .onChange(of: code) { _, _ in errorText = nil }

                        if let errorText {
                            Label(errorText, systemImage: "exclamationmark.triangle.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.danger)
                        }
                        if let acceptedPartner {
                            Label("Welkom! Aangeboden via \(acceptedPartner).", systemImage: "checkmark.seal.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.success)
                        }
                    }
                }

                BCCTAButton(title: "Aanmelden", icon: "arrow.right") {
                    submit()
                }

                Text("Adres en geboortedatum mag u later rustig op uw profiel aanvullen, niet verplicht.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)

                Text("Nog geen koppelcode? Vraag ernaar bij uw gemeente, zorgverzekeraar of werkgever.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)

                Divider().padding(.vertical, BCSpacing.xs)

                Button {
                    appState.passElderlyLinkingCodeGate()
                } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "arrow.right.circle")
                        Text("Verder zonder koppelcode")
                    }
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BCSpacing.sm)
                    .background(Capsule().fill(BCColors.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private func submit() {
        let failMessage = "Deze koppelcode is onbekend, verlopen of opgebruikt. Controleer de code en probeer opnieuw."
        if appState.isLive {
            // Live: code echt valideren tegen Supabase + teller ophogen.
            Task {
                let name = await appState.redeemPartnerCodeLive(code)
                await MainActor.run {
                    if let name {
                        acceptedPartner = name
                        errorText = nil
                        appState.isOnboardingComplete = true
                    } else {
                        acceptedPartner = nil
                        errorText = failMessage
                    }
                }
            }
        } else if let partner = appState.redeemPartnerCode(code) {
            acceptedPartner = partner.partnerName
            errorText = nil
            appState.isOnboardingComplete = true
        } else {
            acceptedPartner = nil
            errorText = failMessage
        }
    }
}

#Preview {
    ElderlyTabView().environment(AppState())
}
