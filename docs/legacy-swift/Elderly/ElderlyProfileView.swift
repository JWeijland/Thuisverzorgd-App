import SwiftUI
import CoreLocation
import PhotosUI

struct ElderlyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var notificationsEnabled = true
    @State private var reminderEnabled = true
    @State private var showEditSheet = false
    @State private var showPrivacy = false
    @State private var photoItem: PhotosPickerItem?
    @ObservedObject private var avatars = AvatarStore.shared

    var body: some View {
        BCProfileScaffold(eyebrow: "Mijn profiel") {
            // Avatar + naam
            VStack(spacing: BCSpacing.md) {
                BCProfileAvatar(image: avatars.image, initials: initials)
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
                                _ = try? await ProfileService().uploadElderlyAvatar(elderlyId: id, imageData: data)
                            }
                        }
                    }
                VStack(spacing: 3) {
                    Text(appState.elderlyUser.fullName)
                        .font(BCTypography.title2)
                        .foregroundStyle(BCColors.textPrimary)
                    if !headerSubtitle.isEmpty {
                        Text(headerSubtitle)
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    if let orgName = appState.organizationName {
                        BCOrganizationTag(name: orgName)
                            .padding(.top, 5)
                    }
                }
            }

            // Statistieken-band
            BCProfileStatRow(stats: [
                .init(value: appState.elderlyUser.displayAge.map { "\($0)" } ?? "—", label: "Leeftijd"),
                .init(value: "\(appState.favoriteBuddyNames.count)", label: "Buddies"),
                .init(value: "\(appState.taskHistory.count)", label: "Bezoeken"),
            ])

            // Koppelcode voor familie (live)
            if let linkCode = appState.myLinkingCode {
                VStack(spacing: 0) {
                    BCProfileSectionLabel(title: "Koppelcode voor familie")
                    BCInsetCard {
                        HStack(spacing: BCSpacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(linkCode)
                                    .font(BCTypography.title)
                                    .tracking(5)
                                    .foregroundStyle(BCColors.primary)
                                Text("Deel met familie om mee te kijken")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = linkCode
                                appState.showToast(text: "Code gekopieerd", icon: "doc.on.doc.fill")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(BCColors.primary)
                                    .frame(width: 42, height: 42)
                                    .background(RoundedRectangle(cornerRadius: BCRadius.sm, style: .continuous)
                                        .fill(BCColors.primary.opacity(0.10)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, BCSpacing.md)
                        .padding(.vertical, BCSpacing.md)
                    }
                }
            }

            // Gegevens — subtiel aanvulbaar
            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Gegevens", trailing: "Aanpassen") {
                    showEditSheet = true
                }
                BCInsetCard {
                    BCProfileInfoRow(icon: "phone.fill", label: "Telefoon",
                                     value: appState.elderlyUser.phoneNumber ?? "",
                                     visible: appState.elderlyUser.showsPhone) { showEditSheet = true }
                    BCHairline(leading: 48)
                    BCProfileInfoRow(icon: "house.fill", label: "Adres",
                                     value: appState.elderlyUser.address,
                                     visible: appState.elderlyUser.showsAddress) { showEditSheet = true }
                    BCHairline(leading: 48)
                    BCProfileInfoRow(icon: "calendar", label: "Geboortedatum",
                                     value: birthInfoText,
                                     visible: appState.elderlyUser.showsBirthDate) { showEditSheet = true }
                }
            }

            // Voorkeuren
            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Voorkeuren")
                BCInsetCard {
                    BCProfileToggleRow(
                        title: "Grote letters",
                        isOn: Binding(get: { appState.largeTextEnabled },
                                      set: { appState.largeTextEnabled = $0 }),
                        tint: BCColors.primary
                    )
                    BCHairline(leading: 18)
                    BCProfileToggleRow(
                        title: "Formeel aanspreken",
                        subtitle: appState.prefersFormal ? "Buddies zeggen u" : "Buddies zeggen jij",
                        isOn: Binding(get: { appState.prefersFormal },
                                      set: { appState.prefersFormal = $0 }),
                        tint: BCColors.primary
                    )
                }
            }

            // PRIVACY: de beoordelingen die buddies over de hulpvrager schrijven,
            // worden hier BEWUST NIET getoond. De hulpvrager mag deze nergens zien;
            // ze zijn alleen zichtbaar voor buddies op het hulpverzoek (de kaart).

            // Vertrouwen
            BCTrustStrip(items: [
                .init(icon: "checkmark.shield.fill", label: "AVG"),
                .init(icon: "checkmark.seal.fill", label: "VOG"),
                .init(icon: "star.fill", label: "Reviews"),
            ])

            // Meldingen
            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Meldingen")
                BCInsetCard {
                    BCProfileToggleRow(title: "Als een buddy reageert", isOn: $notificationsEnabled)
                    BCHairline(leading: 18)
                    BCProfileToggleRow(title: "Herinnering geplande hulp", isOn: $reminderEnabled)
                    BCHairline(leading: 18)
                    BCProfileNavRow(title: "Hoe werkt de app?", icon: "questionmark.circle") {
                        appState.replayWalkthrough(.elderly)
                    }
                    BCHairline(leading: 18)
                    BCProfileNavRow(title: "Privacy & gegevens") { showPrivacy = true }
                }
            }

            BCSignOutButton { Task { await appState.signOut() } }
                .padding(.top, BCSpacing.xs)
        }
        .task { await appState.loadMyLinkingCode() }
        .sheet(isPresented: $showEditSheet) { EditProfileSheet() }
        .sheet(isPresented: $showPrivacy) { PrivacyConsentSheet() }
    }

    private var initials: String {
        let first = appState.elderlyUser.firstName.first.map { String($0) } ?? ""
        let last = appState.elderlyUser.lastName.first.map { String($0) } ?? ""
        return "\(first)\(last)"
    }

    /// Toont de volledige geboortedatum als die bekend is ("12 maart 1948"),
    /// anders het losse geboortejaar, anders leeg.
    private var birthInfoText: String {
        if appState.elderlyUser.hasRealDateOfBirth {
            return BCBirthDate.display(appState.elderlyUser.dateOfBirth)
        }
        return appState.elderlyUser.birthYear.map(String.init) ?? ""
    }

    /// Adres onder de naam (leeftijd staat nu in de statistieken-band).
    private var headerSubtitle: String {
        appState.elderlyUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Edit sheet

struct EditProfileSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.largeTextEnabled) private var largeText
    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    /// Als true bewerkt het familielid de gegevens van de actieve gekoppelde
    /// oudere; anders bewerkt de oudere zijn/haar eigen gegevens.
    var editingFamilyElderly: Bool = false

    private var elderly: ElderlyUser {
        editingFamilyElderly ? appState.activeFamilyElderly : appState.elderlyUser
    }

    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var addressCoordinate: CLLocationCoordinate2D? = nil
    @State private var birthDate: Date? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    editField(icon: "phone.fill", label: "Telefoonnummer",
                              placeholder: "06 12 34 56 78", text: $phone,
                              keyboard: .phonePad)
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Label("Adres", systemImage: "house.fill")
                                .font(et.caption)
                                .foregroundStyle(BCColors.textSecondary)
                            AddressAutocompleteField(
                                placeholder: "Straat, huisnummer, plaats",
                                text: $address,
                                font: et.body,
                                onManualEdit: { addressCoordinate = nil }
                            ) { coord, formatted in
                                addressCoordinate = coord
                                address = formatted
                            }
                        }
                    }
                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.sm) {
                            Label("Geboortedatum", systemImage: "calendar")
                                .font(et.caption)
                                .foregroundStyle(BCColors.textSecondary)
                            BirthDateField(date: $birthDate, font: et.body)
                        }
                    }

                    // Punt 13: per gegeven regelen wat zichtbaar is voor anderen.
                    if !editingFamilyElderly {
                        BCCard {
                            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                                Label("Zichtbaar voor anderen", systemImage: "eye")
                                    .font(et.caption)
                                    .foregroundStyle(BCColors.textSecondary)
                                Text("Kies zelf wat er van u zichtbaar is. Uw postcode of adres wil niet iedereen delen.")
                                    .font(et.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                                visibilityRow(title: "Telefoon",
                                              isOn: Binding(get: { appState.elderlyUser.showsPhone },
                                                            set: { appState.setElderlyFieldVisibility(phone: $0) }))
                                BCHairline(leading: 0)
                                visibilityRow(title: "Adres",
                                              isOn: Binding(get: { appState.elderlyUser.showsAddress },
                                                            set: { appState.setElderlyFieldVisibility(address: $0) }))
                                BCHairline(leading: 0)
                                visibilityRow(title: "Geboortedatum",
                                              isOn: Binding(get: { appState.elderlyUser.showsBirthDate },
                                                            set: { appState.setElderlyFieldVisibility(birthDate: $0) }))
                            }
                        }
                    }
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Gegevens aanpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Opslaan") { save() }
                        .font(BCTypography.bodyEmphasized)
                        .tint(BCColors.primary)
                }
            }
        }
        .onAppear {
            phone = elderly.phoneNumber ?? ""
            address = elderly.address
            birthDate = elderly.hasRealDateOfBirth ? elderly.dateOfBirth : nil
        }
    }

    /// Eén regel in het zichtbaarheids-kaartje: veldnaam + oog-schakelaar.
    private func visibilityRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOn.wrappedValue ? BCColors.success : BCColors.textTertiary)
                Text(title).font(et.body).foregroundStyle(BCColors.textPrimary)
            }
        }
        .tint(BCColors.success)
    }

    @ViewBuilder
    private func editField(icon: String, label: String, placeholder: String,
                           text: Binding<String>, keyboard: UIKeyboardType = .default,
                           multiline: Bool = false) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                Label(label, systemImage: icon)
                    .font(et.caption)
                    .foregroundStyle(BCColors.textSecondary)
                if multiline {
                    TextField(placeholder, text: text, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                }
            }
        }
    }

    private func save() {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let editingFamily = editingFamilyElderly
        let elderlyId = editingFamily ? appState.activeFamilyElderly.id : appState.elderlyUser.id
        let isLive = appState.isLive
        // Volledige geboortedatum → exacte leeftijd; geboortejaar blijft in sync.
        let dob = birthDate
        let birthYear: Int? = dob.map { Calendar.current.component(.year, from: $0) }

        if editingFamily {
            var updated = appState.activeFamilyElderly
            updated.phoneNumber = phone.isEmpty ? nil : phone
            updated.address = trimmedAddress
            updated.birthYear = birthYear
            if let dob { updated.dateOfBirth = dob }
            appState.activeFamilyElderly = updated
        } else {
            appState.elderlyUser.phoneNumber = phone.isEmpty ? nil : phone
            appState.elderlyUser.address = trimmedAddress
            appState.elderlyUser.birthYear = birthYear
            if let dob { appState.elderlyUser.dateOfBirth = dob }
        }

        // Adres → coördinaat geocoderen en (live) opslaan, zodat een hulpvraag op
        // het juiste adres op de buddy-kaart verschijnt.
        let picked = addressCoordinate
        Task {
            // Voorkeur: exacte coördinaat uit de suggestielijst; anders geocoderen.
            let coord: CLLocationCoordinate2D?
            if let picked {
                coord = picked
            } else {
                coord = await AddressGeocoder.coordinate(for: trimmedAddress)
            }
            if let coord {
                await MainActor.run {
                    if editingFamily {
                        appState.activeFamilyElderly.coordinate = coord
                    } else {
                        appState.elderlyUser.coordinate = coord
                    }
                }
            }
            if isLive {
                try? await ProfileService().updateElderlyLocation(
                    elderlyId: elderlyId,
                    address: trimmedAddress,
                    latitude: coord?.latitude,
                    longitude: coord?.longitude
                )
                try? await ProfileService().updateElderlyDateOfBirth(
                    elderlyId: elderlyId, date: dob
                )
                try? await ProfileService().updateElderlyPhoneNumber(
                    elderlyId: elderlyId, phoneNumber: phone.isEmpty ? nil : phone
                )
            }
        }

        dismiss()
    }
}

#Preview {
    ElderlyProfileView().environment(AppState())
}
