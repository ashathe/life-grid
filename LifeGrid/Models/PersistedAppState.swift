import Foundation

struct PersistedAppState: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 3

    var schemaVersion: Int
    var preferences: AppPreferences
    var lastSetup: GameSetup
    var activeGame: ActiveGame?
    var customCounters: [CustomCounterDefinition]
    var savedDice: [SavedDieDefinition]
    var diceHistory: [DiceRollEntry]
    var lastDiceCountsBySides: [Int: Int]

    static let `default` = PersistedAppState(
        schemaVersion: currentSchemaVersion,
        preferences: .default,
        lastSetup: GameSetup(totalPlayers: 4, startingLife: 40, opponentNames: []),
        activeGame: nil,
        customCounters: [],
        savedDice: [],
        diceHistory: [],
        lastDiceCountsBySides: [:]
    )
}

extension JSONEncoder {
    static var lifeGrid: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var lifeGrid: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
