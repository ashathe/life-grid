import SwiftUI

struct NewGameScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: AppStateStore
    let onGameStarted: () -> Void

    @State private var draft: NewGameDraft
    @State private var showsReplacementConfirmation = false

    init(
        store: AppStateStore,
        onGameStarted: @escaping () -> Void = {}
    ) {
        self.store = store
        self.onGameStarted = onGameStarted
        _draft = State(initialValue: NewGameDraft(state: store.state))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    playerCountCard
                    startingLifeCard
                    opponentNamesCard
                    rememberSetupCard
                    startButton
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .accessibilityIdentifier("new-game-screen")
            .toolbar {
                if store.state.activeGame != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .confirmationDialog(
                "Replace current game?",
                isPresented: $showsReplacementConfirmation,
                titleVisibility: .visible
            ) {
                Button("Start New Game", role: .destructive) {
                    startValidatedGame()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This creates a new game and replaces the autosaved active game.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("New Game")
                .font(.title2.bold())
            Text("Start with your preferred table setup")
                .font(.caption)
                .foregroundStyle(LifeGridPalette.secondaryText)
        }
    }

    private var playerCountCard: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Players")
                    .font(.headline)
                Text("Includes you")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            }
            Spacer()
            countButton(
                title: "−",
                identifier: "player-count-decrement",
                disabled: draft.totalPlayers == 2
            ) {
                draft.setTotalPlayers(draft.totalPlayers - 1)
            }
            Text("\(draft.totalPlayers)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 30)
                .accessibilityLabel("Total players")
                .accessibilityValue("\(draft.totalPlayers)")
                .accessibilityIdentifier("player-count")
            countButton(
                title: "+",
                identifier: "player-count-increment",
                disabled: draft.totalPlayers == 6
            ) {
                draft.setTotalPlayers(draft.totalPlayers + 1)
            }
        }
        .lifeGridCard()
    }

    private var startingLifeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Starting Life")
                .font(.headline)
            StartingLifePicker(input: $draft.startingLife)
        }
        .lifeGridCard()
    }

    private var opponentNamesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Opponent Names")
                    .font(.headline)
                Text("Optional · Blank names use Opponent 1, 2, 3…")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            }
            ForEach(draft.opponentNames.indices, id: \.self) { index in
                TextField(
                    "Opponent \(index + 1)",
                    text: $draft.opponentNames[index]
                )
                .foregroundStyle(LifeGridPalette.primaryText)
                .colorScheme(.dark)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    LifeGridPalette.field,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LifeGridPalette.border)
                }
                .accessibilityIdentifier("opponent-name-\(index + 1)")
            }
        }
        .lifeGridCard()
    }

    private var rememberSetupCard: some View {
        Toggle(isOn: $draft.rememberLastSetup) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Remember last setup")
                    .font(.headline)
                Text("Used by Quick Restart")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            }
        }
        .tint(LifeGridPalette.accent)
        .onChange(of: draft.rememberLastSetup) { _, value in
            Task { await store.setRememberLastSetup(value) }
        }
        .accessibilityIdentifier("remember-last-setup")
        .lifeGridCard()
    }

    private var startButton: some View {
        Button("Start Game", action: submit)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                draft.validatedSetup == nil
                    ? LifeGridPalette.control
                    : LifeGridPalette.accent,
                in: RoundedRectangle(cornerRadius: 9)
            )
            .foregroundStyle(LifeGridPalette.primaryText)
            .disabled(draft.validatedSetup == nil)
            .accessibilityIdentifier("start-game")
    }

    private func countButton(
        title: String,
        identifier: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .font(.headline)
            .frame(width: 44, height: 44)
            .background(
                disabled ? LifeGridPalette.field : LifeGridPalette.control,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundStyle(
                disabled ? LifeGridPalette.secondaryText : LifeGridPalette.primaryText
            )
            .disabled(disabled)
            .accessibilityIdentifier(identifier)
    }

    private func submit() {
        guard draft.validatedSetup != nil else { return }
        if store.state.activeGame == nil {
            startValidatedGame()
        } else {
            showsReplacementConfirmation = true
        }
    }

    private func startValidatedGame() {
        guard let setup = draft.validatedSetup else { return }
        Task {
            await store.startGame(
                using: setup,
                rememberLastSetup: draft.rememberLastSetup
            )
            onGameStarted()
        }
    }
}
