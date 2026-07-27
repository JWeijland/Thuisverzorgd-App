import SwiftUI
import CoreLocation

struct RequestHelpFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Indien gezet vraagt een familielid hulp aan namens deze oudere.
    /// Indien nil vraagt de oudere zelf hulp aan.
    var onBehalfOf: ElderlyUser? = nil

    private var targetElderly: ElderlyUser { onBehalfOf ?? appState.elderlyUser }

    @State private var step: Int = 0
    @State private var descriptionText: String = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var otherDescription: String = ""
    @State private var selectedTiming: TaskTiming? = nil
    @State private var note: String = ""
    @State private var showingConfirmation = false
    @State private var customDate: Date = Date().addingTimeInterval(3600)
    @State private var useCustomDate: Bool = false
    @State private var showVoiceInput: Bool = false
    @State private var showSuccess: Bool = false
    // Verplicht adres: als de hulpvrager nog geen adres heeft, moet dat eerst
    // worden ingevuld (en gevonden) voordat de aanvraag kan worden afgerond.
    @State private var addressInput: String = ""
    @State private var addressSaving: Bool = false
    @State private var addressError: String? = nil
    // Exacte coördinaat zodra een adres uit de suggestielijst wordt gekozen.
    @State private var pickedCoordinate: CLLocationCoordinate2D? = nil
    // Recurring — vrij in te vullen: elke N dagen of weken.
    @State private var isRecurring: Bool = false
    @State private var recurringIntervalCount: Int = 1
    @State private var recurringUnit: RecurringUnit = .weeks
    @State private var recurringEndDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    // Wie mag dit oppakken: het eigen zorg-team (vaste kennissen) of alle buddies.
    @State private var audience: HelpAudience = .pool
    // Heeft de gebruiker zelf een keuze getikt? Dan niet meer overschrijven.
    @State private var userChoseAudience: Bool = false
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    private var recurringSchedule: RecurringSchedule? {
        guard isRecurring else { return nil }
        return RecurringSchedule(intervalCount: recurringIntervalCount, unit: recurringUnit, endDate: recurringEndDate)
    }

    /// Het zorg-team rond deze hulpvrager (nil = geen team, dan blijft alles pool).
    private var myTeam: CareTeam? { appState.careTeam(for: targetElderly) }

    /// De gekozen startdatum, als er zelf een datum is gekozen.
    private var scheduledStartDate: Date? {
        if case .scheduled(let d) = selectedTiming { return d }
        return nil
    }

    /// Het inzetrooster van het team is er voor géplande momenten: er moet een
    /// live team zijn én er is zelf een datum gekozen. Spontane vragen
    /// ("zo snel mogelijk") gaan altijd als gewone hulpvraag de deur uit — de
    /// server geeft het team daarbij automatisch 8 minuten voorrang.
    private var teamEligible: Bool {
        guard let team = myTeam, team.status == .live else { return false }
        return scheduledStartDate != nil
    }

    /// De concrete bezoekdatums die bij "mijn team" in het rooster komen.
    private var plannedTeamDates: [Date] {
        guard let timing = selectedTiming else { return [] }
        return AppState.teamVisitDates(timing: timing, schedule: recurringSchedule)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                Group {
                    switch step {
                    case 0: categoryStep
                    case 1: timingStep
                    case 2: confirmStep
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Hulp vragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }
                        .tint(BCColors.primary)
                }
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceTaskInputView { spokenText in
                    applySpokenTranscript(spokenText)
                }
            }
        }
        .overlay {
            if showSuccess {
                BCCelebrationOverlay(
                    icon: audience == .team ? "person.3.fill" : "checkmark",
                    title: "Aanvraag geplaatst!",
                    subtitle: audience == .team
                        ? "De bezoeken staan in het rooster van \(myTeam?.name ?? "uw team"). Uw vaste kennissen verdelen ze onderling."
                        : "We zoeken meteen een vertrouwde buddy in de buurt voor \(targetElderly.firstName).",
                    onDone: { dismiss() }
                )
                .transition(.opacity)
            }
        }
    }

    private func applySpokenTranscript(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        descriptionText = trimmed
        if let match = recognizeCategory(from: trimmed) {
            selectedCategory = match
            if match == .other {
                otherDescription = trimmed
            }
        } else {
            // Geen categorie herkend → val terug op 'Anders' met transcript
            selectedCategory = .other
            otherDescription = trimmed
        }
    }

    private var progressBar: some View {
        HStack(spacing: BCSpacing.xs) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= step ? BCColors.accent : BCColors.border)
                    .frame(height: 6)
            }
        }
    }

    private var voiceInputCallout: some View {
        Button {
            showVoiceInput = true
        } label: {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(BCColors.navy900)
                    Image(systemName: "mic.fill")
                        .font(.system(size: largeText ? 34 : 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: et.iconBoxSize, height: et.iconBoxSize)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spreek het in")
                        .font(et.button)
                        .foregroundStyle(BCColors.navy900)
                    Text("Tik en vertel rustig wat u nodig heeft")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: BCSpacing.sm)

                ZStack {
                    Circle().fill(BCColors.accent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: largeText ? 24 : 20, weight: .bold))
                        .foregroundStyle(BCColors.navy900)
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
    }

    // STEP 0 — categorie
    private var categoryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Waar heeft u hulp bij nodig?")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                voiceInputCallout
                    .padding(.horizontal, BCSpacing.lg)

                HStack(spacing: BCSpacing.sm) {
                    Rectangle().fill(BCColors.border).frame(height: 1)
                    Text("of kies hieronder")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                    Rectangle().fill(BCColors.border).frame(height: 1)
                }
                .padding(.horizontal, BCSpacing.lg)

                // Smart description field
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Beschrijf in uw eigen woorden (optioneel)")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                    TextField("Bijv. \"ik kan niet naar de winkel lopen\"", text: $descriptionText, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .font(et.body)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.subtle)
                        .padding(.horizontal, BCSpacing.lg)
                        .onChange(of: descriptionText) { _, text in
                            if let match = recognizeCategory(from: text) {
                                selectedCategory = match
                            }
                        }
                    if let match = recognizeCategory(from: descriptionText), !descriptionText.isEmpty {
                        HStack(spacing: BCSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Herkend als: \(match.displayName)")
                                .font(BCTypography.captionEmphasized)
                        }
                        .foregroundStyle(BCColors.green700)
                        .padding(.horizontal, BCSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: descriptionText)

                let columns = largeText
                    ? [GridItem(.flexible())]
                    : [GridItem(.flexible(), spacing: BCSpacing.sm), GridItem(.flexible(), spacing: BCSpacing.sm)]
                LazyVGrid(columns: columns, spacing: BCSpacing.sm) {
                    ForEach(TaskCategory.allCases) { category in
                        CategoryTile(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if selectedCategory == .other {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Beschrijf wat er nodig is")
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .padding(.horizontal, BCSpacing.lg)
                        TextField("Bijv. \"samen naar de markt\" of \"hulp met de tablet\"", text: $otherDescription, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(et.body)
                            .padding(BCSpacing.md)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(
                                otherDescription.isEmpty ? Color.clear : BCColors.accent, lineWidth: otherDescription.isEmpty ? 0 : 1.5
                            ))
                            .bcSoftShadow(.subtle)
                            .padding(.horizontal, BCSpacing.lg)
                    }
                    .animation(.easeInOut(duration: 0.2), value: otherDescription)
                } else if let cat = selectedCategory {
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.xs) {
                            HStack {
                                Text(cat.displayName)
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.textPrimary)
                                Spacer()
                            }
                            Text(cat.description)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    // STEP 1 — tijd
    private var timingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                Text("Wanneer wilt u hulp?")
                    .font(et.heading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                // Eenmalig / Periodiek toggle
                Picker("", selection: $isRecurring) {
                    Text("Eenmalig").tag(false)
                    Text("Periodiek").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, BCSpacing.lg)
                .onChange(of: isRecurring) { _, _ in
                    selectedTiming = nil
                    useCustomDate = false
                }

                // Timing tiles
                VStack(spacing: BCSpacing.sm) {
                    if !isRecurring {
                        TimingTile(title: "Zo snel mogelijk", subtitle: "Een buddy in de buurt komt eraan",
                                   icon: "bolt.fill", isSelected: selectedTiming == .now && !useCustomDate) {
                            useCustomDate = false; selectedTiming = .now
                        }
                    }
                    TimingTile(title: "Zelf kiezen", subtitle: "Kies een datum en tijd",
                               icon: "calendar.badge.clock", isSelected: useCustomDate) {
                        useCustomDate = true; selectedTiming = .scheduled(date: customDate)
                    }
                    if useCustomDate {
                        DatePicker("", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(BCColors.accent)
                            .padding(BCSpacing.md)
                            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                            .bcSoftShadow(.card)
                            .onChange(of: customDate) { _, d in selectedTiming = .scheduled(date: d) }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                // Periodieke opties
                if isRecurring {
                    recurringSection
                }

                // Wie mag dit oppakken? Alleen zichtbaar bij een live zorg-team.
                if let team = myTeam, team.status == .live {
                    audienceSection(team: team)
                }

                // Opmerking
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Opmerking voor de buddy (optioneel)")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    TextField("Bijv. bel twee keer aan", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .font(et.body)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.subtle)
                }
                .padding(.horizontal, BCSpacing.lg)
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    /// Keuze tussen het eigen zorg-team (vaste kennissen) en de gewone
    /// buddy-pool. Geplande momenten gaan standaard het teamrooster in;
    /// spontane vragen gaan als gewone hulpvraag (het team krijgt op de
    /// server automatisch 8 minuten voorrang).
    @ViewBuilder
    private func audienceSection(team: CareTeam) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            if teamEligible {
                Text("Wie mag dit oppakken?")
                    .font(et.body)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)

                VStack(spacing: BCSpacing.sm) {
                    TimingTile(
                        title: "Mijn team: \(team.name)",
                        subtitle: team.members.isEmpty
                            ? "Uw vaste kennissen krijgen dit als eerste te zien"
                            : "Vaste kennissen: \(team.members.map(\.name).joined(separator: ", "))",
                        icon: "person.3.fill",
                        isSelected: audience == .team
                    ) {
                        userChoseAudience = true
                        audience = .team
                    }

                    TimingTile(
                        title: "Alle buddies",
                        subtitle: "Een beschikbare buddy in de buurt helpt u",
                        icon: "person.2.wave.2.fill",
                        isSelected: audience == .pool
                    ) {
                        userChoseAudience = true
                        audience = .pool
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if audience == .team {
                    Text(isRecurring
                            ? "De bezoeken komen in het inzetrooster van \(team.name); uw teamleden verdelen ze onderling."
                            : "Het bezoek komt in het rooster van \(team.name); uw teamleden spreken af wie er komt.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                }
            } else {
                // Spontane vraag ("zo snel mogelijk"): gewone hulpvraag, met
                // uitleg over de voorrang van het team.
                HStack(alignment: .top, spacing: BCSpacing.sm) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                        .padding(.top, 2)
                    Text(team.fallbackAllowed
                            ? "Uw team krijgt dit als eerste te zien; is er na 8 minuten niemand, dan vragen we buddies uit de buurt."
                            : "Alleen uw team krijgt deze vraag te zien.")
                        .font(et.caption)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, BCSpacing.lg)
            }
        }
        .onChange(of: selectedTiming) { _, _ in refreshDefaultAudience() }
        .onChange(of: isRecurring) { _, _ in refreshDefaultAudience() }
    }

    /// Geplande/periodieke vragen defaulten op het team; zodra het team niet
    /// (meer) gevraagd kan worden valt de keuze altijd terug op de pool.
    private func refreshDefaultAudience() {
        if !teamEligible {
            audience = .pool
        } else if !userChoseAudience {
            audience = .team
        }
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Hoe vaak?")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)

            // Vrije invoer: elke N dagen of weken (geen vaste vakjes meer).
            BCCard {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    HStack(spacing: BCSpacing.sm) {
                        Text("Elke")
                            .font(et.body)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("\(recurringIntervalCount)")
                            .font(et.button)
                            .foregroundStyle(BCColors.primary)
                            .frame(minWidth: 28)
                        Text(recurringIntervalCount == 1 ? recurringUnit.singular : recurringUnit.rawValue)
                            .font(et.body)
                            .foregroundStyle(BCColors.textPrimary)
                        Spacer()
                        Stepper("", value: $recurringIntervalCount, in: 1...30)
                            .labelsHidden()
                    }
                    Picker("", selection: $recurringUnit) {
                        Text("Dagen").tag(RecurringUnit.days)
                        Text("Weken").tag(RecurringUnit.weeks)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, BCSpacing.lg)

            Text("Tot wanneer?")
                .font(et.body)
                .foregroundStyle(BCColors.textPrimary)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.xs)

            // Alleen via de kalender kiezen (geen vaste presets meer).
            DatePicker("", selection: $recurringEndDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(BCColors.accent)
                .padding(BCSpacing.md)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .bcSoftShadow(.card)
                .padding(.horizontal, BCSpacing.lg)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // STEP 2 — bevestiging
    private var confirmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Klopt dit?")
                    .font(BCTypography.elderlyHeading)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                if needsAddress { addressRequiredCard }

                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        SummaryRow(label: "Soort hulp", value: selectedCategory?.displayName ?? "—",
                                   icon: selectedCategory?.icon ?? "questionmark")
                        Divider()
                        SummaryRow(label: "Wanneer", value: selectedTiming?.displayName ?? "—", icon: "clock.fill")
                        if let sched = recurringSchedule {
                            Divider()
                            SummaryRow(label: "Herhaling", value: sched.displayName, icon: "repeat")
                        }
                        if let team = myTeam, team.status == .live {
                            Divider()
                            SummaryRow(
                                label: "Wie",
                                value: (audience == .team && teamEligible)
                                    ? "Mijn team: \(team.name)"
                                    : (team.fallbackAllowed
                                        ? "Uw team eerst, daarna buddies in de buurt"
                                        : "Alleen uw team"),
                                icon: audience == .team ? "person.3.fill" : "person.2.wave.2.fill"
                            )
                        }
                        if audience == .team && plannedTeamDates.count > 1 {
                            Divider()
                            SummaryRow(label: "Inzetrooster",
                                       value: "\(min(plannedTeamDates.count, 52)) bezoeken worden ingepland",
                                       icon: "calendar.badge.clock")
                        }
                        if !needsAddress {
                            Divider()
                            SummaryRow(label: "Adres", value: targetElderly.address, icon: "house.fill")
                        }
                        if !note.isEmpty {
                            Divider()
                            SummaryRow(label: "Opmerking", value: note, icon: "text.bubble.fill")
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                Text("Door op Bevestigen te tikken vraagt u officieel hulp aan. We zoeken meteen een vrijwilliger in de buurt voor u.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .padding(.horizontal, BCSpacing.lg)
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: BCSpacing.sm) {
            Divider()
            HStack(spacing: BCSpacing.sm) {
                if step > 0 {
                    BCSecondaryButton(title: "Terug", icon: "chevron.left", fullWidth: true) {
                        step -= 1
                    }
                }
                BCCTAButton(
                    title: step == 2 ? "Bevestigen" : "Volgende",
                    icon: step == 2 ? "checkmark" : "arrow.right",
                    fullWidth: true
                ) {
                    next()
                }
                .opacity(canContinue ? 1.0 : 0.5)
                .disabled(!canContinue)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.md)
        }
        .background(BCColors.background)
    }

    /// Heeft de hulpvrager nog geen adres? Dan is invullen verplicht vóór bevestigen.
    private var needsAddress: Bool {
        targetElderly.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var addressReady: Bool {
        !addressInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canContinue: Bool {
        switch step {
        case 0: return selectedCategory != nil && (selectedCategory != .other || !otherDescription.isEmpty)
        case 1: return selectedTiming != nil && (!isRecurring || recurringEndDate > Date())
        case 2: return (!needsAddress || addressReady) && !addressSaving
        default: return false
        }
    }

    private func next() {
        if step < 2 {
            step += 1
        } else {
            confirm()
        }
    }

    private var addressRequiredCard: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill").foregroundStyle(BCColors.primary)
                    Text("Vul eerst het adres in").font(et.button).foregroundStyle(BCColors.textPrimary)
                }
                Text("Begin met typen en kies uw adres uit de lijst, zodat de buddy precies weet waar de hulp moet komen.")
                    .font(et.caption).foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                AddressAutocompleteField(
                    placeholder: "Straat, huisnummer, plaats",
                    text: $addressInput,
                    font: et.body,
                    onManualEdit: { addressError = nil; pickedCoordinate = nil }
                ) { coord, formatted in
                    pickedCoordinate = coord
                    addressInput = formatted
                    addressError = nil
                }
                if let addressError {
                    Text(addressError).font(et.caption).foregroundStyle(BCColors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    private func confirm() {
        guard let cat = selectedCategory, let timing = selectedTiming else { return }
        let finalNote = cat == .other && !otherDescription.isEmpty
            ? (otherDescription + (note.isEmpty ? "" : "\n\(note)"))
            : note

        // Geen adres? Eerst geocoderen + opslaan, dan pas de aanvraag afronden.
        if needsAddress {
            saveAddressThenRequest(cat: cat, timing: timing, note: finalNote)
            return
        }
        fireRequest(cat: cat, timing: timing, note: finalNote, elderly: onBehalfOf)
        // Toon eerst een duidelijke succes-animatie; de overlay dismisst zelf.
        withAnimation(.easeOut(duration: 0.25)) { showSuccess = true }
    }

    private func fireRequest(cat: TaskCategory, timing: TaskTiming, note: String, elderly: ElderlyUser?) {
        let finalAudience: HelpAudience = (audience == .team && teamEligible) ? .team : .pool
        if let elderly {
            appState.requestHelpOnBehalf(for: elderly, category: cat, timing: timing,
                                         note: note, recurringSchedule: recurringSchedule,
                                         audience: finalAudience)
        } else {
            appState.requestHelp(category: cat, timing: timing, note: note,
                                 recurringSchedule: recurringSchedule,
                                 audience: finalAudience)
        }
    }

    /// Geocodeert het ingevoerde adres, bewaart het op het profiel van de
    /// hulpvrager en rondt daarna pas de aanvraag af. Lukt geocoderen niet, dan
    /// blijft de gebruiker op deze stap met een foutmelding.
    private func saveAddressThenRequest(cat: TaskCategory, timing: TaskTiming, note: String) {
        let trimmed = addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addressError = nil
        addressSaving = true
        let elderlyId = targetElderly.id
        let isLive = appState.isLive
        let onBehalf = onBehalfOf
        let picked = pickedCoordinate
        Task {
            // Voorkeur: exacte coördinaat uit de suggestielijst; anders geocoderen.
            let resolved: CLLocationCoordinate2D?
            if let picked {
                resolved = picked
            } else {
                resolved = await AddressGeocoder.coordinate(for: trimmed)
            }
            guard let coord = resolved else {
                await MainActor.run {
                    addressSaving = false
                    addressError = "We konden dit adres niet vinden. Kies het adres uit de lijst en probeer opnieuw."
                }
                return
            }
            if isLive {
                try? await ProfileService().updateElderlyLocation(
                    elderlyId: elderlyId, address: trimmed,
                    latitude: coord.latitude, longitude: coord.longitude
                )
            }
            await MainActor.run {
                var corrected: ElderlyUser? = nil
                if onBehalf == nil {
                    appState.elderlyUser.address = trimmed
                    appState.elderlyUser.coordinate = coord
                } else {
                    var e = onBehalf!
                    e.address = trimmed
                    e.coordinate = coord
                    corrected = e
                    if appState.activeFamilyElderly.id == e.id {
                        appState.activeFamilyElderly.address = trimmed
                        appState.activeFamilyElderly.coordinate = coord
                    }
                }
                addressSaving = false
                fireRequest(cat: cat, timing: timing, note: note, elderly: corrected)
                withAnimation(.easeOut(duration: 0.25)) { showSuccess = true }
            }
        }
    }
}

// MARK: - Smart recognition

private func recognizeCategory(from text: String) -> TaskCategory? {
    guard text.count > 3 else { return nil }
    let t = text.lowercased()
    let rules: [(words: [String], category: TaskCategory)] = [
        (["boodschap", "supermarkt", "winkel", "inkopen", "winkelen", "albert", "jumbo", "halen"],       .groceries),
        (["telefoon", "tablet", "computer", "internet", "videobel", "whatsapp", "e-mail", "email", "digitaal", "app"], .digitalHelp),
        (["schoon", "opruim", "stofzuig", "poets", "klusje", "klusjes", "tuin", "planten", "afwas", "rommel"], .lightCleaning),
        (["koffie", "gezelschap", "praatje", "kletsen", "samen", "spelletje", "voorlezen", "kaarten"],   .companionship),
        (["eenzaam", "verdriet", "luisteren", "luisterend", "praten", "alleen", "down"],                 .socialSupport),
        (["eten", "maaltijd", "koken", "lunch", "uitje", "museum", "activiteit", "samen koken"],         .activity),
        (["wandel", "lopen", "buiten", "ommetje", "frisse lucht", "park"],                               .walkOutdoors),
        (["dokter", "ziekenhuis", "afspraak", "arts", "specialist", "apotheek", "tandarts"],             .appointment),
    ]
    for rule in rules {
        if rule.words.contains(where: { t.contains($0) }) { return rule.category }
    }
    return nil
}

