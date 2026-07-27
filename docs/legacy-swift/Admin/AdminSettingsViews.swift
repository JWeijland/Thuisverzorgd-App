//  AdminSettingsViews.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

enum AdminSettingsDestination: Hashable {
    case account, notifications, security
}

struct AdminSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var destination: AdminSettingsDestination?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                BCNavBar(title: "Instellingen", subtitle: "Admin configuratie")
                ScrollView {
                    VStack(spacing: BCSpacing.md) {
                        BCCard {
                            VStack(spacing: 0) {
                                AdminRow(icon: "person.crop.circle.fill", label: "Admin account") {
                                    destination = .account
                                }
                                Divider().padding(.leading, 56)
                                AdminRow(icon: "bell.fill", label: "Meldingen") {
                                    destination = .notifications
                                }
                                Divider().padding(.leading, 56)
                                AdminRow(icon: "lock.fill", label: "Beveiliging") {
                                    destination = .security
                                }
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)

                        Button {
                            Task { await appState.signOut() }
                        } label: {
                            HStack {
                                AppIcon(name: "tv-uitloggen", size: 18)
                                Text("Uitloggen")
                            }
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.danger)
                            .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                    }
                    .padding(.top, BCSpacing.md)
                    .padding(.bottom, BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $destination) { dest in
                switch dest {
                case .account:       AdminAccountView()
                case .notifications: AdminNotificationsView()
                case .security:      AdminSecurityView()
                }
            }
        }
    }
}

struct AdminAccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Admin account", subtitle: "Jouw gegevens") { dismiss() }
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        VStack(spacing: 0) {
                            InfoRow(label: "Naam", value: name.isEmpty ? "—" : name)
                            Divider()
                            InfoRow(label: "E-mail", value: appState.authService.currentUserEmail ?? "—")
                            Divider()
                            InfoRow(label: "Rol", value: "Beheerder")
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let id = appState.realUserId,
               let profile = try? await ProfileService().fetchProfile(userId: id) {
                name = "\(profile.firstName) \(profile.lastName)".trimmingCharacters(in: .whitespaces)
            }
        }
    }
}

struct AdminNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("admin.notif.applications") private var notifApplications = true
    @AppStorage("admin.notif.vog")          private var notifVOG = true
    @AppStorage("admin.notif.intake")       private var notifIntake = true
    @AppStorage("admin.notif.phone")        private var notifPhone = true

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Meldingen", subtitle: "Waarvoor wil je een seintje?") { dismiss() }
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        VStack(spacing: 0) {
                            Toggle("Nieuwe aanvragen", isOn: $notifApplications)
                            Divider()
                            Toggle("VOG-uploads", isOn: $notifVOG)
                            Divider()
                            Toggle("Intake-wachtrij", isOn: $notifIntake)
                            Divider()
                            Toggle("Telefonische verzoeken", isOn: $notifPhone)
                        }
                        .font(BCTypography.body)
                        .tint(BCColors.primary)
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    Text("Deze voorkeuren bepalen welke pushmeldingen je als beheerder ontvangt.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                        .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct AdminSecurityView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("admin.security.appLock") private var appLock = false
    @State private var sendingReset = false

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Beveiliging", subtitle: "Toegang & wachtwoord") { dismiss() }
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        Toggle("App vergrendelen met Face ID / code", isOn: $appLock)
                            .font(BCTypography.body)
                            .tint(BCColors.primary)
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    BCCard {
                        Button {
                            Task { await sendReset() }
                        } label: {
                            HStack(spacing: BCSpacing.md) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BCColors.primary)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Wachtwoord opnieuw instellen")
                                        .font(BCTypography.body)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text("We sturen een reset-link naar je e-mail")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textTertiary)
                                }
                                Spacer()
                                if sendingReset { ProgressView() }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(sendingReset || appState.authService.currentUserEmail == nil)
                    }
                    .padding(.horizontal, BCSpacing.lg)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func sendReset() async {
        guard let email = appState.authService.currentUserEmail else { return }
        sendingReset = true
        defer { sendingReset = false }
        do {
            try await appState.authService.sendPasswordReset(email: email)
            appState.showToast(text: "Reset-link verstuurd naar \(email)", icon: "envelope.fill")
        } catch {
            appState.showToast(text: "Versturen mislukt. Probeer later opnieuw.", icon: "exclamationmark.triangle.fill")
        }
    }
}
