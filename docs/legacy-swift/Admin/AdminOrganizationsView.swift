//  AdminOrganizationsView.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AdminOrganizationsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Takken", subtitle: "Partnerorganisaties")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    ForEach(appState.availableOrganizations) { org in
                        OrgManageCard(org: org)
                    }

                    Button {
                        appState.showToast(text: "Organisatie toevoegen, binnenkort beschikbaar", icon: "building.2.fill")
                    } label: {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Nieuwe organisatie toevoegen")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: BCRadius.lg)
                                .stroke(BCColors.primary, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

struct OrgManageCard: View {
    let org: Organization

    var body: some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BCColors.primary.opacity(0.08))
                        .frame(width: 48, height: 48)
                    Image(systemName: org.logoSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(org.name)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Text("Aangesloten vrijwilligersorganisatie / partner")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                    Label(org.isActive ? "Actief" : "Inactief", systemImage: org.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(BCTypography.caption)
                        .foregroundStyle(org.isActive ? BCColors.success : BCColors.danger)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(BCColors.textTertiary)
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}
