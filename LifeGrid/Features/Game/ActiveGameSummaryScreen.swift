import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Active")
                            .font(.title2.bold())
                        Text("Your saved game is ready")
                            .font(.caption)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                    }

                    VStack(spacing: 12) {
                        summaryRow("Starting Life", value: "\(game.startingLife)")
                        Divider().overlay(LifeGridPalette.border)
                        summaryRow(
                            "Total Players",
                            value: "\(game.opponents.count + 1)"
                        )
                    }
                    .lifeGridCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Players").font(.headline)
                        playerRow(localPlayerDisplayName, detail: "You")
                        ForEach(game.opponents) { opponent in
                            playerRow(opponent.displayName, detail: "Opponent")
                        }
                    }
                    .lifeGridCard()

                    Text("Gameplay controls arrive in the next approved phase.")
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
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
            .accessibilityIdentifier("active-game-summary")
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

    private var localPlayerDisplayName: String {
        store.state.preferences.playerName.isEmpty
            ? "You"
            : store.state.preferences.playerName
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(LifeGridPalette.secondaryText)
            Spacer()
            Text(value).font(.headline.monospacedDigit())
        }
    }

    private func playerRow(_ name: String, detail: String) -> some View {
        HStack {
            Text(name)
                .lineLimit(1)
                .accessibilityLabel(name)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(LifeGridPalette.secondaryText)
        }
        .frame(minHeight: 44)
    }
}
