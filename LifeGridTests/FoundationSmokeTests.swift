import SwiftUI
import Testing
@testable import LifeGrid

struct FoundationSmokeTests {
    @Test func testTargetLoadsApplicationModule() {
        _ = FoundationRootView()
    }

    @Test func setupComponentsLoadApplicationModule() {
        _ = StartingLifePicker(
            input: .constant(StartingLifeInput(value: 40))
        )
        _ = Text("Card").modifier(LifeGridCard())
    }

    @MainActor @Test func newGameScreenLoadsApplicationModule() {
        let store = AppStateStore(environment: AppEnvironment(
            repository: ScriptedAppStateRepository(),
            randomSource: ScriptedRandomSource([1]),
            clock: TestClock(date: .distantPast),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        ))

        _ = NewGameScreen(store: store)
    }
}
