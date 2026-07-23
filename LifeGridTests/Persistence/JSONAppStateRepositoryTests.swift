import Foundation
import Testing
@testable import LifeGrid

@Suite(.serialized) struct JSONAppStateRepositoryTests {
    @Test func missingFileLoadsApprovedDefaults() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONAppStateRepository(directoryURL: directory)

        let loaded = try await repository.load()

        #expect(loaded == .default)
    }

    @Test func savedCompleteStateReloadsExactly() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONAppStateRepository(directoryURL: directory)
        let state = completeState

        try await repository.save(state)
        let loaded = try await repository.load()
        let siblings = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )

        #expect(loaded == state)
        #expect(siblings.map(\.lastPathComponent) == [JSONAppStateRepository.fileName])
    }

    @Test func versionOneSnapshotMigratesWithoutLosingState() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONAppStateRepository(directoryURL: directory)
        let current = completeState
        let legacy = LegacyPersistedAppStateV1(
            schemaVersion: 1,
            preferences: LegacyAppPreferencesV1(
                playerName: current.preferences.playerName,
                commanderEnabled: current.preferences.commanderEnabled,
                ownPartnerCommanderEnabled: current.preferences.ownPartnerCommanderEnabled,
                commanderDamageChangesLife: current.preferences.commanderDamageChangesLife,
                keepScreenAwakeDuringGames: current.preferences.keepScreenAwakeDuringGames,
                hapticsEnabled: current.preferences.hapticsEnabled,
                soundEffectsEnabled: current.preferences.soundEffectsEnabled,
                appearance: current.preferences.appearance,
                appScale: current.preferences.appScale
            ),
            lastSetup: current.lastSetup,
            activeGame: current.activeGame,
            customCounters: current.customCounters,
            savedDice: current.savedDice,
            diceHistory: current.diceHistory
        )
        let snapshotURL = directory.appendingPathComponent(JSONAppStateRepository.fileName)
        try JSONEncoder.lifeGrid.encode(legacy).write(to: snapshotURL)

        let loaded = try await repository.load()

        #expect(loaded.schemaVersion == 2)
        #expect(loaded.preferences.playerName == legacy.preferences.playerName)
        #expect(loaded.preferences.defaultStartingLife == 40)
        #expect(loaded.preferences.rememberLastSetup)
        #expect(loaded.lastSetup == legacy.lastSetup)
        #expect(loaded.activeGame == legacy.activeGame)
        #expect(loaded.customCounters == legacy.customCounters)
        #expect(loaded.savedDice == legacy.savedDice)
        #expect(loaded.diceHistory == legacy.diceHistory)
    }

    @Test func unsupportedFutureSchemaThrowsWithoutReplacingFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONAppStateRepository(directoryURL: directory)
        let snapshotURL = directory.appendingPathComponent(JSONAppStateRepository.fileName)
        let original = Data(#"{"schemaVersion":999}"#.utf8)
        try original.write(to: snapshotURL)

        do {
            _ = try await repository.load()
            Issue.record("Expected an unsupported schema error")
        } catch let error as StateMigrationError {
            #expect(error == .unsupportedSchema(999))
        }

        #expect(try Data(contentsOf: snapshotURL) == original)
    }

    @Test func corruptJSONThrowsWithoutDeletingFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONAppStateRepository(directoryURL: directory)
        let snapshotURL = directory.appendingPathComponent(JSONAppStateRepository.fileName)
        let original = Data("not-json".utf8)
        try original.write(to: snapshotURL)

        do {
            _ = try await repository.load()
            Issue.record("Expected corrupt JSON to throw")
        } catch {
            #expect(!(error is StateMigrationError))
        }

        #expect(FileManager.default.fileExists(atPath: snapshotURL.path))
        #expect(try Data(contentsOf: snapshotURL) == original)
    }
}

private struct LegacyPersistedAppStateV1: Codable {
    var schemaVersion: Int
    var preferences: LegacyAppPreferencesV1
    var lastSetup: GameSetup
    var activeGame: ActiveGame?
    var customCounters: [CustomCounterDefinition]
    var savedDice: [SavedDieDefinition]
    var diceHistory: [DiceRollEntry]
}

private struct LegacyAppPreferencesV1: Codable {
    var playerName: String
    var commanderEnabled: Bool
    var ownPartnerCommanderEnabled: Bool
    var commanderDamageChangesLife: Bool
    var keepScreenAwakeDuringGames: Bool
    var hapticsEnabled: Bool
    var soundEffectsEnabled: Bool
    var appearance: AppearanceMode
    var appScale: AppScale
}

private extension JSONAppStateRepositoryTests {
    func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeGridTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    var completeState: PersistedAppState {
        var state = PersistedAppState.default
        state.preferences.playerName = "Michi"
        let customCounterID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        state.customCounters = [
            CustomCounterDefinition(
                id: customCounterID,
                name: "Quest",
                createdAt: Date(timeIntervalSince1970: 1_699_999_000)
            )
        ]
        state.activeGame = ActiveGame(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            startingLife: 40,
            currentLife: 34,
            opponents: [
                OpponentState(
                    id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                    displayName: "Amanda",
                    isVisible: true,
                    primaryCommanderName: "Atraxa",
                    primaryCommanderDamage: 5,
                    partner: nil,
                    hasCitysBlessing: true
                )
            ],
            ownCommanderAName: "Muldrotha",
            ownCommanderBName: nil,
            ownCommanderTaxA: 2,
            ownCommanderTaxB: 0,
            currentMonarchPlayerID: .local,
            playerHasCitysBlessing: false,
            counterValues: [
                .builtIn(.poison): 3,
                .custom(customCounterID): 7
            ],
            dayNightState: .night,
            pinnedCounterIDs: [.custom(customCounterID)],
            keepAwakeOverride: true
        )
        state.savedDice = [
            SavedDieDefinition(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                sides: 37
            )
        ]
        state.diceHistory = [
            DiceRollEntry(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                sides: 6,
                diceCount: 3,
                individualResults: [4, 1, 3],
                total: 8
            )
        ]
        return state
    }
}
