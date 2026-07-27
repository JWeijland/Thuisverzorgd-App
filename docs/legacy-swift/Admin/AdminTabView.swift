import SwiftUI

struct AdminTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            AdminCodesView()
                .tabItem { Label("Koppelcodes", image: "tv-koppelcodes") }

            AdminMembershipsView()
                .tabItem { Label("Aanvragen", image: "tv-hulpvragen") }

            AdminVOGView()
                .tabItem { Label("VOG's", image: "tv-vog") }

            AdminIntakeCallsView()
                .tabItem { Label("Intake", image: "tv-intake") }
                .badge(appState.waitingCalls.filter { $0.status == "waiting" }.count)

            AdminPhoneRequestView()
                .tabItem { Label("Telefonisch", image: "tv-telefoon") }

            AdminOrganizationsView()
                .tabItem { Label("Partners", image: "tv-organisaties") }

            AdminUsersView()
                .tabItem { Label("Gebruikers", image: "tv-gebruikers") }

            AdminPrizesView()
                .tabItem { Label("Prijzen", systemImage: "gift.fill") }

            AdminSettingsView()
                .tabItem { Label("Instellingen", image: "tv-instellingen") }
        }
        .tint(BCColors.primary)
        // Houd de wachtrij vers zodat de badge meebeweegt, ook buiten de tab.
        .task {
            while !Task.isCancelled {
                appState.adminRefreshWaitingCalls()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
}

#Preview {
    AdminTabView().environment(AppState())
}
