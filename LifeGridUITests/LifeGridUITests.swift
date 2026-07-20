import XCTest

final class LifeGridUITests: XCTestCase {
    func testFoundationAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
