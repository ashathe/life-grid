import Foundation
import Testing
@testable import LifeGrid

@MainActor
struct CounterStoreTests {
    private func storeWithGame(
        pinned: [CounterID] = [],
        counterValues: [CounterID: Int] = [:],
        customCounters: [CustomCounterDefinition] = []
    ) -> AppStateStore {
        var game = ActiveGame(
            id: UUID(),
            startedAt: Date(),
            startingLife: 40,
            currentLife: 40,
            opponents: [],
            ownCommanderAName: nil,
            ownCommanderBName: nil,
            ownCommanderTaxA: 0,
            ownCommanderTaxB: 0,
            currentMonarchPlayerID: nil,
            playerHasCitysBlessing: false,
            counterValues: counterValues,
            dayNightState: .notSet,
            pinnedCounterIDs: pinned,
            keepAwakeOverride: nil
        )
        var state = PersistedAppState.default
        state.activeGame = game
        state.customCounters = customCounters
        let repository = ScriptedAppStateRepository(loadedState: state)
        return AppStateStore(environment: environment(repository: repository))
    }

    private func environment(
        repository: ScriptedAppStateRepository
    ) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            randomSource: ScriptedRandomSource([1]),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient(),
            clock: TestClock(date: .distantPast),
            uiTestingCommanderDisabled: false
        )
    }

    // MARK: - Numeric counters

    @Test func incrementCounter() async {
        let store = storeWithGame()
        await store.load()

        await store.changeCounterValue(.builtIn(.poison), by: 1)

        #expect(store.state.activeGame?.counterValues[.builtIn(.poison)] == 1)
    }

    @Test func decrementCounter() async {
        let store = storeWithGame(counterValues: [.builtIn(.poison): 5])
        await store.load()

        await store.changeCounterValue(.builtIn(.poison), by: -2)

        #expect(store.state.activeGame?.counterValues[.builtIn(.poison)] == 3)
    }

    @Test func counterClampsAtZero() async {
        let store = storeWithGame(counterValues: [.builtIn(.energy): 3])
        await store.load()

        await store.changeCounterValue(.builtIn(.energy), by: -10)

        #expect(store.state.activeGame?.counterValues[.builtIn(.energy)] == 0)
    }

    @Test func setCounterExactValue() async {
        let store = storeWithGame()
        await store.load()

        await store.setCounterValue(.builtIn(.treasure), to: 7)

        #expect(store.state.activeGame?.counterValues[.builtIn(.treasure)] == 7)
    }

    @Test func setCounterRejectsNegative() async {
        let store = storeWithGame(counterValues: [.builtIn(.treasure): 5])
        await store.load()

        await store.setCounterValue(.builtIn(.treasure), to: -3)

        #expect(store.state.activeGame?.counterValues[.builtIn(.treasure)] == 5)
    }

    @Test func noCounterMutationWithoutActiveGame() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))
        await store.load()

        await store.changeCounterValue(.builtIn(.poison), by: 1)

        #expect(store.state.activeGame == nil)
    }

    // MARK: - Day/Night

    @Test func dayNightTransitions() async {
        let store = storeWithGame()
        await store.load()

        #expect(store.state.activeGame?.dayNightState == .notSet)

        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .day)

        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .night)

        await store.toggleDayNight()
        #expect(store.state.activeGame?.dayNightState == .day)
    }

    // MARK: - Pinning

    @Test func pinCounter() async {
        let store = storeWithGame()
        await store.load()

        await store.pinCounter(.builtIn(.poison))
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(.builtIn(.poison)) == true)
    }

    @Test func unpinCounter() async {
        let store = storeWithGame(pinned: [.builtIn(.poison), .builtIn(.energy)])
        await store.load()

        await store.unpinCounter(.builtIn(.poison))
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(.builtIn(.poison)) == false)
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(.builtIn(.energy)) == true)
    }

    @Test func maxFourPins() async {
        let store = storeWithGame(pinned: [
            .builtIn(.poison),
            .builtIn(.energy),
            .builtIn(.experience),
            .builtIn(.treasure),
        ])
        await store.load()

        await store.pinCounter(.builtIn(.storm))
        #expect(store.state.activeGame?.pinnedCounterIDs.count == 4)
        #expect(store.state.activeGame?.pinnedCounterIDs.contains(.builtIn(.storm)) == false)
    }

    @Test func noDuplicatePins() async {
        let store = storeWithGame(pinned: [.builtIn(.poison)])
        await store.load()

        await store.pinCounter(.builtIn(.poison))
        #expect(store.state.activeGame?.pinnedCounterIDs == [.builtIn(.poison)])
    }

    // MARK: - Custom counters

    @Test func addCustomCounter() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))
        await store.load()

        await store.addCustomCounter(name: "Loyalty")

        #expect(store.state.customCounters.count == 1)
        #expect(store.state.customCounters.first?.name == "Loyalty")
    }

    @Test func addCustomCounterRejectsBlank() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(environment: environment(repository: repository))
        await store.load()

        await store.addCustomCounter(name: "   ")

        #expect(store.state.customCounters.isEmpty)
    }

    @Test func renameCustomCounter() async {
        let counter = CustomCounterDefinition(
            id: UUID(),
            name: "Old",
            createdAt: Date()
        )
        let store = storeWithGame(customCounters: [counter])
        await store.load()

        await store.renameCustomCounter(counter.id, to: "New")

        #expect(store.state.customCounters.first?.name == "New")
    }

    @Test func deleteCustomCounter() async {
        let counter = CustomCounterDefinition(
            id: UUID(),
            name: "Temp",
            createdAt: Date()
        )
        let store = storeWithGame(customCounters: [counter])
        await store.load()

        await store.deleteCustomCounter(counter.id)

        #expect(store.state.customCounters.isEmpty)
    }

    @Test func deleteCustomCounterClearsValueAndPin() async {
        let counter = CustomCounterDefinition(
            id: UUID(),
            name: "Temp",
            createdAt: Date()
        )
        let store = storeWithGame(
            pinned: [.custom(counter.id)],
            counterValues: [.custom(counter.id): 5],
            customCounters: [counter]
        )
        await store.load()

        await store.deleteCustomCounter(counter.id)

        #expect(store.state.activeGame?.pinnedCounterIDs.contains(.custom(counter.id)) == false)
        #expect(store.state.activeGame?.counterValues[.custom(counter.id)] == nil)
    }

    // MARK: - Custom counter in game

    @Test func customCounterAdjustableInGame() async {
        let counter = CustomCounterDefinition(
            id: UUID(),
            name: "Custom",
            createdAt: Date()
        )
        let customID = CounterID.custom(counter.id)
        let store = storeWithGame(
            counterValues: [customID: 3],
            customCounters: [counter]
        )
        await store.load()

        await store.changeCounterValue(customID, by: 2)
        #expect(store.state.activeGame?.counterValues[customID] == 5)

        await store.changeCounterValue(customID, by: -1)
        #expect(store.state.activeGame?.counterValues[customID] == 4)
    }
}
