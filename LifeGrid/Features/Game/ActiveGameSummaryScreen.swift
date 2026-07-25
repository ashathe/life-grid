import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false
    @State private var showsResetConfirmation = false
    @State private var quickRollLabel: String?
    @State private var quickRollValue: String?
    @State private var quickRollRevision = 0
    @State private var quickRollDismissTask: Task<Void, Never>?
    @State private var containerWidth: CGFloat = 0
    @State private var isLandscapeLocked = false

    private var isLandscape: Bool { containerWidth > 560 }

    private var singleColumnLayout: some View {
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
        .overlay {
            if let label = quickRollLabel, let value = quickRollValue {
                quickRollOverlay(label: label, value: value)
            }
        }
    }

    private var twoColumnLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    LocalLifeCard(store: store, game: game)
                        .id(game.id)
                    PinnedCountersView(store: store)
                }
                .padding(.leading, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .background(LifeGridPalette.background)

            if store.state.preferences.commanderEnabled {
                ScrollView {
                    opponentsSection
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .background(LifeGridPalette.background)
            }
        }
        .background(LifeGridPalette.background.ignoresSafeArea())
        .overlay {
            if let label = quickRollLabel, let value = quickRollValue {
                quickRollOverlay(label: label, value: value)
            }
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Group {
                    if isLandscape {
                        twoColumnLayout
                    } else {
                        singleColumnLayout
                    }
                }
                .onAppear { containerWidth = geometry.size.width }
                .onChange(of: geometry.size.width) { _, w in containerWidth = w }
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(quickRollDice, id: \.sides) { die in
                            Button {
                                Task { await quickRoll(sides: die.sides, label: die.label) }
                            } label: { Text(die.label) }
                        }
                    } label: {
                        Image("BadgeIcon")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .accessibilityLabel("Quick dice roll")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isLandscapeLocked ? OrientationLock.reset() : OrientationLock.landscape()
                        isLandscapeLocked.toggle()
                    } label: {
                        Image(systemName: isLandscapeLocked ? "lock.rotation" : "rotate.3d")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isLandscapeLocked ? "Unlock orientation" : "Rotate to landscape")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Button("Reset") { showsResetConfirmation = true }
                            .accessibilityIdentifier("reset-toolbar")
                        Button("New Game") { showsNewGame = true }
                            .accessibilityIdentifier("new-game-toolbar")
                    }
                }
            }
            .accessibilityIdentifier("game-screen")
            .alert("Reset Game?", isPresented: $showsResetConfirmation) {
                Button("Reset", role: .destructive) { Task { await store.resetGame() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Life, commander damage, counters, Day/Night, Monarch, and City's Blessing will reset. Player names, pins, and preferences are preserved.")
            }
            .sheet(isPresented: $showsNewGame) {
                NewGameScreen(store: store) { showsNewGame = false }
            }
            .onDisappear {
                quickRollDismissTask?.cancel()
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
                Text("Opponents").font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button { Task { await store.removeLastOpponent() } } label: {
                        Image(systemName: "minus.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.opponents.isEmpty)
                    Text("\(game.opponents.count)")
                        .font(.headline.monospacedDigit()).frame(minWidth: 24)
                    Button { Task { await store.addOpponent() } } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.opponents.count >= OpponentState.maximumCount)
                }
            }
            ForEach(game.opponents.filter(\.isVisible)) { opponent in
                OpponentCard(store: store, opponentID: opponent.id)
            }

            if !game.opponents.filter({ !$0.isVisible }).isEmpty {
                outOfGameSection
            }
        }
    }

    private var outOfGameSection: some View {
        let hidden = game.opponents.filter { !$0.isVisible }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Out of Game · \(hidden.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(LifeGridPalette.secondaryText)
                Spacer()
            }
            ForEach(hidden) { opponent in
                HStack {
                    Text(OpponentCard.displayName(for: opponent))
                        .font(.caption)
                        .foregroundStyle(LifeGridPalette.secondaryText)
                    Spacer()
                    Button("Restore") {
                        Task { await store.restoreOpponent(opponent.id) }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(LifeGridPalette.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(LifeGridPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(LifeGridPalette.border) }
    }

    private let quickRollDice: [(label: String, sides: Int)] = [
        ("Coin", 2), ("d4", 4), ("d6", 6), ("d8", 8), ("d10", 10), ("d12", 12), ("d20", 20)
    ]

    private func quickRoll(sides: Int, label: String) async {
        guard let entry = await store.rollDice(sides: sides, count: 1) else { return }
        await store.playHaptic(.adjustment)
        let result = label == "Coin" ? (entry.total == 1 ? "Heads" : "Tails") : "\(entry.total)"
        quickRollLabel = label
        quickRollValue = result
        quickRollRevision += 1
        let revision = quickRollRevision
        quickRollDismissTask?.cancel()
        quickRollDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            guard revision == quickRollRevision else { return }
            quickRollLabel = nil
            quickRollValue = nil
        }
    }

    @ViewBuilder
    private func quickRollOverlay(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(LifeGridPalette.secondaryText)
            Text(value).font(.system(size: 64, weight: .bold).monospacedDigit()).foregroundStyle(LifeGridPalette.accent)
        }
        .padding(32)
        .background(LifeGridPalette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(LifeGridPalette.accent, lineWidth: 2) }
        .shadow(color: .black.opacity(0.5), radius: 20)
        .transition(.opacity.combined(with: .scale(0.8)))
        .animation(.spring(response: 0.3), value: quickRollLabel)
    }
}

private enum OrientationLock {
    static func landscape() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    }

    static func reset() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
    }
}
