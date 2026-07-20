import Foundation
import Testing
@testable import LifeGrid

struct AppStateStoreTests {
    @MainActor @Test func loadPublishesPersistedState() async {
        var loaded = PersistedAppState.default
        loaded.preferences.playerName = "Michi"
        let repository = ScriptedAppStateRepository(loadedState: loaded)
        let store = AppStateStore(environment: environment(repository: repository))

        await store.load()

        #expect(store.state == loaded)
        #expect(store.persistenceErrorDescription == nil)
        #expect(store.hasLoaded)
    }

    @MainActor @Test func missingStateLoadsDefaults() async {
        let repository = ScriptedAppStateRepository(loadedState: .default)
        let store = AppStateStore(environment: environment(repository: repository))

        await store.load()

        #expect(store.state == .default)
    }

    @MainActor @Test func meaningfulMutationSavesImmediately() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))

        await store.applyFoundationMutation { state in
            state.preferences.playerName = "Michi"
        }

        #expect(await repository.savedSnapshots() == [store.state])
    }

    @MainActor @Test func saveFailureRetainsMutatedInMemoryState() async {
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(environment: environment(repository: repository))

        await store.applyFoundationMutation { state in
            state.preferences.playerName = "Retained"
        }

        #expect(store.state.preferences.playerName == "Retained")
        #expect(store.persistenceErrorDescription != nil)
    }

    @MainActor @Test func nextMutationRetriesAfterSaveFailure() async {
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(environment: environment(repository: repository))

        await store.applyFoundationMutation { $0.preferences.playerName = "First" }
        await store.applyFoundationMutation { $0.preferences.playerName = "Second" }
        let snapshots = await repository.savedSnapshots()

        #expect(snapshots.map(\.preferences.playerName) == ["First", "Second"])
        #expect(store.persistenceErrorDescription == nil)
    }

    @MainActor @Test func startGameCreatesAndSavesCompleteGame() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))
        let setup = GameSetup(
            totalPlayers: 3,
            startingLife: 25,
            opponentNames: ["Amanda", "Chris"]
        )

        await store.startGame(using: setup, rememberLastSetup: true)

        #expect(store.state.activeGame?.startingLife == 25)
        #expect(store.state.activeGame?.currentLife == 25)
        #expect(store.state.activeGame?.opponents.map(\.displayName) == ["Amanda", "Chris"])
        #expect(store.state.lastSetup == setup)
        #expect(await repository.savedSnapshots() == [store.state])
    }

    @MainActor @Test func startGameWithoutRememberingPreservesLastSetup() async {
        var initial = PersistedAppState.default
        initial.lastSetup = GameSetup(
            totalPlayers: 2,
            startingLife: 20,
            opponentNames: ["Remembered"]
        )
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        await store.startGame(
            using: GameSetup(
                totalPlayers: 3,
                startingLife: 60,
                opponentNames: ["New 1", "New 2"]
            ),
            rememberLastSetup: false
        )

        #expect(store.state.lastSetup == initial.lastSetup)
        #expect(!store.state.preferences.rememberLastSetup)
        #expect(store.state.activeGame?.startingLife == 60)
    }

    @MainActor @Test func defaultStartingLifeUpdatesOnlyRememberedLife() async {
        var initial = PersistedAppState.default
        initial.lastSetup = GameSetup(
            totalPlayers: 3,
            startingLife: 40,
            opponentNames: ["Amanda", "Chris"]
        )
        initial.activeGame = activeGame(startingLife: 40)
        let originalGame = initial.activeGame
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        await store.setDefaultStartingLife(25)

        #expect(store.state.preferences.defaultStartingLife == 25)
        #expect(store.state.lastSetup == GameSetup(
            totalPlayers: 3,
            startingLife: 25,
            opponentNames: ["Amanda", "Chris"]
        ))
        #expect(store.state.activeGame == originalGame)
        #expect(await repository.savedSnapshots() == [store.state])
    }

    @MainActor @Test func rememberPreferenceSavesWithoutClearingSetup() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))
        let originalSetup = store.state.lastSetup

        await store.setRememberLastSetup(false)

        #expect(!store.state.preferences.rememberLastSetup)
        #expect(store.state.lastSetup == originalSetup)
        #expect(await repository.savedSnapshots() == [store.state])
    }

    @MainActor @Test func replacementPersistsOneCompleteSnapshot() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        await store.startGame(
            using: GameSetup(
                totalPlayers: 2,
                startingLife: 60,
                opponentNames: ["Replacement"]
            ),
            rememberLastSetup: true
        )

        let snapshots = await repository.savedSnapshots()
        #expect(snapshots.count == 1)
        #expect(snapshots[0].activeGame?.startingLife == 60)
        #expect(snapshots[0].activeGame?.opponents.map(\.displayName) == ["Replacement"])
    }

    @MainActor @Test func failedGameSaveRetainsCompleteInMemoryGame() async {
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(environment: environment(repository: repository))

        await store.startGame(
            using: GameSetup(
                totalPlayers: 2,
                startingLife: 30,
                opponentNames: ["Amanda"]
            ),
            rememberLastSetup: true
        )

        #expect(store.state.activeGame?.startingLife == 30)
        #expect(store.state.activeGame?.opponents.map(\.displayName) == ["Amanda"])
        #expect(store.persistenceErrorDescription != nil)
    }

    @MainActor @Test func lifecycleSaveRetriesCurrentState() async {
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(environment: environment(repository: repository))

        await store.load()
        await store.setRememberLastSetup(false)
        await store.saveForLifecycle()

        #expect(await repository.savedSnapshots() == [store.state, store.state])
        #expect(store.persistenceErrorDescription == nil)
    }

    @MainActor @Test func lifecycleSaveBeforeInitialLoadDoesNotWrite() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))

        await store.saveForLifecycle()

        #expect(await repository.savedSnapshots().isEmpty)
        #expect(!store.hasLoaded)
    }

    @MainActor @Test func failedLoadBlocksWritesThatCouldReplaceUnreadableState() async {
        let repository = ScriptedAppStateRepository(shouldFailLoad: true)
        let store = AppStateStore(environment: environment(repository: repository))

        await store.load()
        await store.saveForLifecycle()
        await store.setRememberLastSetup(false)

        #expect(store.hasLoaded)
        #expect(store.persistenceErrorDescription != nil)
        #expect(store.state.preferences.rememberLastSetup)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func mutationRetriesTransientLoadBeforeChangingState() async {
        let repository = ScriptedAppStateRepository(failingLoadCalls: [1])
        let store = AppStateStore(environment: environment(repository: repository))

        await store.load()
        await store.setRememberLastSetup(false)

        #expect(!store.state.preferences.rememberLastSetup)
        #expect(store.persistenceErrorDescription == nil)
        #expect(await repository.savedSnapshots() == [store.state])
    }

    @MainActor @Test func overlappingMutationsPersistInIntentOrder() async {
        let repository = SuspendingFirstSaveAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))

        let firstMutation = Task { @MainActor in
            await store.applyFoundationMutation {
                $0.preferences.playerName = "First"
            }
        }
        await repository.waitUntilFirstSaveStarts()

        var secondMutationApplied = false
        let secondMutation = Task { @MainActor in
            await store.applyFoundationMutation {
                $0.preferences.playerName = "Second"
                secondMutationApplied = true
            }
        }
        while !secondMutationApplied {
            await Task.yield()
        }

        await repository.releaseFirstSave()
        await firstMutation.value
        await secondMutation.value

        let names = await repository.savedSnapshots().map(\.preferences.playerName)
        #expect(names == ["First", "Second"])
        #expect(store.state.preferences.playerName == "Second")
        #expect(store.persistenceErrorDescription == nil)
    }
}

private extension AppStateStoreTests {
    func environment(repository: any AppStateRepository) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            randomSource: ScriptedRandomSource([1]),
            clock: TestClock(date: .distantPast),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        )
    }

    func activeGame(startingLife: Int) -> ActiveGame {
        ActiveGame(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            startingLife: startingLife,
            currentLife: startingLife,
            opponents: [],
            ownCommanderAName: nil,
            ownCommanderBName: nil,
            ownCommanderTaxA: 0,
            ownCommanderTaxB: 0,
            currentMonarchPlayerID: nil,
            playerHasCitysBlessing: false,
            counterValues: [:],
            dayNightState: .notSet,
            pinnedCounterIDs: [],
            keepAwakeOverride: nil
        )
    }
}
