import Foundation
import Testing
@testable import LifeGrid

@MainActor
struct RepeatActionButtonTests {
    @Test func localLifeScheduleUsesSpecifiedTiming() {
        #expect(RepeatActionSchedule.localLife == RepeatActionSchedule(
            initialDelay: .milliseconds(350),
            interval: .milliseconds(120)
        ))
    }

    @Test func repeatedBeginDuringOnePressInvokesInitialOnlyOnce() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )
        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )

        #expect(actions == [.initial])
        _ = await sleeper.waitForSleep()

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func activeGestureBecomingInactiveStopsRepeatAndAllowsLaterPress() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )
        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )
        _ = await sleeper.waitForSleep()

        driver.gestureActivityChanged(from: false, to: true)
        driver.gestureActivityChanged(from: true, to: false)
        await Task.yield()
        await sleeper.resumeNext()
        await Task.yield()

        #expect(actions == [.initial])

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )

        #expect(actions == [.initial, .initial])
        _ = await sleeper.waitForSleep()

        driver.end()
        await sleeper.resumeNext()
    }

    @Test func beginInvokesInitialOnceWithoutRepeatingBeforeTheDelay() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: RepeatActionSchedule(
                initialDelay: .milliseconds(350),
                interval: .milliseconds(120)
            ),
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )

        #expect(actions == [.initial])
        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        #expect(actions == [.initial])

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func repeatFiresAfterInitialDelayAndEachInterval() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: RepeatActionSchedule(
                initialDelay: .milliseconds(350),
                interval: .milliseconds(120)
            ),
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )

        #expect(await sleeper.waitForSleep() == .milliseconds(350))
        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        #expect(actions == [.initial, .repeat])

        await sleeper.resumeNext()
        #expect(await sleeper.waitForSleep() == .milliseconds(120))
        #expect(actions == [.initial, .repeat, .repeat])

        driver.cancel()
        await sleeper.resumeNext()
    }

    @Test func endPreventsRepeatsAfterTheInitialDelay() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )
        _ = await sleeper.waitForSleep()

        driver.end()
        await sleeper.resumeNext()
        await Task.yield()

        #expect(actions == [.initial])
    }

    @Test func cancelPreventsRepeatsAfterAnIntervalStarts() async {
        let sleeper = ControlledRepeatSleeper()
        var actions: [RepeatAction] = []
        let driver = RepeatActionDriver(
            schedule: .localLife,
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        driver.begin(
            onInitial: { actions.append(.initial) },
            onRepeat: { actions.append(.repeat) }
        )
        _ = await sleeper.waitForSleep()
        await sleeper.resumeNext()
        _ = await sleeper.waitForSleep()

        driver.cancel()
        await sleeper.resumeNext()
        await Task.yield()

        #expect(actions == [.initial, .repeat])
    }
}

private enum RepeatAction: Equatable {
    case initial
    case `repeat`
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
