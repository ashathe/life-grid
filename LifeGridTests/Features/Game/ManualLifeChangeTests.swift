import Foundation
import Testing
@testable import LifeGrid

@Suite(.serialized) struct ManualLifeChangeTests {
    @Test func equalityIncludesNegativeCurrentValue() {
        let change = ManualLifeChange(previousValue: 40, currentValue: -1)

        #expect(change == ManualLifeChange(previousValue: 40, currentValue: -1))
        #expect(change != ManualLifeChange(previousValue: 40, currentValue: 0))
        #expect(change != ManualLifeChange(previousValue: 39, currentValue: -1))
    }

    @Test func replacementUndoOperationHasNewIdentityAndRestoreValue() {
        let firstOperationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!
        let replacementOperationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000002"
        )!
        let first = LocalLifeUndoState(
            restoreValue: 40,
            operationID: firstOperationID
        )
        let replacement = LocalLifeUndoState(
            restoreValue: -7,
            operationID: replacementOperationID
        )

        #expect(replacement.operationID != first.operationID)
        #expect(replacement.restoreValue == -7)
        #expect(replacement != first)
    }

    @Test func blankTrimmedPlayerNameDisplaysYou() {
        #expect(LocalLifeCard.displayName(for: " \n ") == "You")
    }

    @Test func nonemptyPlayerNameDisplaysTrimmedValue() {
        #expect(
            LocalLifeCard.displayName(for: "  Michi\n") == "Michi"
        )
    }

    @MainActor
    @Test func localLifeCardHoldPersistsMultipleChangesWithOneUndo() async {
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: stateWithActiveGame(startingLife: 40)
        )
        let interaction = LocalLifeInteractionController()

        await interaction.applyManualDelta(1, to: store)
        await interaction.applyManualDelta(1, to: store)
        await interaction.applyManualDelta(1, to: store)

        #expect(store.state.activeGame?.currentLife == 43)
        #expect(
            await repository.savedSnapshots()
                .compactMap(\.activeGame?.currentLife) == [41, 42, 43]
        )
        #expect(interaction.undoState == nil)

        interaction.finishHeldOperation()

        #expect(interaction.undoState?.restoreValue == 40)
        #expect(await interaction.undo(in: store))
        #expect(store.state.activeGame?.currentLife == 40)
        #expect(interaction.undoState == nil)
        #expect(await !interaction.undo(in: store))
        #expect(
            await repository.savedSnapshots()
                .compactMap(\.activeGame?.currentLife) == [41, 42, 43, 40]
        )
    }

    @MainActor
    @Test func localLifeCardUndoExpiresAfterExactlyFourSeconds() async {
        let sleeper = ControlledUndoSleeper()
        let repository = ScriptedAppStateRepository()
        let store = AppStateStore(
            environment: environment(repository: repository),
            initialState: stateWithActiveGame(startingLife: 40)
        )
        let interaction = LocalLifeInteractionController(
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        await interaction.applyManualDelta(1, to: store)
        interaction.finishHeldOperation()

        #expect(interaction.undoState?.restoreValue == 40)
        #expect(await sleeper.waitForSleep() == .seconds(4))

        await sleeper.resumeNext()
        for _ in 0..<100 where interaction.undoState != nil {
            await Task.yield()
        }

        #expect(interaction.undoState == nil)
        #expect(store.state.activeGame?.currentLife == 41)
        #expect(
            await repository.savedSnapshots()
                .compactMap(\.activeGame?.currentLife) == [41]
        )
    }
}

private extension ManualLifeChangeTests {
    func environment(repository: any AppStateRepository) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            randomSource: ScriptedRandomSource([1]),
            clock: TestClock(date: .distantPast),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        )
    }

    func stateWithActiveGame(startingLife: Int) -> PersistedAppState {
        var state = PersistedAppState.default
        state.activeGame = ActiveGame(
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
        return state
    }
}

private actor ControlledUndoSleeper {
    private var suspendedSleeps: [CheckedContinuation<Void, Never>] = []
    private var pendingDurations: [Duration] = []
    private var durationWaiters: [CheckedContinuation<Duration, Never>] = []

    func sleep(for duration: Duration) async {
        if let waiter = durationWaiters.first {
            durationWaiters.removeFirst()
            waiter.resume(returning: duration)
        } else {
            pendingDurations.append(duration)
        }

        await withCheckedContinuation { continuation in
            suspendedSleeps.append(continuation)
        }
    }

    func waitForSleep() async -> Duration {
        if let duration = pendingDurations.first {
            pendingDurations.removeFirst()
            return duration
        }

        return await withCheckedContinuation { continuation in
            durationWaiters.append(continuation)
        }
    }

    func resumeNext() {
        suspendedSleeps.removeFirst().resume()
    }
}
