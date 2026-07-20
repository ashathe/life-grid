import Foundation
@testable import LifeGrid

actor ScriptedRandomSource: RandomSource {
    private var values: [Int]

    init(_ values: [Int]) {
        self.values = values
    }

    func nextInt(in range: ClosedRange<Int>) -> Int {
        let value = values.removeFirst()
        precondition(range.contains(value))
        return value
    }
}

struct TestClock: ClockClient {
    let date: Date

    func now() async -> Date { date }
}

actor RecordingHapticsClient: HapticsClient {
    private var recordedEvents: [HapticEvent] = []

    func play(_ event: HapticEvent) {
        recordedEvents.append(event)
    }

    func events() -> [HapticEvent] { recordedEvents }
}

actor RecordingSoundClient: SoundClient {
    private var recordedEvents: [SoundEvent] = []

    func play(_ event: SoundEvent) {
        recordedEvents.append(event)
    }

    func events() -> [SoundEvent] { recordedEvents }
}
