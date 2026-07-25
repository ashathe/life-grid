import Foundation
import Testing
@testable import LifeGrid

@MainActor
@Suite(.serialized) struct RepeatActionButtonTests {
    @Test func localLifeScheduleUsesSpecifiedTiming() {
        #expect(RepeatActionSchedule.localLife == RepeatActionSchedule(
            initialDelay: .milliseconds(350),
            interval: .milliseconds(120)
        ))
    }

    @Test func beginFiresRepeatAfterInitialDelay() async {
        let sleeper = ControlledRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            schedule: RepeatActionSchedule(
                initialDelay: .milliseconds(350),
                interval: .milliseconds(120)
            ),
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })

        #expect(repeats == 0)
        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        await sleeper.resumeNext()
        await Task.yield()
        #expect(repeats == 1)

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func repeatFiresAfterInitialDelayAndEachInterval() async {
        let sleeper = ControlledRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            schedule: RepeatActionSchedule(
                initialDelay: .milliseconds(350),
                interval: .milliseconds(120)
            ),
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })

        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        #expect(repeats == 1)

        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        #expect(repeats == 2)

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func cancelPreventsRepeatsAfterAnIntervalStarts() async {
        let sleeper = ControlledRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })

        _ = await sleeper.waitForSleep()
        await sleeper.resumeNext()
        _ = await sleeper.waitForSleep()

        driver.cancel()
        await sleeper.resumeNext()
        await Task.yield()

        #expect(repeats == 1)
    }

    @Test func repeatedBeginDoesNotCreateMultipleRepeatLoops() async {
        let sleeper = ControlledRepeatSleeper()
        var repeats = 0
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in await sleeper.sleep(for: duration) }
        )

        driver.begin(onRepeat: { repeats += 1 })
        driver.begin(onRepeat: { repeats += 1 })

        #expect(repeats == 0)
        _ = await sleeper.waitForSleep()
        await sleeper.resumeNext()
        await Task.yield()
        #expect(repeats == 1)

        driver.cancel()
        await sleeper.resumeNext()
    }
}

private actor ControlledRepeatSleeper {
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
