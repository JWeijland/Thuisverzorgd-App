import SwiftUI

// Replaced by RootView. Kept here as a thin alias so any stray references compile.
struct ContentView: View {
    var body: some View { RootView() }
}

#Preview {
    ContentView().environment(AppState())
}
