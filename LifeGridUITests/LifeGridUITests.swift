import XCTest

final class LifeGridUITests: XCTestCase {
    @MainActor
    func testFoundationAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
