import SwiftUI

struct FamilyProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var notifyOnVisit = true
    @State private var notifyOnSOS = true
    @State private var notifyOnReview = false
    @State private var showLinking = false
    @State private var showPrivacy = false

    var body: some View {
        BCProfileScaffold(eyebrow: "Familielid") {
            // Avatar + naam
            VStack(spacing: BCSpacing.md) {
                BCProfileAvatar(initials: initials)
                VStack(spacing: 3) {
                    Text(appState.familyUser.fullName)
                        .font(BCTypography.title2)
                        .foregroundStyle(BCColors.textPrimary)
                    Text(appState.familyUser.relationship)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                    if let orgName = appState.organizationName {
                        BCOrganizationTag(name: orgName)
                            .padding(.top, 5)
                    }
                }
            }

            // Statistieken-band
            BCProfileStatRow(stats: [
                .init(value: "\(appState.familyLinkedElderly.count)", label: "Gekoppeld"),
                .init(value: appState.familyUser.relationship.isEmpty ? "—" : appState.familyUser.relationship,
                      label: "Relatie"),
            ])

            // Gekoppelde personen
            VStack(spacing: BCSpacing.sm) {
                BCProfileSectionLabel(title: "Gekoppelde personen")
                BCInsetCard {
                    ForEach(Array(appState.familyLinkedElderly.enumerated()), id: \.element.id) { index, elderly in
                        if index > 0 { BCHairline(leading: 60) }
                        HStack(spacing: BCSpacing.sm) {
                            ZStack {
                                Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 38, height: 38)
                                Text(String(elderly.firstName.prefix(1)))
                                    .font(BCTypography.bodyEmphasized)
                                    .foregroundStyle(BCColors.primary)
                            }
                            Text(elderly.fullName)
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textPrimary)
                            Spacer()
                            if index == appState.activeFamilyElderlyIndex {
                                BCStatusPill(label: "Actief", color: BCColors.success, showDot: true)
                            } else {
                                Button("Beheer") { appState.activeFamilyElderlyIndex = index }
                                    .font(BCTypography.captionEmphasized)
                                    .foregroundStyle(BCColors.primary)
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, BCSpacing.md)
                        .padding(.vertical, 12)
                    }
                }

                Button { showLinking = true } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Nog iemand koppelen")
                            .font(BCTypography.bodyEmphasized)
                    }
                    .foregroundStyle(BCColors.primary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(BCColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .stroke(BCColors.border, lineWidth: 1.5))
                    )
                }
                .buttonStyle(.plain)
            }

            // Meldingen
            VStack(spacing: 0) {
                BCProfileSectionLabel(title: "Meldingen")
                BCInsetCard {
                    BCProfileToggleRow(title: "Bij elk bezoek", isOn: $notifyOnVisit)
                    BCHairline(leading: 18)
                    BCProfileToggleRow(title: "Bij SOS-alarm", isOn: $notifyOnSOS)
                    BCHairline(leading: 18)
                    BCProfileToggleRow(title: "Maandelijkse rapportage", isOn: $notifyOnReview)
                    BCHairline(leading: 18)
                    BCProfileNavRow(title: "Privacy & gegevens") { showPrivacy = true }
                }
            }

            BCSignOutButton { Task { await appState.signOut() } }
                .padding(.top, BCSpacing.xs)
        }
        .sheet(isPresented: $showLinking) { FamilyLinkingView() }
        .sheet(isPresented: $showPrivacy) { PrivacyConsentSheet() }
    }

    private var initials: String {
        let f = appState.familyUser.firstName.first.map(String.init) ?? ""
        let l = appState.familyUser.lastName.first.map(String.init) ?? ""
        return f + l
    }
}

#Preview {
    FamilyProfileView().environment(AppState())
}
