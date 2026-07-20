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
}
