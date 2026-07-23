import Testing
@testable import LifeGrid

@Suite(.serialized) @MainActor
struct CounterBehaviorTests {

    private func environment(
        repository: any AppStateRepository
    ) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            randomSource: ScriptedRandomSource([1]),
            clock: TestClock(date: .distantPast),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        )
    }

    private nonisolated func freshRepo() -> ScriptedAppStateRepository { ScriptedAppStateRepository() }

    @MainActor
    private func makeGameStore(repository: any AppStateRepository) async -> AppStateStore {
        let store = AppStateStore(environment: environment(repository: repository))
        await store.load()
        await store.startGame(using: GameSetup(totalPlayers: 2, startingLife: 40, opponentNames: ["O1"]), rememberLastSetup: false)
        return store
    }

    // MARK: - Numeric counter operations

    @Test func builtInCounterStartsAtZero() async {
        let store = await makeGameStore(repository: freshRepo())
        let value = store.state.activeGame?.counterValues[CounterID.builtIn(.poison)] ?? 99
        #expect(value == 0)
    }

    @Test func incrementAddsOne() async {
        let store = await makeGameStore(repository: freshRepo())
        let success = await store.adjustCounter(CounterID.builtIn(.energy), by: 1)
        #expect(success)
        #expect(store.state.activeGame?.counterValues[CounterID.builtIn(.energy)] == 1)
    }

    @Test func decrementRemovesOne() async {
        let store = await makeGameStore(repository: freshRepo())
        _ = await store.adjustCounter(CounterID.builtIn(.energy), by: 1)
        _ = await store.adjustCounter(CounterID.builtIn(.energy), by: 1)
        let success = await store.adjustCounter(CounterID.builtIn(.energy), by: -1)
        #expect(success)
        #expect(store.state.activeGame?.counterValues[CounterID.builtIn(.energy)] == 1)
    }

    @Test func counterClampsAtZero() async {
        let store = await makeGameStore(repository: freshRepo())
        let success = await store.adjustCounter(CounterID.builtIn(.poison), by: -1)
        #expect(!success)
        #expect(store.state.activeGame?.counterValues[CounterID.builtIn(.poison)] == 0)
    }

    @Test func setExactCounterValue() async {
        let store = await makeGameStore(repository: freshRepo())
        let success = await store.setCounterValue(CounterID.builtIn(.experience), to: 5)
        #expect(success)
        #expect(store.state.activeGame?.counterValues[CounterID.builtIn(.experience)] == 5)
    }

    @Test func setExactCounterRejectsNegative() async {
        let store = await makeGameStore(repository: freshRepo())
        let success = await store.setCounterValue(CounterID.builtIn(.storm), to: -1)
        #expect(!success)
    }

    @Test func setExactCounterNoOpsOnSameValue() async {
        let store = await makeGameStore(repository: freshRepo())
        let success = await store.setCounterValue(CounterID.builtIn(.treasure), to: 0)
        #expect(!success)
    }

    // MARK: - Day/Night

    @Test func dayNightTransitionsNotSetToDayToNightToDay() async {
        let store = await makeGameStore(repository: freshRepo())
        #expect(store.state.activeGame?.dayNightState == .notSet)
        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .day)
        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .night)
        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .day)
    }

    // MARK: - Pinning

    @Test func canPinUpToFourCounters() async {
        let store = await makeGameStore(repository: freshRepo())
        let ids: [CounterID] = [
            CounterID.builtIn(.poison),
            CounterID.builtIn(.energy),
            CounterID.builtIn(.experience),
            CounterID.builtIn(.treasure)
        ]
        for id in ids {
            let success = await store.pinCounter(id)
            #expect(success)
        }
        #expect(store.state.activeGame?.pinnedCounterIDs.count == 4)
        let fifth = await store.pinCounter(CounterID.builtIn(.radiation))
        #expect(!fifth)
        #expect(store.state.activeGame?.pinnedCounterIDs.count == 4)
    }

    @Test func unpinRemovesCounterFromPinned() async {
        let store = await makeGameStore(repository: freshRepo())
        _ = await store.pinCounter(CounterID.builtIn(.poison))
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(CounterID.builtIn(.poison)) == true)
        let success = await store.unpinCounter(CounterID.builtIn(.poison))
        #expect(success)
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(CounterID.builtIn(.poison)) == false)
    }

    @Test func unpinPreservesCounterValue() async {
        let store = await makeGameStore(repository: freshRepo())
        _ = await store.adjustCounter(CounterID.builtIn(.poison), by: 3)
        _ = await store.pinCounter(CounterID.builtIn(.poison))
        _ = await store.unpinCounter(CounterID.builtIn(.poison))
        #expect(store.state.activeGame?.counterValues[CounterID.builtIn(.poison)] == 3)
    }

    @Test func cannotDoublePin() async {
        let store = await makeGameStore(repository: freshRepo())
        _ = await store.pinCounter(CounterID.builtIn(.poison))
        let second = await store.pinCounter(CounterID.builtIn(.poison))
        #expect(!second)
        #expect(store.state.activeGame?.pinnedCounterIDs.count == 1)
    }

    // MARK: - Custom counters

    @Test func addCustomCounterCreatesDefinition() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        let created = await store.addCustomCounter(name: "Loyalty")
        #expect(created != nil)
        #expect(created?.name == "Loyalty")
        #expect(store.state.customCounters.count == 1)
    }

    @Test func addCustomCounterRejectsBlankName() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        let created = await store.addCustomCounter(name: "   ")
        #expect(created == nil)
        #expect(store.state.customCounters.isEmpty)
    }

    @Test func addCustomCounterRejectsDuplicateName() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        _ = await store.addCustomCounter(name: "Loyalty")
        let duplicate = await store.addCustomCounter(name: "loyalty")
        #expect(duplicate == nil)
        #expect(store.state.customCounters.count == 1)
    }

    @Test func addCustomCounterRejectsBuiltInName() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        let created = await store.addCustomCounter(name: "Poison")
        #expect(created == nil)
    }

    @Test func renameCustomCounterUpdatesName() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        let created = await store.addCustomCounter(name: "Old Name")
        let id = created!.id
        let success = await store.renameCustomCounter(id, to: "New Name")
        #expect(success)
        #expect(store.state.customCounters.first(where: { $0.id == id })?.name == "New Name")
    }

    @Test func renameCustomCounterRejectsDuplicateName() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        _ = await store.addCustomCounter(name: "Alpha")
        let beta = await store.addCustomCounter(name: "Beta")
        let success = await store.renameCustomCounter(beta!.id, to: "alpha")
        #expect(!success)
        #expect(store.state.customCounters.first(where: { $0.id == beta!.id })?.name == "Beta")
    }

    @Test func deleteCustomCounterRemovesDefinitionValueAndPin() async {
        let store = await makeGameStore(repository: freshRepo())
        let created = await store.addCustomCounter(name: "TestCounter")
        let counterID = CounterID.custom(created!.id)
        _ = await store.adjustCounter(counterID, by: 5)
        _ = await store.pinCounter(counterID)
        #expect(store.state.activeGame?.counterValues[counterID] == 5)
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(counterID) == true)
        let deleted = await store.deleteCustomCounter(created!.id)
        #expect(deleted)
        #expect(store.state.customCounters.isEmpty)
        #expect(store.state.activeGame?.counterValues[counterID] == nil)
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(counterID) == false)
    }

    // MARK: - All built-in counters

    @Test func allTenBuiltInCountersAreAvailable() {
        #expect(BuiltInCounterID.allCases.count == 10)
        let names = Set(BuiltInCounterID.allCases.map(\.displayName))
        #expect(names.contains("Poison"))
        #expect(names.contains("Energy"))
        #expect(names.contains("Experience"))
        #expect(names.contains("Treasure"))
        #expect(names.contains("Radiation"))
        #expect(names.contains("Storm"))
        #expect(names.contains("Charge"))
        #expect(names.contains("Doom"))
        #expect(names.contains("Tickets"))
        #expect(names.contains("Day / Night"))
    }

    // MARK: - No active game

    @Test func counterMutationsRejectWhenNoActiveGame() async {
        let store = AppStateStore(environment: environment(repository: freshRepo()))
        await store.load()
        let increment = await store.adjustCounter(CounterID.builtIn(.poison), by: 1)
        #expect(!increment)
        let exact = await store.setCounterValue(CounterID.builtIn(.poison), to: 5)
        #expect(!exact)
        let pin = await store.pinCounter(CounterID.builtIn(.poison))
        #expect(!pin)
    }

    // MARK: - Persistence

    @Test func counterValuePersistsAcrossSaveAndLoad() async throws {
        let repo = ScriptedAppStateRepository()
        let store = await makeGameStore(repository: repo)
        _ = await store.adjustCounter(CounterID.builtIn(.poison), by: 3)
        await store.saveForLifecycle()
        let snapshots = await repo.savedSnapshots()
        #expect(snapshots.count >= 1)
        #expect(snapshots.last?.activeGame?.counterValues[CounterID.builtIn(.poison)] == 3)
    }
}
