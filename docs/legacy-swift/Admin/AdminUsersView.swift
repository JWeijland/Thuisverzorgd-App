//  AdminUsersView.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AdminUsersView: View {
    @Environment(AppState.self) private var appState
    @State private var search = ""

    private var filtered: [DBProfile] {
        let base = appState.allUsers
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter {
            "\($0.firstName) \($0.lastName)".lowercased().contains(q)
            || $0.role.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Gebruikers", subtitle: "Rollen beheren")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    if !appState.isLive {
                        BCCard {
                            Text("Gebruikersbeheer werkt alleen wanneer je echt bent ingelogd (live-modus).")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else if appState.allUsers.isEmpty {
                        BCEmptyState(icon: "person.2", title: "Geen gebruikers",
                                     message: "Er zijn nog geen profielen om te beheren.")
                            .padding(.top, BCSpacing.xl)
                    } else {
                        ForEach(filtered) { user in
                            userCard(user)
                        }
                    }
                    Spacer().frame(height: BCSpacing.xl)
                }
                .padding(.top, BCSpacing.md)
            }
            .searchable(text: $search, prompt: "Zoek op naam of rol")
        }
        .background(BCColors.background.ignoresSafeArea())
        .onAppear { appState.adminLoadUsers() }
        .refreshable { appState.adminLoadUsers() }
    }

    private func userCard(_ user: DBProfile) -> some View {
        let role = UserRole(rawValue: user.role)
        return BCCard {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 44, height: 44)
                    Image(systemName: "person.fill").foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces).isEmpty
                         ? "(naam onbekend)" : "\(user.firstName) \(user.lastName)")
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    if let phone = user.phoneNumber, !phone.isEmpty {
                        Text(phone).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                    }
                }
                Spacer()
                Menu {
                    ForEach(UserRole.allCases) { r in
                        Button {
                            appState.adminSetUserRole(userId: user.id, role: r)
                        } label: {
                            if role == r { Label(r.displayName, systemImage: "checkmark") }
                            else { Text(r.displayName) }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(role?.displayName ?? user.role)
                            .font(BCTypography.captionEmphasized)
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(role == .admin ? BCColors.danger : BCColors.primary)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill((role == .admin ? BCColors.danger : BCColors.primary).opacity(0.10)))
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}
