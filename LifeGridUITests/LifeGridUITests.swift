import XCTest

final class LifeGridUITests: XCTestCase {
    private let resetArgument = "--ui-testing-reset-state"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchCreatesAndRestoresGame() {
        let app = launchResetApp()

        app.buttons["player-count-decrement"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["player-count"].value as? String, "3")
        app.buttons["starting-life-25"].tap()
        app.textFields["opponent-name-1"].tap()
        app.textFields["opponent-name-1"].typeText("Amanda")
        app.textFields["opponent-name-2"].tap()
        app.textFields["opponent-name-2"].typeText("Chris")
        app.buttons["start-game"].tap()

        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["25"].exists)
        XCTAssertTrue(app.staticTexts["Amanda"].exists)
        XCTAssertTrue(app.staticTexts["Chris"].exists)
        attachScreenshot(named: "phase2-active-game", app: app)

        app.terminate()
        let restoredApp = launchPreservingApp()

        XCTAssertTrue(element("active-game-summary", in: restoredApp).waitForExistence(timeout: 3))
        XCTAssertTrue(restoredApp.staticTexts["25"].exists)
        XCTAssertTrue(restoredApp.staticTexts["3"].exists)
        XCTAssertTrue(restoredApp.staticTexts["Amanda"].exists)
        XCTAssertTrue(restoredApp.staticTexts["Chris"].exists)
    }

    @MainActor
    func testInvalidCustomLifeKeepsDraftAndDisablesStart() {
        let app = launchResetApp()

        app.buttons["starting-life-custom"].tap()
        let customLife = app.textFields["custom-starting-life"]
        customLife.tap()
        customLife.typeText("0")

        XCTAssertEqual(customLife.value as? String, "0")
        XCTAssertTrue(element("custom-starting-life-error", in: app).exists)
        XCTAssertFalse(app.buttons["start-game"].isEnabled)
        attachScreenshot(named: "phase2-invalid-custom-life", app: app)
    }

    @MainActor
    func testLaunchResetClearsExistingGame() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))
        app.terminate()

        let resetApp = launchResetApp()
        XCTAssertTrue(element("new-game-screen", in: resetApp).waitForExistence(timeout: 3))
        XCTAssertFalse(element("active-game-summary", in: resetApp).exists)
    }

    @MainActor
    func testReplacementCancelPreservesGameAndDraft() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))

        app.buttons["new-game-toolbar"].tap()
        XCTAssertTrue(element("new-game-screen", in: app).waitForExistence(timeout: 3))
        app.buttons["starting-life-25"].tap()
        app.buttons["start-game"].tap()
        XCTAssertTrue(app.buttons["Start New Game"].waitForExistence(timeout: 2))
        attachScreenshot(named: "phase2-replacement-confirmation", app: app)
        app.buttons["Cancel"].firstMatch.tap()

        XCTAssertTrue(element("new-game-screen", in: app).exists)
        XCTAssertEqual(app.buttons["starting-life-25"].value as? String, "Selected")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["40"].exists)
    }

    @MainActor
    func testReplacementConfirmCreatesNewGame() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))

        app.buttons["new-game-toolbar"].tap()
        app.buttons["starting-life-25"].tap()
        app.buttons["start-game"].tap()
        XCTAssertTrue(app.buttons["Start New Game"].waitForExistence(timeout: 2))
        app.buttons["Start New Game"].tap()

        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["25"].exists)
        XCTAssertFalse(app.staticTexts["40"].exists)
    }

    @MainActor
    func testSettingsDefaultUpdatesNextNewGameWithoutChangingActiveGame() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 3))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(element("settings-default-life", in: app).waitForExistence(timeout: 2))
        app.buttons["starting-life-25"].tap()
        XCTAssertEqual(app.buttons["starting-life-25"].value as? String, "Selected")
        attachScreenshot(named: "phase2-settings-default-life", app: app)

        app.tabBars.buttons["Game"].tap()
        XCTAssertTrue(element("active-game-summary", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["40"].exists)
        app.buttons["new-game-toolbar"].tap()
        XCTAssertTrue(element("new-game-screen", in: app).waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["starting-life-25"].value as? String, "Selected")
    }

    @MainActor
    func testFourTabsRemainAvailable() {
        let app = launchResetApp()

        for tab in ["Game", "Counters", "Dice", "Settings"] {
            XCTAssertTrue(app.tabBars.buttons[tab].exists, "Missing \(tab) tab")
        }
        attachScreenshot(named: "phase2-new-game", app: app)
    }

    @MainActor
    private func launchResetApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [resetArgument]
        app.launch()
        XCTAssertTrue(
            element("new-game-screen", in: app).waitForExistence(timeout: 3),
            "Reset launch did not show New Game"
        )
        return app
    }

    @MainActor
    private func launchPreservingApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
