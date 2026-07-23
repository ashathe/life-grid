import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LocalLifeCard(store: store, game: game)
                        .id(game.id)

                    PinnedCountersView(store: store)

                    if store.state.preferences.commanderEnabled {
                        opponentsSection
                    }
                }
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

    private var opponentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Opponents")
                    .font(.headline)
                Spacer()
                if game.opponents.count < OpponentState.maximumCount {
                    Button("Add Opponent") {
                        Task { await store.addOpponent() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LifeGridPalette.accent)
                    .accessibilityHint("Adds a new opponent to this game")
                    .accessibilityIdentifier("add-opponent")
                }
            }

            ForEach(game.opponents.filter(\.isVisible)) { opponent in
                OpponentCard(store: store, opponentID: opponent.id)
            }
        }
    }
}
