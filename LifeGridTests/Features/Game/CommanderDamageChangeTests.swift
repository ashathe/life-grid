import Foundation
import Testing
@testable import LifeGrid

@Suite(.serialized) struct CommanderDamageChangeTests {
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
@Suite(.serialized) struct OpponentDamageInteractionTests {
    private struct TestMutations {
        var initialCount = 0
        var repeatCount = 0
        var lastWasRejected = false

        mutating func acceptedMutation() -> Bool {
            initialCount += 1
            return true
        }

        mutating func rejectedMutation() -> Bool {
            lastWasRejected = true
            return false
        }
    }

    @Test func repeatFiresAfterDelayAndCallsOnRepeat() async {
        let sleeper = ControlledOpponentRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })
        #expect(repeats == 0)
        #expect(await sleeper.waitForSleep() == .milliseconds(350))

        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        #expect(repeats == 1)

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func cancelStopsRepeats() async {
        let sleeper = ControlledOpponentRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })
        _ = await sleeper.waitForSleep()
        driver.cancel()
        await sleeper.resumeNext()
        await Task.yield()

        #expect(repeats == 0)
    }

    @Test func secondBeginAfterCancelWorks() async {
        let sleeper = ControlledOpponentRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })
        _ = await sleeper.waitForSleep()
        driver.cancel()
        await sleeper.resumeNext()

        driver.begin(onRepeat: { repeats += 1 })
        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        await sleeper.resumeNext()

        #expect(repeats == 1)
        driver.cancel()
        await sleeper.resumeNext()
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
