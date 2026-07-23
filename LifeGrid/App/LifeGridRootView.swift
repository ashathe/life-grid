import SwiftUI

struct LifeGridRootView: View {
    @Bindable var store: AppStateStore

    var body: some View {
        Group {
            if store.hasLoaded {
                tabShell
            } else {
                ProgressView("Loading Life Grid…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LifeGridPalette.background)
                    .foregroundStyle(LifeGridPalette.primaryText)
                    .accessibilityIdentifier("loading-state")
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if store.persistenceErrorDescription != nil {
                Text("Couldn’t access saved data. Life Grid will retry.")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LifeGridPalette.destructive)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("persistence-error")
            }
        }
    }

    private var tabShell: some View {
        TabView {
            gameDestination
                .tabItem { Label("Game", systemImage: "heart.fill") }

            CountersScreen(store: store)
                .tabItem { Label("Counters", systemImage: "number") }

            neutralDestination(
                title: "Dice",
                symbol: "die.face.6.fill"
            )
            .tabItem { Label("Dice", systemImage: "die.face.6.fill") }

            SettingsScreen(store: store)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(LifeGridPalette.accent)
        .background(LifeGridPalette.background.ignoresSafeArea())
        .accessibilityIdentifier("phase-two-tab-shell")
    }

    @ViewBuilder
    private var gameDestination: some View {
        if store.state.activeGame == nil {
            NewGameScreen(store: store)
                .id(store.state.preferences.defaultStartingLife)
        } else {
            ActiveGameSummaryScreen(store: store)
        }
    }

    private func neutralDestination(
        title: String,
        symbol: String
    ) -> some View {
        ContentUnavailableView(
            title,
            systemImage: symbol,
            description: Text("Available in a later approved phase.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LifeGridPalette.background)
        .foregroundStyle(LifeGridPalette.primaryText)
    }
}
