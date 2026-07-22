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

    @MainActor @Test func localLifeChangesByOneAndPersistsCompleteSnapshots() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let decreased = await store.changeLocalLife(by: -1)
        let increased = await store.changeLocalLife(by: 1)

        #expect(decreased == ManualLifeChange(previousValue: 40, currentValue: 39))
        #expect(increased == ManualLifeChange(previousValue: 39, currentValue: 40))
        #expect(store.state.activeGame?.currentLife == 40)
        #expect(await repository.savedSnapshots() == [
            snapshot(from: initial, currentLife: 39),
            store.state,
        ])
    }

    @MainActor @Test func exactLocalLifeEntryAcceptsIntegerBounds() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let minimum = await store.setLocalLife(to: .min)
        let maximum = await store.setLocalLife(to: .max)

        #expect(minimum == ManualLifeChange(previousValue: 40, currentValue: .min))
        #expect(maximum == ManualLifeChange(previousValue: .min, currentValue: .max))
        #expect(store.state.activeGame?.currentLife == .max)
        #expect(await repository.savedSnapshots().count == 2)
    }

    @MainActor @Test func localLifeIntentsDoNothingWithoutAnActiveGame() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))

        let changed = await store.changeLocalLife(by: 1)
        let set = await store.setLocalLife(to: -10)
        await store.restoreLocalLife(to: 40)

        #expect(changed == nil)
        #expect(set == nil)
        #expect(store.state.activeGame == nil)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func localLifeChangeOverflowDoesNotMutateOrPersist() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: .max)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let result = await store.changeLocalLife(by: 1)

        #expect(result == nil)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func localCommanderTaxAdjustmentsClampAndDoNotChangeLife() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        await store.adjustLocalCommanderTax(.primary, by: 2)
        await store.adjustLocalCommanderTax(.partner, by: 2)
        await store.adjustLocalCommanderTax(.primary, by: -4)

        #expect(store.state.activeGame?.currentLife == 40)
        #expect(store.state.activeGame?.ownCommanderTaxA == 0)
        #expect(store.state.activeGame?.ownCommanderTaxB == 2)
        #expect(await repository.savedSnapshots().count == 3)
    }

    @MainActor @Test func commanderTaxDoesNothingWithoutAnActiveGameOrOnOverflow() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))

        await store.adjustLocalCommanderTax(.primary, by: 2)

        #expect(await repository.savedSnapshots().isEmpty)

        var initial = PersistedAppState.default
        var game = activeGame(startingLife: 40)
        game.ownCommanderTaxA = .max
        initial.activeGame = game
        let overflowRepository = ScriptedAppStateRepository()
        let overflowStore = AppStateStore(
            environment: environment(repository: overflowRepository),
            initialState: initial
        )

        await overflowStore.adjustLocalCommanderTax(.primary, by: 2)

        #expect(overflowStore.state == initial)
        #expect(await overflowRepository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func localLifeAndTaxIntentsRespectFailedLoadProtection() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository(shouldFailLoad: true)
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        await store.load()
        let changed = await store.changeLocalLife(by: 1)
        let set = await store.setLocalLife(to: 12)
        await store.restoreLocalLife(to: 20)
        await store.adjustLocalCommanderTax(.primary, by: 2)

        #expect(changed == nil)
        #expect(set == nil)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func localLifeAndTaxIntentsRetainInMemoryStateAfterSaveFailure() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40)
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1, 2, 3, 4])
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let changed = await store.changeLocalLife(by: -1)
        let set = await store.setLocalLife(to: -10)
        await store.restoreLocalLife(to: 40)
        await store.adjustLocalCommanderTax(.primary, by: 2)

        #expect(changed == ManualLifeChange(previousValue: 40, currentValue: 39))
        #expect(set == ManualLifeChange(previousValue: 39, currentValue: -10))
        #expect(store.state.activeGame?.currentLife == 40)
        #expect(store.state.activeGame?.ownCommanderTaxA == 2)
        #expect(store.persistenceErrorDescription != nil)
        #expect(await repository.savedSnapshots().count == 4)
    }

    @MainActor @Test func addOpponentAppendsDefaultAndStopsAtFive() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: [
            "Opponent 1", "Amanda", "Opponent 3", "Opponent 4",
        ])
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let added = await store.addOpponent()
        let blocked = await store.addOpponent()
        let snapshots = await repository.savedSnapshots()
        let addedOpponent = try! #require(store.state.activeGame?.opponents.last)

        #expect(added == .persisted(addedOpponent))
        #expect(addedOpponent.displayName == "Opponent 2")
        #expect(store.state.activeGame?.opponents.count == 5)
        #expect(blocked == .rejected)
        #expect(snapshots.count == 1)
        let initialIDs = try! #require(initial.activeGame?.opponents.map(\.id))
        #expect(snapshots[0].activeGame?.opponents.map(\.id) ==
                initialIDs + [addedOpponent.id])
        #expect(snapshots[0].activeGame?.opponents.last == addedOpponent)
    }

    @MainActor @Test func addOpponentReportsRetainedInMemoryWhenRepositorySaveFails() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(
            startingLife: 40,
            opponentNames: ["Opponent 1"]
        )
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let result = await store.addOpponent()
        let appended = try! #require(store.state.activeGame?.opponents.last)

        #expect(result == .retainedInMemory(appended))
        #expect(store.state.activeGame?.opponents.map(\.displayName) == [
            "Opponent 1", "Opponent 2",
        ])
        #expect(store.persistenceErrorDescription != nil)
        #expect(await repository.savedSnapshots().count == 1)
    }

    @MainActor @Test func primaryDamageAtomicallyLinksLifeInBothDirections() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        let id = try! #require(initial.activeGame?.opponents[0].id)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let up = await store.changePrimaryCommanderDamage(for: id, by: 3)
        let down = await store.changePrimaryCommanderDamage(for: id, by: -2)

        #expect(up == .persisted(CommanderDamageChange(
            previousDamage: 0,
            currentDamage: 3,
            previousLife: 40,
            currentLife: 37
        )))
        #expect(down == .persisted(CommanderDamageChange(
            previousDamage: 3,
            currentDamage: 1,
            previousLife: 37,
            currentLife: 39
        )))
        #expect(store.state.activeGame?.opponents[0].primaryCommanderDamage == 1)
        #expect(store.state.activeGame?.currentLife == 39)
        #expect(await repository.savedSnapshots().count == 2)
    }

    @MainActor @Test func exactPrimaryDamageEntryAppliesLinkedLifeDelta() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        let id = try! #require(initial.activeGame?.opponents[0].id)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let increased = await store.setPrimaryCommanderDamage(for: id, to: 8)
        let decreased = await store.setPrimaryCommanderDamage(for: id, to: 3)

        #expect(increased == .persisted(CommanderDamageChange(
            previousDamage: 0,
            currentDamage: 8,
            previousLife: 40,
            currentLife: 32
        )))
        #expect(decreased == .persisted(CommanderDamageChange(
            previousDamage: 8,
            currentDamage: 3,
            previousLife: 32,
            currentLife: 37
        )))
    }

    @MainActor @Test func primaryDamageDoesNotChangeLifeWhenLinkIsOff() async {
        var initial = PersistedAppState.default
        initial.preferences.commanderDamageChangesLife = false
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        let id = try! #require(initial.activeGame?.opponents[0].id)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let change = await store.changePrimaryCommanderDamage(for: id, by: 4)

        #expect(change == .persisted(CommanderDamageChange(
            previousDamage: 0,
            currentDamage: 4,
            previousLife: 40,
            currentLife: 40
        )))
        #expect(store.state.activeGame?.currentLife == 40)
        #expect(await repository.savedSnapshots().count == 1)
    }

    @MainActor @Test func primaryDamageNoOpsAtZeroAndForSameExactValue() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        let id = try! #require(initial.activeGame?.opponents[0].id)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let decremented = await store.changePrimaryCommanderDamage(for: id, by: -1)
        let zeroDelta = await store.changePrimaryCommanderDamage(for: id, by: 0)
        let unchanged = await store.setPrimaryCommanderDamage(for: id, to: 0)
        let negativeExact = await store.setPrimaryCommanderDamage(for: id, to: -1)

        #expect(decremented == .rejected)
        #expect(zeroDelta == .rejected)
        #expect(unchanged == .rejected)
        #expect(negativeExact == .rejected)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func repeatStyleDamageChangesAtThresholdAndZeroOnlyPersistRealMutations() async {
        var initial = PersistedAppState.default
        var game = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        game.opponents[0].primaryCommanderDamage = 20
        initial.activeGame = game
        let id = game.opponents[0].id
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let lethal = await store.changePrimaryCommanderDamage(for: id, by: 1)
        var zeroInitial = PersistedAppState.default
        zeroInitial.activeGame = activeGame(startingLife: 40, opponentNames: ["Bryn"])
        let zeroID = try! #require(zeroInitial.activeGame?.opponents[0].id)
        let zeroRepository = ScriptedAppStateRepository()
        let zeroStore = AppStateStore(
            environment: environment(repository: zeroRepository),
            initialState: zeroInitial
        )
        let zeroFloor = await zeroStore.changePrimaryCommanderDamage(
            for: zeroID,
            by: -1
        )

        #expect(lethal == .persisted(CommanderDamageChange(
            previousDamage: 20,
            currentDamage: 21,
            previousLife: 40,
            currentLife: 39
        )))
        #expect(zeroFloor == .rejected)
        #expect(zeroStore.state.activeGame?.currentLife == 40)
        #expect(await repository.savedSnapshots().count == 1)
        #expect(await zeroRepository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func primaryDamageDoesNothingForMissingOpponentOrGame() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let missing = await store.changePrimaryCommanderDamage(for: UUID(), by: 1)
        let noGameRepository = ScriptedAppStateRepository()
        let noGameStore = AppStateStore(environment: environment(repository: noGameRepository))
        let noGame = await noGameStore.setPrimaryCommanderDamage(for: UUID(), to: 1)

        #expect(missing == .rejected)
        #expect(noGame == .rejected)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
        #expect(await noGameRepository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func primaryDamageOverflowDoesNotMutateOrPersist() async {
        var initial = PersistedAppState.default
        var game = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        game.opponents[0].primaryCommanderDamage = .max
        initial.activeGame = game
        let id = game.opponents[0].id
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let change = await store.changePrimaryCommanderDamage(for: id, by: 1)

        #expect(change == .rejected)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func linkedLifeOverflowDoesNotMutateOrPersist() async {
        var initial = PersistedAppState.default
        var game = activeGame(startingLife: 40, opponentNames: ["Amanda"])
        game.currentLife = .min
        initial.activeGame = game
        let id = game.opponents[0].id
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let change = await store.changePrimaryCommanderDamage(for: id, by: 1)

        #expect(change == .rejected)
        #expect(store.state == initial)
        #expect(await repository.savedSnapshots().isEmpty)
    }

    @MainActor @Test func primaryDamageKeepsOpponentsIndependent() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda", "Bryn"])
        let firstID = try! #require(initial.activeGame?.opponents[0].id)
        let secondID = try! #require(initial.activeGame?.opponents[1].id)
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        _ = await store.changePrimaryCommanderDamage(for: firstID, by: 2)
        _ = await store.changePrimaryCommanderDamage(for: secondID, by: 3)

        #expect(store.state.activeGame?.opponents.map(\.primaryCommanderDamage) == [2, 3])
        #expect(store.state.activeGame?.currentLife == 35)
        #expect(await repository.savedSnapshots().count == 2)
    }

    @MainActor @Test func primaryDamageReportsRetainedInMemoryWhenRepositorySaveFails() async {
        var initial = PersistedAppState.default
        initial.activeGame = activeGame(
            startingLife: 40,
            opponentNames: ["Amanda"]
        )
        let opponentID = try! #require(initial.activeGame?.opponents[0].id)
        let repository = ScriptedAppStateRepository(failingSaveCalls: [1])
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: initial
        )

        let result = await store.changePrimaryCommanderDamage(
            for: opponentID,
            by: 2
        )

        #expect(result == .retainedInMemory(CommanderDamageChange(
            previousDamage: 0,
            currentDamage: 2,
            previousLife: 40,
            currentLife: 38
        )))
        #expect(store.state.activeGame?.opponents[0].primaryCommanderDamage == 2)
        #expect(store.state.activeGame?.currentLife == 38)
        #expect(store.persistenceErrorDescription != nil)
        #expect(await repository.savedSnapshots().count == 1)
    }

    @MainActor @Test func hapticsPlayOnlyWhenEnabledWithoutPersisting() async {
        let enabledHaptics = RecordingHapticsClient()
        let enabledRepository = ScriptedAppStateRepository()
        let enabledStore = AppStateStore(
            environment: environment(
                repository: enabledRepository,
                haptics: enabledHaptics
            )
        )

        await enabledStore.playHaptic(.adjustment)

        #expect(await enabledHaptics.events() == [.adjustment])
        #expect(await enabledRepository.savedSnapshots().isEmpty)

        var disabled = PersistedAppState.default
        disabled.preferences.hapticsEnabled = false
        let disabledHaptics = RecordingHapticsClient()
        let disabledRepository = ScriptedAppStateRepository()
        let disabledStore = AppStateStore(
            environment: environment(
                repository: disabledRepository,
                haptics: disabledHaptics
            ),
            initialState: disabled
        )

        await disabledStore.playHaptic(.adjustment)

        #expect(await disabledHaptics.events().isEmpty)
        #expect(await disabledRepository.savedSnapshots().isEmpty)
    }
}

private extension AppStateStoreTests {
    func environment(
        repository: any AppStateRepository,
        haptics: any HapticsClient = NoOpHapticsClient()
    ) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            randomSource: ScriptedRandomSource([1]),
            clock: TestClock(date: .distantPast),
            haptics: haptics,
            sound: NoOpSoundClient()
        )
    }

    func snapshot(
        from state: PersistedAppState,
        currentLife: Int
    ) -> PersistedAppState {
        var snapshot = state
        snapshot.activeGame?.currentLife = currentLife
        return snapshot
    }

    func activeGame(
        startingLife: Int,
        opponentNames: [String] = ["Opponent 1"]
    ) -> ActiveGame {
        let opponentIDs = opponentNames.indices.map { index in
            UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
        }
        return ActiveGameFactory.make(
            setup: GameSetup(
                totalPlayers: opponentNames.count + 1,
                startingLife: startingLife,
                opponentNames: opponentNames
            ),
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            opponentIDs: opponentIDs,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
