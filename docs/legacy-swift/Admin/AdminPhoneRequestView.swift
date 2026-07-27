import SwiftUI

struct AdminPhoneRequestView: View {
    @Environment(AppState.self) private var appState

    @State private var step: Int = 0
    @State private var searchText: String = ""
    @State private var selectedElderly: ElderlyUser? = nil
    @State private var selectedCategory: TaskCategory? = nil
    @State private var otherDescription: String = ""
    @State private var selectedTiming: TaskTiming? = nil
    @State private var useCustomDate: Bool = false
    @State private var customDate: Date = Date().addingTimeInterval(3600)
    @State private var note: String = ""

    private var searchResults: [ElderlyUser] {
        guard !searchText.isEmpty else { return appState.allElderlyUsers }
        let q = searchText.lowercased()
        return appState.allElderlyUsers.filter {
            $0.firstName.lowercased().contains(q) ||
            $0.lastName.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(
                title: "Telefonisch",
                subtitle: step == 0 ? "Zoek de oudere op naam" : "Aanvraag voor \(selectedElderly?.firstName ?? "")"
            )

            if step > 0 {
                progressBar
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.vertical, BCSpacing.sm)
            }

            Group {
                switch step {
                case 0: searchStep
                case 1: categoryStep
                case 2: timingStep
                case 3: confirmStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if step > 0 {
                bottomBar
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    // MARK: - Progressiebalk (stap 1–3)

    private var progressBar: some View {
        HStack(spacing: BCSpacing.xs) {
            ForEach(1..<4) { i in
                Capsule()
                    .fill(i <= step ? BCColors.primary : BCColors.border)
                    .frame(height: 5)
            }
        }
    }

    // MARK: - Stap 0: Zoek oudere

    private var searchStep: some View {
        VStack(spacing: 0) {
            // Zoekbalk
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(BCColors.textTertiary)
                TextField("Zoek op naam...", text: $searchText)
                    .font(BCTypography.body)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BCColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.surface)
            )
            .bcSoftShadow(.subtle)
            .padding(.horizontal, BCSpacing.lg)
            .padding(.top, BCSpacing.md)
            .padding(.bottom, BCSpacing.sm)

            Divider()

            ScrollView {
                VStack(spacing: BCSpacing.sm) {
                    if searchResults.isEmpty {
                        BCCard {
                            BCEmptyState(
                                icon: "person.fill.questionmark",
                                title: "Geen ouderen gevonden",
                                message: "Pas de zoekterm aan om iemand te vinden."
                            )
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else {
                        ForEach(searchResults) { elderly in
                            ElderlySearchCard(elderly: elderly) {
                                selectedElderly = elderly
                                step = 1
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }
                    }
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
    }

    // MARK: - Stap 1: Categorie

    private var categoryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Waar heeft \(selectedElderly?.firstName ?? "de oudere") hulp bij nodig?")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                BCCard {
                    VStack(spacing: 0) {
                        ForEach(Array(TaskCategory.allCases.enumerated()), id: \.element) { index, category in
                            if index > 0 { Divider().padding(.leading, 52) }
                            AdminCategoryRow(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                otherDescription = ""
                            }
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if selectedCategory == .other {
                    VStack(alignment: .leading, spacing: BCSpacing.xs) {
                        Text("Omschrijf de hulpvraag")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                            .padding(.horizontal, BCSpacing.lg)
                        BCCard {
                            TextField("Bijv. \"hulp bij douchen en aankleden\"", text: $otherDescription, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    }
                }
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    // MARK: - Stap 2: Tijdstip

    private var timingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Wanneer heeft \(selectedElderly?.firstName ?? "de oudere") hulp nodig?")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                BCCard {
                    VStack(spacing: 0) {
                        AdminTimingRow(title: "Zo snel mogelijk", subtitle: "Een buddy in de buurt komt eraan",
                                       icon: "bolt.fill",
                                       isSelected: selectedTiming == .now && !useCustomDate) {
                            useCustomDate = false; selectedTiming = .now
                        }
                        Divider().padding(.leading, 52)
                        AdminTimingRow(title: "Zelf kiezen", subtitle: "Kies een datum en tijd",
                                       icon: "calendar.badge.clock",
                                       isSelected: useCustomDate) {
                            useCustomDate = true; selectedTiming = .scheduled(date: customDate)
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                if useCustomDate {
                    BCCard {
                        DatePicker("", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(BCColors.primary)
                            .onChange(of: customDate) { _, d in selectedTiming = .scheduled(date: d) }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: useCustomDate)
                }

                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    Text("Opmerking voor de buddy (optioneel)")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, BCSpacing.lg)
                    BCCard {
                        TextField("Bijv. bel twee keer aan", text: $note, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .font(BCTypography.body)
                            .foregroundStyle(BCColors.textPrimary)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    // MARK: - Stap 3: Bevestiging

    private var confirmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                Text("Controleer de aanvraag")
                    .font(BCTypography.title3)
                    .foregroundStyle(BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                // Oudere kaartje
                if let elderly = selectedElderly {
                    BCCard {
                        HStack(spacing: BCSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(BCColors.primary.opacity(0.08))
                                    .frame(width: 44, height: 44)
                                Text(initials(elderly))
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(elderly.firstName) \(elderly.lastName)")
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.textPrimary)
                                if let phone = elderly.phoneNumber {
                                    Text(phone)
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Text(elderly.address)
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }

                // Samenvatting aanvraag
                BCCard {
                    VStack(alignment: .leading, spacing: BCSpacing.sm) {
                        PhoneSummaryRow(label: "Soort hulp",
                                        value: selectedCategory?.displayName ?? "—",
                                        icon: selectedCategory?.icon ?? "questionmark")
                        Divider()
                        PhoneSummaryRow(label: "Wanneer",
                                        value: selectedTiming?.displayName ?? "—",
                                        icon: "clock.fill")
                        if !note.isEmpty {
                            Divider()
                            PhoneSummaryRow(label: "Opmerking", value: note, icon: "text.bubble.fill")
                        }
                    }
                }
                .padding(.horizontal, BCSpacing.lg)

                Text("Na bevestigen wordt de aanvraag direct zichtbaar voor buddies in de buurt.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
                    .padding(.horizontal, BCSpacing.lg)
            }
            .padding(.bottom, BCSpacing.lg)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: BCSpacing.sm) {
                BCSecondaryButton(title: step == 1 ? "Annuleer" : "Terug",
                                  icon: "chevron.left", fullWidth: true) {
                    if step == 1 {
                        reset()
                    } else {
                        step -= 1
                    }
                }
                BCPrimaryButton(
                    title: step == 3 ? "Aanvraag plaatsen" : "Volgende",
                    icon: step == 3 ? "checkmark" : "chevron.right",
                    fullWidth: true
                ) {
                    next()
                }
                .opacity(canContinue ? 1.0 : 0.5)
                .disabled(!canContinue)
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.vertical, BCSpacing.md)
        }
        .background(BCColors.background)
    }

    private var canContinue: Bool {
        switch step {
        case 1: return selectedCategory != nil && (selectedCategory != .other || !otherDescription.isEmpty)
        case 2: return selectedTiming != nil
        case 3: return true
        default: return false
        }
    }

    private func next() {
        if step < 3 {
            step += 1
        } else {
            placeRequest()
        }
    }

    private func placeRequest() {
        guard let elderly = selectedElderly,
              let category = selectedCategory,
              let timing = selectedTiming else { return }
        let finalNote = category == .other && !otherDescription.isEmpty
            ? (otherDescription + (note.isEmpty ? "" : "\n\(note)"))
            : note
        appState.requestHelpOnBehalf(
            for: elderly,
            category: category,
            timing: timing,
            note: finalNote
        )
        reset()
    }

    private func reset() {
        step = 0
        searchText = ""
        selectedElderly = nil
        selectedCategory = nil
        otherDescription = ""
        selectedTiming = nil
        useCustomDate = false
        customDate = Date().addingTimeInterval(3600)
        note = ""
    }

    private func initials(_ elderly: ElderlyUser) -> String {
        "\(elderly.firstName.prefix(1))\(elderly.lastName.prefix(1))"
    }
}

// MARK: - Elderly zoekkaartje

private struct ElderlySearchCard: View {
    let elderly: ElderlyUser
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            BCCard {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(BCColors.primary.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Text("\(elderly.firstName.prefix(1))\(elderly.lastName.prefix(1))")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(elderly.firstName) \(elderly.lastName)")
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        if let phone = elderly.phoneNumber {
                            Label(phone, systemImage: "phone.fill")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        Label(elderly.address, systemImage: "house.fill")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Categorie rij (admin stijl)

private struct AdminCategoryRow: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? BCColors.primary : BCColors.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(category.description)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BCColors.primary)
                        .font(.system(size: 18))
                }
            }
            .padding(.vertical, BCSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timing rij (admin stijl)

private struct AdminTimingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? BCColors.primary : BCColors.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(subtitle)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BCColors.primary)
                        .font(.system(size: 18))
                }
            }
            .padding(.vertical, BCSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Samenvatting rij

private struct PhoneSummaryRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                Text(value)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
            }
            Spacer()
        }
    }
}

#Preview {
    AdminPhoneRequestView().environment(AppState())
}
