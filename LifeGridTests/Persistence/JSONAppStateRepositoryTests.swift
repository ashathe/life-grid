import Foundation
import Testing
@testable import LifeGrid

struct JSONAppStateRepositoryTests {
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
