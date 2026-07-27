import SwiftUI

struct BuddyTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            BuddyMapView()
                .tag(0)
                .tabItem { Label("Kaart", systemImage: "map.fill") }

            BuddyProfileView()
                .tag(1)
                .tabItem { Label("Profiel", systemImage: "person.crop.circle") }
                // Rood waarschuwingsbolletje zolang VOG/intake nog niet rond zijn
                // (buddy kan nog geen taken aannemen → actie nodig op het profiel).
                .badge(appState.buddyUser.canAcceptTasks ? nil : "!")
        }
        .tint(BCColors.primary)
        .fullScreenCover(isPresented: Binding(
            get: { !appState.isOnboardingComplete },
            set: { if !$0 { appState.isOnboardingComplete = true } }
        )) {
            BuddyOnboardingFlow()
        }
        // Punt 9: "hoe het werkt"-rondleiding, 1 keer na de registratie.
        .roleWalkthrough(.buddy)
        // Apart scherm zodra een aangenomen hulpvraag is ingetrokken.
        .fullScreenCover(isPresented: Binding(
            get: { appState.buddyCancelledNotice != nil },
            set: { if !$0 { appState.buddyCancelledNotice = nil } }
        )) {
            TaskCancelledScreen(elderlyName: appState.buddyCancelledNotice ?? "De hulpvrager") {
                appState.buddyCancelledNotice = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Bij terugkeren naar de app: check of de actieve taak nog loopt +
            // ververs de huidige locatie voor de 500m-meldingen + de VOG/intake-
            // status (mogelijk goedgekeurd terwijl de app dicht was).
            if phase == .active {
                Task { await appState.refreshBuddyActiveTask() }
                Task { await appState.refreshBuddyVerification() }
                appState.startBuddyLocationTrackingIfNeeded()
                BuddyLocationManager.shared.requestOneShot()
            }
        }
        // Realtime-ish: houd de VOG/intake-status bij terwijl de buddy de app
        // gebruikt. Zo verschijnt "goedgekeurd" vanzelf (zonder opnieuw inloggen)
        // en hoort de buddy het ook via een melding.
        .task {
            while !Task.isCancelled {
                await appState.refreshBuddyVerification()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // elke 30 s
            }
        }
    }
}

/// Vol scherm dat de buddy laat weten dat de aangenomen hulpvraag is ingetrokken.
private struct TaskCancelledScreen: View {
    let elderlyName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()
            BCPopIcon(systemName: "xmark.circle.fill", color: BCColors.danger, size: 72)
            VStack(spacing: BCSpacing.sm) {
                Text("Hulpvraag ingetrokken")
                    .font(BCTypography.title2)
                    .foregroundStyle(BCColors.textPrimary)
                Text("\(elderlyName) heeft de hulpvraag geannuleerd. Je hoeft niet meer langs te komen, bedankt voor je inzet!")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)
            }
            Spacer()
            BCPrimaryButton(title: "Begrepen", icon: "checkmark") { onDismiss() }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.bottom, BCSpacing.xl)
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

#Preview {
    BuddyTabView().environment(AppState())
}
