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
}
