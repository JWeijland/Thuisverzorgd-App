import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import CoreLocation

struct BuddyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showVOGImporter = false
    @State private var notifyNewRequest = true
    @State private var notifyMessages = true
    @State private var showPrivacy = false
    @State private var photoItem: PhotosPickerItem?
    @State private var addressDraft: String = ""
    @State private var addressCoordinate: CLLocationCoordinate2D? = nil
    @State private var bioDraft: String = ""
    @State private var birthDate: Date? = nil
    @State private var expanded: DetailSection? = nil
    @State private var showIntakePlanner = false
    @Environment(\.openURL) private var openURL
    @ObservedObject private var avatars = AvatarStore.shared

    /// De uitklapbare onderdelen van de subtiele profiel-lijst (accordeon).
    private enum DetailSection { case overMij, buurt, geboorte, verificatie, beoordelingen, meldingen }

    var body: some View {
        BCProfileScaffold(eyebrow: "Mijn profiel") {
            avatarBlock
            statRow
            if !appState.buddyFans.isEmpty { fansCard }
            availabilityCard
            detailsList

            BCSignOutButton { Task { await appState.signOut() } }
                .padding(.top, BCSpacing.xs)
        }
        .fileImporter(
            isPresented: $showVOGImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handleVOGImport(result)
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.myIntakeCall != nil },
            set: { if !$0 { appState.myIntakeCall = nil } }
        )) {
            IntakeCallSheet()
        }
        .sheet(isPresented: $showPrivacy) { PrivacyConsentSheet() }
        .sheet(isPresented: $showIntakePlanner) { IntakePlannerSheet() }
        .onAppear {
            if addressDraft.isEmpty { addressDraft = appState.buddyUser.address }
            if bioDraft.isEmpty { bioDraft = appState.buddyUser.bio }
            if birthDate == nil { birthDate = appState.buddyUser.dateOfBirth }
            // Verificatie meteen open als de buddy nog niet kan aannemen (actie nodig).
            if !appState.buddyUser.canAcceptTasks { expanded = .verificatie }
            Task { await appState.refreshMyScheduledCall() }
        }
        .onChange(of: appState.buddyUser.address) { _, new in
            if addressDraft.isEmpty { addressDraft = new }
        }
        .onChange(of: appState.buddyUser.bio) { _, new in
            if bioDraft.isEmpty { bioDraft = new }
        }
    }

    // MARK: - Avatar + naam

    private var avatarBlock: some View {
        VStack(spacing: BCSpacing.md) {
            BCProfileAvatar(image: avatars.image,
                            systemName: appState.buddyUser.avatarSystemName)
                .overlay(alignment: .bottomTrailing) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(BCColors.primary))
                            .overlay(Circle().stroke(BCColors.surface, lineWidth: 2))
                    }
                }
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task {
                        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                        await MainActor.run { avatars.set(data) }
                        if appState.isLive, let id = appState.realUserId {
                            _ = try? await ProfileService().uploadBuddyAvatar(buddyId: id, imageData: data)
                        }
                    }
                }

            VStack(spacing: 4) {
                Text(appState.buddyUser.fullName)
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)
                Text(appState.buddyUser.study)
                    .font(BCTypography.subheadline)
                    .foregroundStyle(BCColors.textSecondary)
                if let orgName = appState.organizationName {
                    BCOrganizationTag(name: orgName)
                        .padding(.top, 5)
                }
            }
        }
    }

    // MARK: - Statistieken-band

    private var statRow: some View {
        // Alle statwaarden krijgen dezelfde kleur (textPrimary), zodat "Nieuw" niet
        // grijs afsteekt tegen de cijfers (punt 17).
        BCProfileStatRow(stats: [
            .init(value: appState.buddyUser.ratingAverage > 0
                    ? String(format: "%.1f", appState.buddyUser.ratingAverage) : "Nieuw",
                  label: "Beoordeling"),
            .init(value: "\(appState.buddyUser.totalTasks)", label: "Bezoeken"),
            .init(value: "\(appState.buddyReviews.count)", label: "Reviews"),
        ])
    }

    // MARK: - Vaste buddy van …

    /// Warm blok dat laat zien welke hulpvragers deze buddy als vaste buddy
    /// hebben gekozen — het persoonlijke bewijs dat je het verschil maakt.
    private var fansCard: some View {
        HStack(spacing: BCSpacing.md) {
            ZStack {
                Circle().fill(BCColors.danger.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(BCColors.danger)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Vaste buddy van \(fansList)")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(appState.buddyFans.count == 1
                        ? "Deze hulpvrager koos jou als vertrouwd gezicht."
                        : "Deze hulpvragers kozen jou als vertrouwd gezicht.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
            Spacer()
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
    }

    private var fansList: String {
        let names = appState.buddyFans
        if names.count <= 2 { return names.joined(separator: " en ") }
        return names.prefix(2).joined(separator: ", ") + " en \(names.count - 2) anderen"
    }

    // MARK: - Beschikbaarheid

    private var availabilityCard: some View {
        HStack(spacing: BCSpacing.sm) {
            Image(systemName: appState.isAvailableNow ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(appState.isAvailableNow ? BCColors.success : BCColors.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(appState.isAvailableNow ? "Beschikbaar voor taken" : "Niet beschikbaar")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text(appState.isAvailableNow ? "Je bent zichtbaar voor hulpvragers in de buurt" : "Je ontvangt geen nieuwe hulpvragen")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { appState.isAvailableNow },
                                     set: { appState.isAvailableNow = $0 }))
                .labelsHidden()
                .tint(BCColors.accent)
        }
        .padding(BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.accent.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                    .stroke(BCColors.accent.opacity(0.30), lineWidth: 1))
        )
    }

    // MARK: - Profiel-lijst (subtiel, met scheidingslijntjes)

    private var detailsList: some View {
        VStack(spacing: BCSpacing.lg) {
            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Mijn gegevens")
                BCInsetCard {
                    VStack(spacing: 0) {
                        row(.overMij, label: "Over mij", value: bioValue, valueColor: bioValueColor,
                            visible: appState.buddyUser.showsBio)
                        if expanded == .overMij { overMijEditor }
                        BCHairline(leading: 0)

                        row(.buurt, label: "Mijn buurt", value: addressValue, valueColor: addressValueColor,
                            visible: appState.buddyUser.showsNeighborhood)
                        if expanded == .buurt { buurtEditor }
                        BCHairline(leading: 0)

                        row(.geboorte, label: "Geboortedatum", value: geboorteValue, valueColor: geboorteValueColor,
                            visible: appState.buddyUser.showsBirthDate)
                        if expanded == .geboorte { geboorteEditor }
                    }
                    .padding(.horizontal, BCSpacing.md)
                }
            }

            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Account")
                BCInsetCard {
                    VStack(spacing: 0) {
                        row(.verificatie, label: "Verificatie", value: verificatieValue, valueColor: verificatieValueColor)
                        if expanded == .verificatie { verificatieDetails }
                        BCHairline(leading: 0)

                        row(.beoordelingen, label: "Beoordelingen", value: beoordelingenValue)
                        if expanded == .beoordelingen { beoordelingenDetails }
                        BCHairline(leading: 0)

                        row(.meldingen, label: "Meldingen")
                        if expanded == .meldingen { meldingenDetails }
                    }
                    .padding(.horizontal, BCSpacing.md)
                }
            }
        }
    }

    /// Eén nette lijstregel: label links, waarde + chevron rechts. Tikken klapt
    /// het bijbehorende onderdeel uit/in (accordeon — er is er steeds één open).
    private func row(_ section: DetailSection, label: String,
                     value: String? = nil, valueColor: Color = BCColors.textTertiary,
                     visible: Bool? = nil) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if expanded != section { prepareDraft(for: section) }
            withAnimation(.easeInOut(duration: 0.22)) {
                expanded = (expanded == section) ? nil : section
            }
        } label: {
            HStack(spacing: BCSpacing.sm) {
                Text(label)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                    .layoutPriority(1)
                if let visible {
                    BCVisibilityTag(isVisible: visible)
                }
                Spacer(minLength: BCSpacing.sm)
                if let value, !value.isEmpty {
                    Text(value)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(valueColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
                    .rotationEffect(.degrees(expanded == section ? 90 : 0))
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func prepareDraft(for section: DetailSection) {
        switch section {
        case .overMij:  bioDraft = appState.buddyUser.bio
        case .buurt:    addressDraft = appState.buddyUser.address; addressCoordinate = nil
        case .geboorte: birthDate = appState.buddyUser.dateOfBirth
        default:        break
        }
    }

    private func collapse() {
        withAnimation(.easeInOut(duration: 0.22)) { expanded = nil }
    }

    // MARK: Waarde-labels per regel (rechts in de lijst)

    private var bioValue: String {
        let b = appState.buddyUser.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return b.isEmpty ? "Toevoegen" : b
    }
    private var bioValueColor: Color {
        appState.buddyUser.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? BCColors.primary : BCColors.textTertiary
    }
    private var addressValue: String {
        let a = appState.buddyUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        return a.isEmpty ? "Toevoegen" : a
    }
    private var addressValueColor: Color {
        appState.buddyUser.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? BCColors.primary : BCColors.textTertiary
    }
    private var geboorteValue: String {
        if let age = appState.buddyUser.age, appState.buddyUser.dateOfBirth != nil { return "\(age) jaar" }
        return "Toevoegen"
    }
    private var geboorteValueColor: Color {
        appState.buddyUser.dateOfBirth == nil ? BCColors.primary : BCColors.textTertiary
    }
    private var verificatieValue: String {
        appState.buddyUser.canAcceptTasks ? "Geverifieerd" : "Actie nodig"
    }
    private var verificatieValueColor: Color {
        appState.buddyUser.canAcceptTasks ? BCColors.success : BCColors.warning
    }
    private var beoordelingenValue: String {
        appState.buddyReviews.isEmpty ? "Nog geen" : String(format: "%.1f ★", appState.buddyUser.ratingAverage)
    }

    // MARK: Uitgeklapte editors / details

    private var overMijEditor: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Vertel kort wie je bent. Hulpvragers zien dit op je profiel.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            TextField("Bijv. Hoi! Ik help graag met gezelschap en een wandeling.",
                      text: $bioDraft, axis: .vertical)
                .font(BCTypography.body)
                .lineLimit(3...8)
                .padding(BCSpacing.md)
                .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).fill(BCColors.surfaceMuted))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous).stroke(BCColors.border, lineWidth: 1))
            BCVisibilityToggle(isVisible: Binding(
                get: { appState.buddyUser.showsBio },
                set: { appState.setBuddyFieldVisibility(bio: $0) }))
            BCPrimaryButton(title: "Over mij opslaan", icon: "checkmark",
                            cornerRadius: BCRadius.sm, height: 52) {
                appState.saveBuddyBio(bioDraft)
                collapse()
            }
            .disabled(bioDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                      == appState.buddyUser.bio.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        .padding(.bottom, BCSpacing.md)
    }

    private var buurtEditor: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Begin met typen en kies je adres uit de lijst. We gebruiken het altijd om hulpvragen in jouw omgeving te tonen. Met de schakelaar hieronder bepaal je zelf of je buurt ook op je openbare profiel staat.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            AddressAutocompleteField(placeholder: "Straat + plaats", text: $addressDraft,
                                     onManualEdit: { addressCoordinate = nil }) { coord, formatted in
                addressCoordinate = coord
                addressDraft = formatted
            }
            BCVisibilityToggle(isVisible: Binding(
                get: { appState.buddyUser.showsNeighborhood },
                set: { appState.setBuddyFieldVisibility(neighborhood: $0) }))
            BCPrimaryButton(title: "Adres opslaan", icon: "checkmark",
                            cornerRadius: BCRadius.sm, height: 52) {
                appState.saveBuddyAddress(addressDraft, coordinate: addressCoordinate)
                collapse()
            }
            .disabled(addressDraft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.bottom, BCSpacing.md)
    }

    private var geboorteEditor: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text("Vul je geboortedatum in zodat hij op je profiel staat.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
            BirthDateField(date: $birthDate)
            BCVisibilityToggle(isVisible: Binding(
                get: { appState.buddyUser.showsBirthDate },
                set: { appState.setBuddyFieldVisibility(birthDate: $0) }))
            BCPrimaryButton(title: "Opslaan", icon: "checkmark",
                            cornerRadius: BCRadius.sm, height: 52) {
                if let dob = birthDate { appState.saveBuddyDateOfBirth(dob); collapse() }
            }
            .disabled(birthDate == nil)
        }
        .padding(.bottom, BCSpacing.md)
    }

    /// Eén gedeeld statusvocabulaire voor beide verificatie-stappen (intake + VOG),
    /// zodat ze exact dezelfde badge en dezelfde woorden gebruiken.
    private enum VerificationStepStatus {
        case todo, inProgress, approved, rejected

        var label: String {
            switch self {
            case .todo:       return "Nog te doen"
            case .inProgress: return "In behandeling"
            case .approved:   return "Goedgekeurd"
            case .rejected:   return "Afgewezen"
            }
        }
        var color: Color {
            switch self {
            case .todo:       return BCColors.textTertiary
            case .inProgress: return BCColors.warning
            case .approved:   return BCColors.success
            case .rejected:   return BCColors.danger
            }
        }
    }

    private var intakeStepStatus: VerificationStepStatus {
        appState.buddyUser.intakeCompleted ? .approved : .todo
    }

    private var vogStepStatus: VerificationStepStatus {
        switch appState.buddyUser.vogStatus {
        case .geldig:                       return .approved
        case .inBehandeling, .aangevraagd:  return .inProgress
        case .afgewezen, .verlopen:         return .rejected
        case .nietAangevraagd:              return .todo
        }
    }

    /// Verificatie als helder 2-stappenplan: Stap 1 Korte intake, Stap 2 VOG. Beide
    /// stappen tonen dezelfde genummerde opmaak en dezelfde status-badge.
    private var verificatieDetails: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            Text("Je account wordt in 2 stappen geverifieerd. Beide moeten goedgekeurd zijn voordat je hulpvragen kunt aannemen.")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            verificationStepRow(number: 1, title: "Korte intake",
                                subtitle: "Kort videogesprek met een medewerker.",
                                status: intakeStepStatus)
            verificationStepRow(number: 2, title: "VOG",
                                subtitle: "Verklaring Omtrent het Gedrag.",
                                status: vogStepStatus)

            // Actie hoort bij de eerstvolgende openstaande stap.
            if !appState.buddyUser.vogStatus.isVerified {
                vogActions
                    .padding(.top, BCSpacing.xs)
            } else if !appState.buddyUser.intakeCompleted {
                intakeStepActions
                    .padding(.top, BCSpacing.xs)
            }
        }
        .padding(.vertical, BCSpacing.sm)
    }

    /// Laatste stap: intakegesprek. Buddy plant zelf een moment of sluit direct aan
    /// in de wachtrij. Is er al een afspraak, dan tonen we die met agenda-knoppen.
    @ViewBuilder
    private var intakeStepActions: some View {
        if let scheduled = appState.myScheduledCall, let date = scheduled.scheduledDate {
            scheduledCallCard(date: date, link: scheduled.meetingUrl)
        } else {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                Text("Laatste stap: een kort intake-videogesprek. Kies zelf een moment, of sluit nu aan in de wachtrij.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                BCPrimaryButton(title: "Kies zelf een moment", icon: "calendar.badge.plus",
                                cornerRadius: BCRadius.sm, height: 52) {
                    showIntakePlanner = true
                }
                BCSecondaryButton(title: "Nu in de wachtrij", icon: "video.fill") {
                    appState.startIntakeCall()
                }
            }
        }
    }

    /// Bevestigde afspraak: datum/tijd + knoppen om in de agenda te zetten en te starten.
    private func scheduledCallCard(date: Date, link: String?) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(BCColors.success)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intakegesprek ingepland")
                        .font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                    Text(intakeDateFormatter.string(from: date))
                        .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                }
            }
            Text("Zet de afspraak in je agenda zodat je hem niet vergeet. Open de app op dat moment om deel te nemen.")
                .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: BCSpacing.sm) {
                Button { addToAppleAgenda(date: date, link: link) } label: {
                    Label("Apple Agenda", systemImage: "calendar")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().stroke(BCColors.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                Button {
                    if let url = IntakeAgenda.googleCalendarURL(start: date, link: link) { openURL(url) }
                } label: {
                    Label("Google Agenda", systemImage: "calendar")
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().stroke(BCColors.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }

            BCPrimaryButton(title: "Nu starten", icon: "video.fill",
                            cornerRadius: BCRadius.sm, height: 52) {
                appState.startIntakeCall()
            }
            Button(role: .destructive) {
                appState.cancelScheduledIntakeCall()
            } label: {
                Text("Afspraak annuleren")
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(BCColors.danger)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surfaceMuted))
    }

    private func addToAppleAgenda(date: Date, link: String?) {
        Task {
            if let error = await IntakeAgenda.addToAppleCalendar(start: date, link: link) {
                appState.showToast(text: error, icon: "exclamationmark.triangle.fill")
            } else {
                appState.showToast(text: "In je agenda gezet.", icon: "calendar.badge.checkmark")
            }
        }
    }

    /// Eén genummerde stap-rij: bolletje met stapnummer, titel + uitleg, gedeelde pill.
    private func verificationStepRow(number: Int, title: String, subtitle: String,
                                     status: VerificationStepStatus) -> some View {
        HStack(alignment: .top, spacing: BCSpacing.md) {
            Text("\(number)")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(status == .approved ? BCColors.success : BCColors.primary))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                Text(subtitle).font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: BCSpacing.sm)
            BCStatusPill(label: status.label, color: status.color, showDot: true)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var beoordelingenDetails: some View {
        VStack(spacing: BCSpacing.sm) {
            if appState.buddyReviews.isEmpty {
                BCEmptyState(
                    icon: "star",
                    title: "Nog geen beoordelingen",
                    message: "Zodra je iemand hebt geholpen en die persoon een beoordeling schrijft, verschijnt die hier."
                )
            } else {
                ForEach(appState.buddyReviews) { review in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: BCSpacing.sm) {
                            BCRatingStars(value: Double(review.stars))
                            Spacer()
                            Text(dateFormatter.string(from: review.date))
                                .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                        }
                        Text(review.body).font(BCTypography.body).foregroundStyle(BCColors.textPrimary)
                        Text("van \(review.authorName)").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BCSpacing.xs)
                }
            }
        }
        .padding(.bottom, BCSpacing.md)
    }

    private var meldingenDetails: some View {
        VStack(spacing: 0) {
            BCProfileToggleRow(title: "Nieuwe hulpvraag in de buurt", isOn: $notifyNewRequest)
            BCHairline(leading: 18)
            BCProfileToggleRow(title: "Berichten", isOn: $notifyMessages)
            BCHairline(leading: 18)
            BCProfileNavRow(title: "Hoe werkt de app?", icon: "questionmark.circle") {
                appState.replayWalkthrough(.buddy)
            }
            BCHairline(leading: 18)
            BCProfileNavRow(title: "Privacy & gegevens") { showPrivacy = true }
        }
        .padding(.bottom, BCSpacing.sm)
    }

    // MARK: - VOG-acties

    /// Inspringing gelijk aan de icoon-/nummerkolom van de status-rijen (26 + md),
    /// zodat losse uitleg-tekst uitlijnt met "Korte intake" / "VOG" i.p.v. met de
    /// icoon-rand (punt 20).
    private var verificationTextInset: CGFloat { 26 + BCSpacing.md }

    @ViewBuilder
    private var vogActions: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            switch appState.buddyUser.vogStatus {
            case .verlopen, .afgewezen:
                // Punt 22: expliciet maken WAAROM er (nu) geen hulp kan worden aangenomen.
                vogBlockedNotice
                vogRequestButtons

            case .nietAangevraagd:
                // Punt 20: meer ruimte boven/onder en uitlijnen met de status-tekst.
                Text("Heb je al een VOG? Upload 'm dan direct. Anders vragen we 'm gratis voor je aan.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, verificationTextInset)
                    .padding(.vertical, BCSpacing.sm)
                vogRequestButtons

            case .aangevraagd, .inBehandeling:
                Text(appState.buddyUser.vogStatus == .inBehandeling
                     ? "We controleren je VOG. Je kunt hulpvragen aannemen zodra deze is goedgekeurd."
                     : "Je VOG-aanvraag loopt. Je krijgt bericht zodra deze rond is.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, verificationTextInset)
                    .padding(.vertical, BCSpacing.sm)

            case .geldig:
                EmptyView()
            }

            #if DEBUG
            // Alleen in debug-builds: meteen verifiëren zonder de echte stappen.
            // In TestFlight/Release is deze knop weg — daar geldt de echte VOG +
            // intake-flow.
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                appState.demoVerifyBuddy()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill").font(.system(size: 13, weight: .bold))
                    Text("Sla over voor demo (verifieer mij)")
                        .font(BCTypography.captionEmphasized)
                }
                .foregroundStyle(BCColors.navy900)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(BCColors.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, BCSpacing.xs)
            #endif
        }
    }

    /// Duidelijke reden + vervolgactie als de VOG verlopen/ingetrokken of afgewezen is (punt 22).
    private var vogBlockedNotice: some View {
        let verlopen = appState.buddyUser.vogStatus == .verlopen
        return HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.danger)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(verlopen ? "Je VOG is verlopen of ingetrokken" : "Je VOG is afgewezen")
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
                Text("Daarom kun je op dit moment geen hulpvragen aannemen. Vraag een nieuwe VOG aan om weer te kunnen helpen.")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(BCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.danger.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.danger.opacity(0.25), lineWidth: 1))
        .padding(.vertical, BCSpacing.xs)
    }

    /// De twee VOG-knoppen (uploaden of gratis aanvragen). De aanvraag-titel wordt
    /// "Nieuwe VOG" zodra een eerdere VOG verlopen/afgewezen is.
    @ViewBuilder
    private var vogRequestButtons: some View {
        BCPrimaryButton(title: "Ik heb al een VOG (uploaden)", icon: "doc.badge.arrow.up") {
            showVOGImporter = true
        }
        BCSecondaryButton(title: vogRequestTitle, icon: "shield.lefthalf.filled") {
            appState.buddyRequestsVOG()
        }
    }

    private var vogRequestTitle: String {
        (appState.buddyUser.vogStatus == .verlopen || appState.buddyUser.vogStatus == .afgewezen)
            ? "Nieuwe VOG gratis aanvragen" : "VOG gratis aanvragen"
    }

    private func handleVOGImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            appState.showToast(text: "Kon het bestand niet lezen.", icon: "exclamationmark.triangle.fill")
            return
        }
        let ext = url.pathExtension.isEmpty ? "pdf" : url.pathExtension.lowercased()
        let contentType: String
        switch ext {
        case "pdf":          contentType = "application/pdf"
        case "png":          contentType = "image/png"
        case "jpg", "jpeg":  contentType = "image/jpeg"
        case "heic":         contentType = "image/heic"
        default:             contentType = "application/octet-stream"
        }
        appState.buddyUploadsVOG(data: data, fileExtension: ext, contentType: contentType)
    }
}

// MARK: - Intake-videogesprek (wachtrij + video-stub)

private struct IntakeCallSheet: View {
    @Environment(AppState.self) private var appState

    private var isConnected: Bool { appState.myIntakeCall?.status == "in_progress" }

    var body: some View {
        Group {
            if isConnected, let call = appState.myIntakeCall {
                // Verbonden → echt videogesprek (Daily).
                IntakeVideoView(callId: call.id, isAdmin: false) {
                    appState.leaveIntakeCall()
                }
            } else {
                wachtrij
            }
        }
        .task {
            while !Task.isCancelled {
                await appState.refreshMyIntakeCall()
                // In de wachtrij sneller pollen, zodat de video bijna direct opent
                // zodra de medewerker opneemt; eenmaal verbonden rustiger.
                let interval: UInt64 = isConnected ? 5_000_000_000 : 2_000_000_000
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }

    private var wachtrij: some View {
        ZStack {
            BCColors.navy900.ignoresSafeArea()
            VStack(spacing: BCSpacing.lg) {
                Spacer()
                ProgressView().tint(.white).scaleEffect(1.4)
                Text("Je staat in de wachtrij")
                    .font(BCTypography.title2)
                    .foregroundStyle(.white)
                    .padding(.top, BCSpacing.sm)
                if appState.intakeQueuePosition > 0 {
                    Text("Plek \(appState.intakeQueuePosition) van \(appState.intakeQueueTotal)")
                        .font(BCTypography.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(appState.intakeEtaMinutes == 0
                         ? "Je bent bijna aan de beurt…"
                         : "Geschatte wachttijd: ~\(appState.intakeEtaMinutes) min")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Text("We verbinden je met een medewerker…")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button {
                    appState.leaveIntakeCall()
                } label: {
                    Text("Wachtrij verlaten")
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Capsule().fill(BCColors.danger))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.xl)
            }
        }
    }
}

// MARK: - Intakegesprek zelf inplannen

private struct IntakePlannerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // Standaard: morgen om 10:00, een logisch en vrij moment.
    @State private var date: Date = {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    Text("Kies een moment voor je intakegesprek. Een medewerker sluit dan op dat tijdstip met je aan voor een kort videogesprek.")
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    DatePicker("Datum en tijd", selection: $date, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(BCColors.accent)
                        .padding(BCSpacing.md)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                        .bcSoftShadow(.card)

                    BCPrimaryButton(title: "Afspraak bevestigen", icon: "checkmark",
                                    cornerRadius: BCRadius.md, height: 54) {
                        appState.scheduleIntakeCall(at: date)
                        dismiss()
                    }
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Gesprek inplannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.dateFormat = "d MMM"
    return f
}()

private let intakeDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.dateFormat = "EEEE d MMMM, HH:mm"
    return f
}()

#Preview {
    BuddyProfileView().environment(AppState())
}
