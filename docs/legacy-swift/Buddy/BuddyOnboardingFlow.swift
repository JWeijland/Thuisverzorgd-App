import SwiftUI
import CoreLocation

/// Korte, laagdrempelige onboarding voor vrijwilligers (Buddies).
///
/// Iedere buddy doorloopt dezelfde stappen — er is GEEN org-route die de intake
/// overslaat. VOG (gratis voor vrijwilligers) en een korte (~5 min) intake horen
/// erbij. Aanmelden/rondkijken mag direct; taken aannemen kan pas als VOG rond is
/// én de intake akkoord is. Een demo-knop slaat beide drempels over.
struct BuddyOnboardingFlow: View {
    @Environment(AppState.self) private var appState

    @State private var step: Int = 0

    // Profiel
    @State private var availableNow: Bool = true
    @State private var maxDistanceKm: Double = 10
    // Adres + geboortedatum — mag je later aanvullen op je profiel.
    @State private var addressDraft: String = ""
    @State private var addressCoordinate: CLLocationCoordinate2D? = nil
    @State private var birthDate: Date? = nil

    // Voorkeuren
    @State private var selectedServices: Set<String> = []

    // Intake (~5 min)
    @State private var motivation: String = ""
    @State private var hasExperience: Bool = false
    @State private var agreesCode: Bool = false
    @State private var referralCode: String = ""

    // VOG
    @State private var vogRequested: Bool = false

    private let totalSteps = 5  // 0..4

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar

            TabView(selection: $step) {
                welcomeStep.tag(0)
                profileStep.tag(1)
                intakeStep.tag(2)
                vogStep.tag(3)
                doneStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: step)

            bottomBar
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    // MARK: - Header & progress

    private var header: some View {
        HStack {
            Text("Word Buddy")
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Spacer()
            #if DEBUG
            // Alleen in debug-builds: hele onboarding (incl. VOG + intake) overslaan.
            // Niet aanwezig in TestFlight/Release.
            Button {
                finishAsDemo()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 11, weight: .bold))
                    Text("Sla over voor demo")
                }
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(BCColors.navy900)
                .padding(.horizontal, BCSpacing.sm)
                .padding(.vertical, 6)
                .background(Capsule().fill(BCColors.accent))
            }
            .buttonStyle(.plain)
            #endif
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.lg)
        .padding(.bottom, BCSpacing.sm)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(BCColors.border)
                Capsule().fill(BCColors.primary)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
            }
        }
        .frame(height: 6)
        .padding(.horizontal, BCSpacing.lg)
        .padding(.bottom, BCSpacing.md)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                BCLogoMark(height: 64, variant: .kleur)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, BCSpacing.lg)

                Text("Welkom als Buddy")
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)

                Text("Als Buddy help je vrijwillig mensen in jouw buurt met welzijn: gezelschap, een kop koffie, samen wandelen, boodschappen of hulp met de telefoon. Geen zorgtaken, geen verplichtingen: jij bepaalt wat je leuk vindt en wanneer je tijd hebt.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)

                infoRow(icon: "checkmark.seal.fill", text: "Aanmelden is gratis en kost een paar minuten")
                infoRow(icon: "shield.lefthalf.filled", text: "Een VOG is gratis voor vrijwilligers, wij helpen je erbij")
                infoRow(icon: "hand.thumbsup.fill", text: "Korte intake van ~5 minuten, daarna kun je aan de slag")
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var profileStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                stepTitle("Jouw profiel", subtitle: "Wat wil je doen en hoe ver wil je reizen?")

                BCCard {
                    Toggle(isOn: $availableNow) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Nu beschikbaar")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                            Text("Je kunt dit later altijd aanpassen")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }
                    .tint(BCColors.success)
                }

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Maximale reisafstand: \(Int(maxDistanceKm)) km")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        Slider(value: $maxDistanceKm, in: 1...30, step: 1)
                            .tint(BCColors.primary)
                    }
                }

                // Adres + geboortejaar — optioneel, mag je later op je profiel aanvullen.
                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.primary)
                            Text("Jouw buurt").font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                        }
                        Text("Begin met typen en kies je adres uit de lijst, dan tonen we hulpvragen bij jou in de buurt. Dit mag je later ook op je profiel doen.")
                            .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        AddressAutocompleteField(
                            placeholder: "Straat + plaats",
                            text: $addressDraft,
                            onManualEdit: { addressCoordinate = nil }
                        ) { coord, formatted in
                            addressCoordinate = coord
                            addressDraft = formatted
                        }
                        Text("Geboortedatum").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                        BirthDateField(date: $birthDate)
                    }
                }
                .onAppear {
                    if birthDate == nil {
                        if let dob = appState.buddyUser.dateOfBirth {
                            birthDate = dob
                        } else if let y = appState.buddyUser.birthYear {
                            // Val terug op 1 januari van het bekende geboortejaar.
                            birthDate = Calendar.current.date(from: DateComponents(year: y, month: 1, day: 1))
                        }
                    }
                    if addressDraft.isEmpty { addressDraft = appState.buddyUser.address }
                }

                Text("Welke welzijnstaken vind je leuk?")
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)

                serviceGrid
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var serviceGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: BCSpacing.sm) {
            ForEach(BuddyServiceCatalog.allItems, id: \.name) { item in
                let isOn = selectedServices.contains(item.name)
                Button {
                    if isOn { selectedServices.remove(item.name) }
                    else { selectedServices.insert(item.name) }
                } label: {
                    HStack(spacing: BCSpacing.xs) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isOn ? .white : BCColors.primary)
                        Text(item.name)
                            .font(BCTypography.caption)
                            .foregroundStyle(isOn ? .white : BCColors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(BCSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(isOn ? BCColors.primary : BCColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .stroke(BCColors.border, lineWidth: isOn ? 0 : 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var intakeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                stepTitle("Korte intake", subtitle: "Een paar vragen, ongeveer 5 minuten. Iedere buddy doet deze intake.")

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Waarom wil je buddy worden?")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.textPrimary)
                        TextField("Bijv. ik vind het fijn om mensen gezelschap te houden", text: $motivation, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(BCTypography.body)
                            .padding(BCSpacing.sm)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))
                    }
                }

                BCCard {
                    Toggle(isOn: $hasExperience) {
                        Text("Ik heb eerder vrijwilligerswerk of mantelzorg gedaan")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                    .tint(BCColors.primary)
                }

                // Optionele uitnodigingscode van een maatje — die maat krijgt punten.
                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.accentDark)
                            Text("Uitnodigingscode (optioneel)").font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                        }
                        Text("Door een maatje uitgenodigd? Vul hun code in, dan krijgt die maat punten.")
                            .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                        TextField("Bijv. KOFFIE24", text: $referralCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(BCTypography.body)
                            .padding(BCSpacing.sm)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))
                    }
                }

                BCCard {
                    Toggle(isOn: $agreesCode) {
                        Text("Ik ga akkoord met de gedragscode en omgangsregels van Thuisverzorgd")
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                    .tint(BCColors.primary)
                }

                Text("Je kunt al rondkijken in de app, ook als de intake nog niet helemaal rond is. Taken aannemen kan zodra intake en VOG akkoord zijn.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var vogStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                stepTitle("VOG aanvragen", subtitle: "Een Verklaring Omtrent het Gedrag is gratis voor vrijwilligers.")

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        infoRow(icon: "eurosign.circle.fill", text: "Gratis voor vrijwilligers, wij regelen de aanvraag")
                        infoRow(icon: "lock.shield.fill", text: "Geeft hulpvragers en families vertrouwen")
                        infoRow(icon: "clock.fill", text: "Aanvragen kan nu; rondkijken kan al meteen")
                    }
                }

                BCPrimaryButton(
                    title: vogRequested ? "VOG aangevraagd ✓" : "VOG aanvragen",
                    icon: vogRequested ? "checkmark" : "shield.lefthalf.filled"
                ) {
                    vogRequested = true
                }
                .disabled(vogRequested)
                .opacity(vogRequested ? 0.6 : 1)

                if vogRequested {
                    Text("Top! Je VOG-aanvraag is gestart. Dit duurt meestal een paar dagen, ondertussen kun je al gezelschap bieden bij mensen die geen VOG vereisen.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    private var doneStep: some View {
        ScrollView {
            VStack(spacing: BCSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(BCColors.success)
                    .padding(.top, BCSpacing.xl)
                BCHeroKop(text: "Je bent er klaar voor",
                          font: BCTypography.title2,
                          alignment: .center)
                Text("Bedankt dat je Buddy wordt. Bekijk de kaart met mensen die gezelschap of hulp zoeken in jouw buurt.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: BCSpacing.sm) {
                if step > 0 {
                    BCSecondaryButton(title: "Terug", icon: "chevron.left", fullWidth: true) {
                        step -= 1
                    }
                }
                BCCTAButton(title: primaryTitle, icon: step == totalSteps - 1 ? "checkmark" : "chevron.right", iconLeading: false) {
                    advance()
                }
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.5)
            }
            .padding(BCSpacing.lg)
        }
        .background(BCColors.background)
    }

    private var primaryTitle: String {
        switch step {
        case 0: return "Beginnen"
        case totalSteps - 1: return "Naar de app"
        case 2: return "Intake afronden"
        default: return "Volgende"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 2: return agreesCode   // gedragscode verplicht om intake af te ronden
        default: return true
        }
    }

    // MARK: - Actions

    private func advance() {
        if step < totalSteps - 1 {
            step += 1
        } else {
            finish()
        }
    }

    private func finish() {
        appState.isAvailableNow = availableNow
        appState.buddyUser.maxDistanceKm = Int(maxDistanceKm)
        appState.setBuddyPreferences(services: selectedServices)
        // intakeCompleted NIET hier zetten — akkoord met de gedragscode is geen
        // afgeronde intake. De échte intake is het videogesprek dat de admin
        // goedkeurt (zet intake_completed in de DB). Zo klopt de status overal,
        // ook na opnieuw inloggen.
        saveOptionalDetails()
        // VOG écht aanvragen (schrijft vog_status='aangevraagd' naar de DB → komt
        // bij de admin binnen). vogValid NIET zelf op true zetten — dat doet de
        // admin pas na goedkeuring, anders denkt de buddy onterecht dat-ie rond is.
        if vogRequested { appState.buddyRequestsVOG() }
        appState.isOnboardingComplete = true
    }

    #if DEBUG
    /// Demo: sla intake & VOG over en ga direct naar de app, klaar om taken aan te nemen.
    private func finishAsDemo() {
        appState.isAvailableNow = true
        appState.buddyUser.maxDistanceKm = Int(maxDistanceKm)
        appState.setBuddyPreferences(services: selectedServices)
        appState.buddyUser.intakeCompleted = true
        appState.buddyUser.vogValid = true
        saveOptionalDetails()
        appState.isOnboardingComplete = true
    }
    #endif

    /// Bewaart het (optionele) adres en de volledige geboortedatum. Leeg laten mag
    /// — dan kan de buddy het later subtiel op het profiel aanvullen.
    private func saveOptionalDetails() {
        let trimmedAddress = addressDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAddress.isEmpty { appState.saveBuddyAddress(trimmedAddress, coordinate: addressCoordinate) }
        if let dob = birthDate { appState.saveBuddyDateOfBirth(dob) }
    }

    // MARK: - Helpers

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BCTypography.title3)
                .foregroundStyle(BCColors.textPrimary)
            Text(subtitle)
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 26)
            Text(text)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    BuddyOnboardingFlow().environment(AppState())
}
