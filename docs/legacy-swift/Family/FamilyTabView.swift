import SwiftUI

struct FamilyTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection = 0
    @State private var showLinking = false

    var body: some View {
        TabView(selection: $selection) {
            // Fase36: de kaart is ook voor familie de voorpagina — buddies in
            // de buurt + de zorgkring van de naaste prominent onderaan.
            FamilyMapHomeView(tabSelection: $selection)
                .tag(0)
                .tabItem { Label("Kaart", systemImage: "map.fill") }
            FamilyDashboardView(showLinking: $showLinking)
                .tag(1)
                .tabItem { Label("Overzicht", systemImage: "house.fill") }
            ActivityTimelineView()
                .tag(2)
                .tabItem { Label("Activiteit", systemImage: "list.bullet.rectangle") }
            FamilyProfileView()
                .tag(3)
                .tabItem { Label("Profiel", systemImage: "person.crop.circle") }
        }
        .tint(BCColors.primary)
        .sheet(isPresented: $showLinking) {
            FamilyLinkingView()
        }
        // Punt 9: "hoe het werkt"-rondleiding, 1 keer na de registratie.
        .roleWalkthrough(.family)
    }
}

#Preview {
    FamilyTabView().environment(AppState())
}
