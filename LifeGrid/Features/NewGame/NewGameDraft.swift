import Foundation

struct NewGameDraft: Equatable, Sendable {
    var totalPlayers: Int
    var startingLife: StartingLifeInput
    var opponentNames: [String]
    var rememberLastSetup: Bool

    init(state: PersistedAppState) {
        rememberLastSetup = state.preferences.rememberLastSetup
        let setup = rememberLastSetup
            ? state.lastSetup
            : GameSetup(
                totalPlayers: 4,
                startingLife: state.preferences.defaultStartingLife,
                opponentNames: []
            )

        totalPlayers = min(max(setup.totalPlayers, 2), 6)
        startingLife = StartingLifeInput(value: setup.startingLife)
        opponentNames = Array(setup.opponentNames.prefix(totalPlayers - 1))
        while opponentNames.count < totalPlayers - 1 {
            opponentNames.append("")
        }
    }

    mutating func setTotalPlayers(_ value: Int) {
        totalPlayers = min(max(value, 2), 6)
        opponentNames = Array(opponentNames.prefix(totalPlayers - 1))
        while opponentNames.count < totalPlayers - 1 {
            opponentNames.append("")
        }
    }

    var validatedSetup: GameSetup? {
        guard let life = startingLife.value else { return nil }
        let normalizedNames = opponentNames.enumerated().map { index, name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Opponent \(index + 1)" : trimmed
        }
        return GameSetup(
            totalPlayers: totalPlayers,
            startingLife: life,
            opponentNames: normalizedNames
        )
    }
}
