import Foundation

enum StateMigrationError: Error, Equatable {
    case unsupportedSchema(Int)
}

struct StateMigration: Sendable {
    func migrate(
        _ data: Data,
        decoder: JSONDecoder = .lifeGrid
    ) throws -> PersistedAppState {
        let schemaVersion = try decoder.decode(SchemaEnvelope.self, from: data).schemaVersion

        switch schemaVersion {
        case 1:
            return try migrateVersionOne(data, decoder: decoder)
        case 2:
            return try migrateVersionTwo(data, decoder: decoder)
        case PersistedAppState.currentSchemaVersion:
            return try decoder.decode(PersistedAppState.self, from: data)
        default:
            throw StateMigrationError.unsupportedSchema(schemaVersion)
        }
    }

    private func migrateVersionOne(
        _ data: Data,
        decoder: JSONDecoder
    ) throws -> PersistedAppState {
        let legacy = try decoder.decode(PersistedAppStateV1.self, from: data)
        return PersistedAppState(
            schemaVersion: PersistedAppState.currentSchemaVersion,
            preferences: AppPreferences(
                playerName: legacy.preferences.playerName,
                commanderEnabled: legacy.preferences.commanderEnabled,
                ownPartnerCommanderEnabled: legacy.preferences.ownPartnerCommanderEnabled,
                commanderDamageChangesLife: legacy.preferences.commanderDamageChangesLife,
                keepScreenAwakeDuringGames: legacy.preferences.keepScreenAwakeDuringGames,
                hapticsEnabled: legacy.preferences.hapticsEnabled,
                soundEffectsEnabled: legacy.preferences.soundEffectsEnabled,
                appearance: legacy.preferences.appearance,
                appScale: legacy.preferences.appScale,
                defaultStartingLife: 40,
                rememberLastSetup: true
            ),
            lastSetup: legacy.lastSetup,
            activeGame: legacy.activeGame,
            customCounters: legacy.customCounters,
            savedDice: legacy.savedDice,
            diceHistory: legacy.diceHistory,
            lastDiceCountsBySides: [:]
        )
    }

    private func migrateVersionTwo(
        _ data: Data,
        decoder: JSONDecoder
    ) throws -> PersistedAppState {
        let legacy = try decoder.decode(PersistedAppStateV2.self, from: data)
        return PersistedAppState(
            schemaVersion: PersistedAppState.currentSchemaVersion,
            preferences: legacy.preferences,
            lastSetup: legacy.lastSetup,
            activeGame: legacy.activeGame,
            customCounters: legacy.customCounters,
            savedDice: legacy.savedDice,
            diceHistory: legacy.diceHistory,
            lastDiceCountsBySides: [:]
        )
    }
}

private struct SchemaEnvelope: Decodable {
    let schemaVersion: Int
}

private struct PersistedAppStateV1: Decodable {
    let schemaVersion: Int
    let preferences: AppPreferencesV1
    let lastSetup: GameSetup
    let activeGame: ActiveGame?
    let customCounters: [CustomCounterDefinition]
    let savedDice: [SavedDieDefinition]
    let diceHistory: [DiceRollEntry]
}

private struct AppPreferencesV1: Decodable {
    let playerName: String
    let commanderEnabled: Bool
    let ownPartnerCommanderEnabled: Bool
    let commanderDamageChangesLife: Bool
    let keepScreenAwakeDuringGames: Bool
    let hapticsEnabled: Bool
    let soundEffectsEnabled: Bool
    let appearance: AppearanceMode
    let appScale: AppScale
}

private struct PersistedAppStateV2: Decodable {
    let schemaVersion: Int
    let preferences: AppPreferences
    let lastSetup: GameSetup
    let activeGame: ActiveGame?
    let customCounters: [CustomCounterDefinition]
    let savedDice: [SavedDieDefinition]
    let diceHistory: [DiceRollEntry]
}
