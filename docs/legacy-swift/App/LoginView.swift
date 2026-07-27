import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var mode: AuthMode = .login

    // Login
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    // Register
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .elderly
    /// Gekozen vrijwilligersorganisatie bij registratie (organization_key).
    /// nil = niet aangesloten. Alleen herkomst; de huisstijl blijft gelijk.
    @State private var selectedOrgKey: String? = nil
    @State private var registerEmail = ""
    @State private var registerPassword = ""
    // Laagdrempelige demografie — geaggregeerd interessant voor gemeenten e.d.
    // Voor buddies vragen we de volledige geboortedatum (exacte leeftijd) en de
    // volledige postcode (1011 AB → preciezere locatie voor matching).
    @State private var gender: Gender = .unknown
    @State private var birthDate: Date? = nil
    @State private var postcode = ""

    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    enum AuthMode: String, CaseIterable {
        case login = "Inloggen"
        case register = "Registreren"
    }

    var body: some View {
        ZStack {
            BCColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    pageHeader

                    Picker("Modus", selection: $mode) {
                        ForEach(AuthMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.lg)
                    .padding(.bottom, BCSpacing.md)
                    .onChange(of: mode) { _, _ in errorMessage = nil }

                    if mode == .login {
                        loginSection
                    } else {
                        registerSection
                    }

                    // Demo-snelkoppeling — tijdelijk altijd zichtbaar zodat de
                    // hele flow (verificatie, taken aannemen + voltooien) te
                    // testen is, ook in een TestFlight-build.
                    // TODO: vóór publieke App Store-release weer achter een vlag.
                    demoShortcut

                    if let error = errorMessage {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error)
                        }
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.danger)
                        .multilineTextAlignment(.leading)
                        .padding(BCSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .fill(BCColors.danger.opacity(0.08))
                        )
                        .padding(.horizontal, BCSpacing.lg)
                        .padding(.bottom, BCSpacing.lg)
                    }
                }
            }

            if isLoading {
                BCColors.primaryDark.opacity(0.25).ignoresSafeArea()
                BCLoadingDots(label: "Even geduld...", onDark: true)
            }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [BCColors.navy900, BCColors.navy700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            VStack(spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.sm) {
                    // Merkteken + woordmerk volgens h2: "thuisverzorgd" in kleine
                    // letters, Montserrat Bold, wit op de navy ondergrond.
                    BCLogoMark(height: 38, variant: .diapositief)
                    Text("thuisverzorgd")
                        .foregroundStyle(.white)
                        .font(BCFont.heading(22, .bold))
                }
                .padding(.top, BCSpacing.xl)
                Text("Hulp om de hoek, met een hart erbij.")
                    .font(BCTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, BCSpacing.lg)
            }
        }
    }

    // MARK: - Login

    private var loginSection: some View {
        VStack(spacing: BCSpacing.md) {
            AuthField(
                label: "E-mailadres",
                placeholder: "naam@voorbeeld.nl",
                text: $loginEmail,
                keyboard: .emailAddress,
                autocapitalization: .never
            )

            AuthField(
                label: "Wachtwoord",
                placeholder: "••••••••",
                text: $loginPassword,
                isSecure: true
            )

            Button {
                Task { await performLogin() }
            } label: {
                submitLabel("Inloggen")
            }
            .buttonStyle(.plain)
            .disabled(isLoading || loginEmail.isEmpty || loginPassword.isEmpty)
            .opacity(loginEmail.isEmpty || loginPassword.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.xl)
    }

    // MARK: - Register

    private var registerSection: some View {
        VStack(spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.sm) {
                AuthField(label: "Voornaam", placeholder: "Jan", text: $firstName)
                AuthField(label: "Achternaam", placeholder: "de Vries", text: $lastName)
            }

            rolePicker

            organizationPicker

            demographicsSection

            AuthField(
                label: "E-mailadres",
                placeholder: "naam@voorbeeld.nl",
                text: $registerEmail,
                keyboard: .emailAddress,
                autocapitalization: .never
            )

            AuthField(
                label: "Wachtwoord",
                placeholder: "Minimaal 8 tekens",
                text: $registerPassword,
                isSecure: true
            )

            Button {
                Task { await performRegister() }
            } label: {
                submitLabel("Account aanmaken")
            }
            .buttonStyle(.plain)
            .disabled(isLoading || !registerFormValid)
            .opacity(registerFormValid ? 1 : 0.5)

            Text("Door te registreren ga je akkoord met onze gebruiksvoorwaarden en het AVG-privacybeleid.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.xl)
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Ik gebruik Thuisverzorgd als")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)

            ForEach(UserRole.allCases.filter { $0 != .admin }) { role in
                Button {
                    selectedRole = role
                } label: {
                    HStack(spacing: BCSpacing.md) {
                        Image(systemName: selectedRole == role ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedRole == role ? BCColors.green600 : BCColors.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.displayName)
                                .font(BCTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(BCColors.textPrimary)
                            Text(role.subtitle)
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(selectedRole == role ? BCColors.accent.opacity(0.10) : BCColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                    .stroke(
                                        selectedRole == role ? BCColors.green600 : BCColors.border,
                                        lineWidth: selectedRole == role ? 1.5 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: selectedRole)
            }
        }
    }

    // MARK: - Organisatie (herkomst)

    /// Naam van de gekozen organisatie, of de standaard-tekst.
    private var selectedOrgName: String {
        appState.availableOrganizations.first { $0.key == selectedOrgKey }?.name
            ?? "Niet aangesloten / weet ik niet"
    }

    private var organizationPicker: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Hoort u bij een vrijwilligersorganisatie?")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)

            Menu {
                Button("Niet aangesloten / weet ik niet") {
                    selectedOrgKey = nil
                }
                ForEach(appState.availableOrganizations) { org in
                    Button(org.name) { selectedOrgKey = org.key }
                }
            } label: {
                HStack {
                    Text(selectedOrgName)
                        .foregroundStyle(selectedOrgKey == nil ? BCColors.textTertiary : BCColors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
                .font(BCTypography.body)
                .padding(.horizontal, BCSpacing.md)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.surface)
                )
                .bcSoftShadow(.subtle)
            }

            Text("De naam van uw organisatie komt dan bij uw profiel te staan. U gebruikt gewoon dezelfde app.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
        }
    }

    // MARK: - Demografie (laagdrempelig, optioneel)

    /// Buddies geven exacte gegevens op (verplicht): volledige geboortedatum +
    /// volledige postcode. Voor andere rollen blijft deze sectie optioneel.
    private var buddyDetailsRequired: Bool { selectedRole == .buddy }

    private var demographicsSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text(buddyDetailsRequired ? "Je gegevens" : "Een paar korte vragen (optioneel)")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)

            // Geslacht
            Menu {
                ForEach(Gender.allCases) { g in
                    Button(g.label) { gender = g }
                }
            } label: {
                HStack {
                    Text(gender == .unknown ? "Geslacht" : gender.label)
                        .foregroundStyle(gender == .unknown ? BCColors.textTertiary : BCColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
                .font(BCTypography.body)
                .padding(.horizontal, BCSpacing.md)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.surface)
                )
                .bcSoftShadow(.subtle)
            }

            // Volledige geboortedatum (exacte leeftijd)
            VStack(alignment: .leading, spacing: 6) {
                Text(buddyDetailsRequired ? "Geboortedatum" : "Geboortedatum (optioneel)")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.textSecondary)
                BirthDateField(date: $birthDate)
            }

            // Volledige postcode (1011 AB) → preciezere locatie
            AuthField(label: buddyDetailsRequired ? "Postcode" : "Postcode (optioneel)",
                      placeholder: "1011 AB", text: $postcode,
                      autocapitalization: .characters)
                .onChange(of: postcode) { _, new in
                    postcode = formatPostcode(new)
                }
            if buddyDetailsRequired && !postcode.isEmpty && !isValidDutchPostcode(postcode) {
                Text("Vul een geldige postcode in, bijv. 1011 AB.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.danger)
            }

            Text(buddyDetailsRequired
                 ? "Je leeftijd en postcode helpen om hulpvragen dicht bij jou te tonen. We delen ze alleen anoniem en geaggregeerd."
                 : "We gebruiken dit alleen anoniem en geaggregeerd om welzijn in de buurt te verbeteren. Nooit herleidbaar tot jou.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary)
        }
    }

    /// Houdt de postcode netjes: max 6 tekens, hoofdletters, vorm "1234 AB".
    private func formatPostcode(_ raw: String) -> String {
        let cleaned = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        let digits = cleaned.prefix(4)
        let letters = cleaned.dropFirst(4).prefix(2)
        return letters.isEmpty ? String(digits) : "\(digits) \(letters)"
    }

    /// 4 cijfers + 2 letters (met optionele spatie).
    private func isValidDutchPostcode(_ value: String) -> Bool {
        let compact = value.replacingOccurrences(of: " ", with: "").uppercased()
        guard compact.count == 6 else { return false }
        return compact.prefix(4).allSatisfy(\.isNumber)
            && compact.suffix(2).allSatisfy(\.isLetter)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func submitLabel(_ title: String) -> some View {
        Text(title)
            .font(BCTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .fill(BCColors.primary)
            )
            .bcSoftShadow(.subtle)
    }

    private var registerFormValid: Bool {
        let base = !firstName.isEmpty && !lastName.isEmpty &&
            !registerEmail.isEmpty && registerPassword.count >= 8
        // Buddies: volledige geboortedatum + geldige postcode verplicht.
        if buddyDetailsRequired {
            return base && birthDate != nil && isValidDutchPostcode(postcode)
        }
        return base
    }

    // MARK: - Demo shortcut

    private var demoShortcut: some View {
        VStack(spacing: BCSpacing.sm) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(BCColors.border)
                Text("of")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .fixedSize()
                Rectangle().frame(height: 1).foregroundStyle(BCColors.border)
            }
            .padding(.horizontal, BCSpacing.lg)

            Menu {
                Button {
                    goDemo(role: .buddy)
                } label: {
                    Label("Demo (Buddy kaart)", systemImage: "map.fill")
                }
                Button {
                    goDemo(role: .elderly)
                } label: {
                    Label("Demo (Oudere)", systemImage: "figure.wave")
                }
                Button {
                    goDemo(role: .family)
                } label: {
                    Label("Demo (Familie)", systemImage: "house.and.flag.fill")
                }
            } label: {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Direct naar demo (zonder account)")
                        .font(BCTypography.captionEmphasized)
                }
                .foregroundStyle(BCColors.textSecondary)
                .padding(.horizontal, BCSpacing.md)
                .padding(.vertical, BCSpacing.sm)
                .background(Capsule().fill(BCColors.surfaceMuted))
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    private func goDemo(role: UserRole) {
        appState.isDemoMode = true
        appState.isOnboardingComplete = true
        // Demo heeft geen echte koppelcode — de gate overslaan, anders blijft de
        // cliënt-demo op het koppelscherm hangen (er is geen account om het op te onthouden).
        appState.elderlyHasLinkingCode = true
        appState.currentRole = role
        appState.showLogin = false
        appState.hasSeenSplash = true
    }

    // MARK: - Actions

    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            try await appState.authService.signIn(email: loginEmail, password: loginPassword)
            if let userId = appState.authService.currentUserId {
                await appState.handleAuthSuccess(userId: userId)
                if appState.currentRole == nil {
                    errorMessage = "Account gevonden maar profiel ontbreekt. Probeer opnieuw te registreren."
                }
            }
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        do {
            // Geboortejaar uit de volledige datum; 4 postcode-cijfers blijven de
            // anonieme demografie (de volledige postcode gebruiken we voor locatie).
            let birthYear = birthDate.map { Calendar.current.component(.year, from: $0) }
            let postcodeDigits = postcode.filter(\.isNumber).prefix(4)
            let needsConfirmation = try await appState.authService.signUp(
                email: registerEmail,
                password: registerPassword,
                role: selectedRole.rawValue,
                firstName: firstName,
                lastName: lastName,
                gender: gender == .unknown ? nil : gender.rawValue,
                birthYear: birthYear,
                postcode4: postcodeDigits.isEmpty ? nil : String(postcodeDigits),
                organizationKey: selectedOrgKey
            )
            if needsConfirmation {
                errorMessage = "Bevestig je e-mailadres via de link in je inbox en log daarna in."
            } else if let userId = appState.authService.currentUserId {
                await appState.handleAuthSuccess(userId: userId, role: selectedRole)
                // Buddy: exacte geboortedatum + locatie (uit postcode) op het profiel
                // zetten, zodat matching meteen klopt.
                if selectedRole == .buddy {
                    if let dob = birthDate { appState.saveBuddyDateOfBirth(dob) }
                    let pc = postcode.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !pc.isEmpty { appState.saveBuddyLocationFromPostcode(pc) }
                }
            }
        } catch {
            errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    private func friendlyError(_ error: Error) -> String {
        let raw = (error.localizedDescription + " " + String(describing: error)).lowercased()
        if raw.contains("email not confirmed") || raw.contains("not confirmed") {
            return "E-mailadres nog niet bevestigd. Controleer je inbox en klik op de bevestigingslink."
        } else if raw.contains("invalid login credentials") || raw.contains("invalid_credentials") || raw.contains("invalid email or password") {
            return "E-mailadres of wachtwoord klopt niet."
        } else if raw.contains("already registered") || raw.contains("already exists") || raw.contains("already in use") || raw.contains("duplicate") {
            return "Er bestaat al een account met dit e-mailadres. Log in."
        } else if raw.contains("weak") && raw.contains("password") {
            return "Wachtwoord is te zwak. Kies minimaal 8 tekens."
        } else if raw.contains("network") || raw.contains("offline") || raw.contains("could not connect") || raw.contains("timed out") {
            return "Geen internetverbinding. Controleer je wifi of mobiele data."
        } else if raw.contains("signup") && raw.contains("disabled") {
            return "Registratie is tijdelijk uitgeschakeld."
        } else if raw.contains("rate limit") || raw.contains("too many") {
            return "Te veel pogingen. Wacht even en probeer het opnieuw."
        }
        #if DEBUG
        return "Fout: \(error.localizedDescription)"
        #else
        return "Er is iets misgegaan. Probeer het opnieuw."
        #endif
    }
}

// MARK: - Shared form field

private struct AuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.textSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(BCTypography.body)
            .foregroundStyle(BCColors.textPrimary)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.subtle)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
