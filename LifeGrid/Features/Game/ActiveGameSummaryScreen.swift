import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LocalLifeCard(store: store, game: game)
                .id(game.id)
                .frame(maxWidth: 560)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Game") { showsNewGame = true }
                        .accessibilityIdentifier("new-game-toolbar")
                }
            }
            .accessibilityIdentifier("game-screen")
            .sheet(isPresented: $showsNewGame) {
                NewGameScreen(store: store) {
                    showsNewGame = false
                }
            }
        }
    }

    private var game: ActiveGame {
        guard let game = store.state.activeGame else {
            preconditionFailure("ActiveGameSummaryScreen requires an active game")
        }
        return game
    }
}
