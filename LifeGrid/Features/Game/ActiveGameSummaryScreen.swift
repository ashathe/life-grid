import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false
    @State private var showsResetConfirmation = false

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
                    HStack(spacing: 4) {
                        Button("Reset") {
                            showsResetConfirmation = true
                        }
                        .accessibilityIdentifier("reset-toolbar")

                        Button("New Game") { showsNewGame = true }
                            .accessibilityIdentifier("new-game-toolbar")
                    }
                }
            }
            .accessibilityIdentifier("game-screen")
            .alert("Reset Game?", isPresented: $showsResetConfirmation) {
                Button("Reset", role: .destructive) {
                    Task { await store.resetGame() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Life, commander damage, counters, Day/Night, Monarch, and City's Blessing will reset. Player names, pins, and preferences are preserved.")
            }
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
                HStack(spacing: 8) {
                    Button {
                        Task { await store.removeLastOpponent() }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.opponents.isEmpty)

                    Text("\(game.opponents.count)")
                        .font(.headline.monospacedDigit())
                        .frame(minWidth: 24)

                    Button {
                        Task { await store.addOpponent() }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.opponents.count >= OpponentState.maximumCount)
                }
            }

            ForEach(game.opponents) { opponent in
                OpponentCard(store: store, opponentID: opponent.id)
            }
        }
    }
}
