import Foundation
import Testing
@testable import LifeGrid

struct AppEnvironmentTests {
    @Test func deterministicRandomSourceReturnsScriptedValues() async {
        let source = ScriptedRandomSource([4, 1, 3])

        let results = await [
            source.nextInt(in: 1...6),
            source.nextInt(in: 1...6),
            source.nextInt(in: 1...6)
        ]

        #expect(results == [4, 1, 3])
    }

    @Test func testClockReturnsFixedDate() async {
        let expected = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = TestClock(date: expected)

        #expect(await clock.now() == expected)
    }

    @Test func recordingFeedbackClientsCaptureEvents() async {
        let haptics = RecordingHapticsClient()
        let sound = RecordingSoundClient()

        await haptics.play(.adjustment)
        await haptics.play(.warning)
        await sound.play(.diceResult)

        #expect(await haptics.events() == [.adjustment, .warning])
        #expect(await sound.events() == [.diceResult])
    }
}
