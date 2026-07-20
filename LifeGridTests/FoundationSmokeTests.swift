import Testing
@testable import LifeGrid

struct FoundationSmokeTests {
    @Test func testTargetLoadsApplicationModule() {
        _ = FoundationRootView()
    }
}
