import Foundation
import Testing
@testable import LifeGrid

struct CommanderDamageChangeTests {
    @Test func valuePreservesDamageAndLifeBoundaries() {
        let change = CommanderDamageChange(
            previousDamage: 20,
            currentDamage: 21,
            previousLife: 23,
            currentLife: 22
        )

        #expect(change.previousDamage == 20)
        #expect(change.currentDamage == 21)
        #expect(change.previousLife == 23)
        #expect(change.currentLife == 22)
    }

    @Test func opponentMutationResultDistinguishesPersistenceOutcomes() {
        let opponent = OpponentState.newDefault(displayName: "Opponent 4")

        #expect(OpponentMutationResult.persisted(opponent).persistedValue == opponent)
        #expect(OpponentMutationResult.retainedInMemory(opponent).mutation == opponent)
        #expect(OpponentMutationResult<OpponentState>.rejected.mutation == nil)
    }

    @Test func exactDamageIdentifiersAreStableAndUniquePerOpponent() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        #expect(OpponentCard.exactDamageEntryIdentifier(for: first) ==
                "opponent-damage-exact-entry-00000000-0000-0000-0000-000000000001")
        #expect(OpponentCard.exactDamageEntryIdentifier(for: first) !=
                OpponentCard.exactDamageEntryIdentifier(for: second))
    }

    @Test func exactDamageFeedbackSeparatesMissingOpponentFromOtherRejections() {
        #expect(OpponentCard.exactDamageRejectionMessage(opponentExists: false) ==
                "Opponent is no longer in this game.")
        #expect(OpponentCard.exactDamageRejectionMessage(opponentExists: true) ==
                "Commander damage could not be updated.")
        #expect(OpponentCard.retainedInMemoryMessage ==
                "The change is kept for this session but could not be saved.")
    }
}

@MainActor
struct OpponentDamageInteractionTests {
    @Test func productionRepeatMutatesAndHapticsExactlyOnceAfterApprovedDelay() async {
        let fixture = makeFixture(startingDamage: 0)
        let sleeper = ControlledOpponentRepeatSleeper()
        let interaction = OpponentDamageInteractionController(
            store: fixture.store,
            opponentID: fixture.opponentID,
            amount: 1,
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        interaction.begin()
        await interaction.waitForPendingActions()
        #expect(fixture.store.state.activeGame?.opponents[0].primaryCommanderDamage == 1)
        #expect(await fixture.haptics.events().isEmpty)
        #expect(await sleeper.waitForSleep() == .milliseconds(350))

        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        await interaction.waitForPendingActions()

        #expect(fixture.store.state.activeGame?.opponents[0].primaryCommanderDamage == 2)
        #expect(await fixture.haptics.events() == [.adjustment])
        #expect(await fixture.repository.savedSnapshots().count == 2)

        interaction.end()
        await sleeper.resumeNext()
    }

    @Test func productionZeroFloorRepeatDoesNotHapticOrPersist() async {
        let fixture = makeFixture(startingDamage: 0)
        let sleeper = ControlledOpponentRepeatSleeper()
        let interaction = OpponentDamageInteractionController(
            store: fixture.store,
            opponentID: fixture.opponentID,
            amount: -1,
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        interaction.begin()
        await interaction.waitForPendingActions()
        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        await interaction.waitForPendingActions()

        #expect(fixture.store.state.activeGame?.opponents[0].primaryCommanderDamage == 0)
        #expect(await fixture.haptics.events().isEmpty)
        #expect(await fixture.repository.savedSnapshots().isEmpty)

        interaction.end()
        await sleeper.resumeNext()
    }

    @Test func productionGestureCancellationStopsRepeatAndAllowsNextHold() async {
        let fixture = makeFixture(startingDamage: 0)
        let sleeper = ControlledOpponentRepeatSleeper()
        let interaction = OpponentDamageInteractionController(
            store: fixture.store,
            opponentID: fixture.opponentID,
            amount: 1,
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        interaction.begin()
        await interaction.waitForPendingActions()
        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        interaction.gestureActivityChanged(from: true, to: false)
        await sleeper.resumeNext()
        await Task.yield()

        #expect(fixture.store.state.activeGame?.opponents[0].primaryCommanderDamage == 1)
        #expect(await fixture.haptics.events().isEmpty)

        interaction.begin()
        await interaction.waitForPendingActions()
        #expect(fixture.store.state.activeGame?.opponents[0].primaryCommanderDamage == 2)
        #expect(await sleeper.waitForSleep() == .milliseconds(350))

        interaction.cancel()
        await sleeper.resumeNext()
    }
}

private extension OpponentDamageInteractionTests {
    struct Fixture {
        let store: AppStateStore
        let opponentID: UUID
        let repository: ScriptedAppStateRepository
        let haptics: RecordingHapticsClient
    }

    func makeFixture(startingDamage: Int) -> Fixture {
        let opponentID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!
        var initial = PersistedAppState.default
        var game = ActiveGameFactory.make(
            setup: GameSetup(
                totalPlayers: 2,
                startingLife: 40,
                opponentNames: ["Opponent 1"]
            ),
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            opponentIDs: [opponentID],
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        game.opponents[0].primaryCommanderDamage = startingDamage
        initial.activeGame = game

        let repository = ScriptedAppStateRepository()
        let haptics = RecordingHapticsClient()
        let store = AppStateStore(
            environment: AppEnvironment(
                repository: repository,
                randomSource: ScriptedRandomSource([1]),
                clock: TestClock(date: .distantPast),
                haptics: haptics,
                sound: NoOpSoundClient()
            ),
            initialState: initial
        )
        return Fixture(
            store: store,
            opponentID: opponentID,
            repository: repository,
            haptics: haptics
        )
    }
}

private actor ControlledOpponentRepeatSleeper {
    private var pendingDurations: [Duration] = []
    private var durationWaiters: [CheckedContinuation<Duration, Never>] = []
    private var suspendedSleeps: [CheckedContinuation<Void, Never>] = []

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
