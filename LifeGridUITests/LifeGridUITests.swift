import XCTest

final class LifeGridUITests: XCTestCase {
    private let resetArgument = "--ui-testing-reset-state"
    private let commanderDisabledArgument = "--ui-testing-commander-disabled"

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

        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))
        let lifeTotal = app.buttons["life-total"]
        XCTAssertTrue(lifeTotal.waitForExistence(timeout: 2))
        XCTAssertEqual(lifeTotal.value as? String, "25")
        attachScreenshot(named: "phase2-active-game", app: app)

        app.terminate()
        let restoredApp = launchPreservingApp()

        XCTAssertTrue(element("game-screen", in: restoredApp).waitForExistence(timeout: 3))
        XCTAssertEqual(restoredApp.buttons["life-total"].value as? String, "25")
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
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))
        app.terminate()

        let resetApp = launchResetApp()
        XCTAssertTrue(element("new-game-screen", in: resetApp).waitForExistence(timeout: 3))
        XCTAssertFalse(element("game-screen", in: resetApp).exists)
    }

    @MainActor
    func testReplacementCancelPreservesGameAndDraft() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))

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
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["life-total"].value as? String, "40")
    }

    @MainActor
    func testReplacementConfirmCreatesNewGame() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))

        app.buttons["new-game-toolbar"].tap()
        app.buttons["starting-life-25"].tap()
        app.buttons["start-game"].tap()
        XCTAssertTrue(app.buttons["Start New Game"].waitForExistence(timeout: 2))
        app.buttons["Start New Game"].tap()

        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["life-total"].value as? String, "25")
    }

    @MainActor
    func testReplacingGameClearsPendingLifeUndo() {
        let app = launchResetApp()
        startDefaultGame(in: app)

        app.buttons["life-decrement"].tap()
        XCTAssertEqual(app.buttons["life-total"].value as? String, "39")
        XCTAssertTrue(app.buttons["life-undo"].exists)

        app.buttons["new-game-toolbar"].tap()
        app.buttons["starting-life-25"].tap()
        app.buttons["start-game"].tap()
        app.buttons["Start New Game"].tap()

        XCTAssertTrue(
            waitForValueWithoutInitialDelay(
                "25",
                for: app.buttons["life-total"]
            )
        )
        XCTAssertFalse(app.buttons["life-undo"].exists)
    }

    @MainActor
    func testSettingsDefaultUpdatesNextNewGameWithoutChangingActiveGame() {
        let app = launchResetApp()
        app.buttons["start-game"].tap()
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 3))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(element("settings-default-life", in: app).waitForExistence(timeout: 2))
        app.buttons["starting-life-25"].tap()
        XCTAssertEqual(app.buttons["starting-life-25"].value as? String, "Selected")
        attachScreenshot(named: "phase2-settings-default-life", app: app)

        app.tabBars.buttons["Game"].tap()
        XCTAssertTrue(element("game-screen", in: app).waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["life-total"].value as? String, "40")
        app.buttons["new-game-toolbar"].tap()
        XCTAssertTrue(element("new-game-screen", in: app).waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["starting-life-25"].value as? String, "Selected")
    }

    @MainActor
    func testLocalLifeControlsUndoAndPersistence() {
        let app = launchResetApp()
        startDefaultGame(in: app)

        let lifeTotal = app.buttons["life-total"]
        XCTAssertTrue(lifeTotal.waitForExistence(timeout: 2))
        XCTAssertEqual(lifeTotal.value as? String, "40")

        app.buttons["life-decrement"].tap()
        assertValue("39", for: lifeTotal)

        app.buttons["life-increment"].tap()
        assertValue("40", for: lifeTotal)

        let undo = app.buttons["life-undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        undo.tap()
        assertValue("39", for: lifeTotal)
        attachScreenshot(named: "phase3a-local-life", app: app)

        app.terminate()
        let restoredApp = launchPreservingApp()

        XCTAssertTrue(element("game-screen", in: restoredApp).waitForExistence(timeout: 3))
        assertValue("39", for: restoredApp.buttons["life-total"])
    }

    @MainActor
    func testExactLifeEntryAcceptsNegativeUndoAndRejectsInvalidInput() {
        let app = launchResetApp()
        startDefaultGame(in: app)
        let lifeTotal = app.buttons["life-total"]

        lifeTotal.tap()
        let entry = app.textFields["Life total"]
        XCTAssertTrue(entry.waitForExistence(timeout: 2))
        replaceText(in: entry, with: "-7")
        app.buttons["Set"].tap()
        assertValue("-7", for: lifeTotal)

        let undo = app.buttons["life-undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        undo.tap()
        assertValue("40", for: lifeTotal)

        lifeTotal.tap()
        XCTAssertTrue(entry.waitForExistence(timeout: 2))
        replaceText(in: entry, with: "--")
        app.buttons["Set"].tap()

        XCTAssertTrue(app.staticTexts["Enter a whole-number life total."].waitForExistence(timeout: 2))
        XCTAssertTrue(element("life-exact-entry", in: app).exists)
        app.buttons["Cancel"].tap()
        assertValue("40", for: lifeTotal)
    }

    @MainActor
    func testCommanderTaxUsesTwoPointFloorWithoutLifeUndo() {
        let app = launchResetApp()
        startDefaultGame(in: app)

        let taxValue = app.staticTexts["Commander tax"]
        XCTAssertTrue(taxValue.waitForExistence(timeout: 2))
        XCTAssertEqual(taxValue.value as? String, "0")
        XCTAssertFalse(app.buttons["life-undo"].exists)

        app.buttons["commander-tax-decrement"].tap()
        XCTAssertEqual(taxValue.value as? String, "0")
        app.buttons["commander-tax-increment"].tap()
        assertValue("2", for: taxValue)

        XCTAssertEqual(app.buttons["life-total"].value as? String, "40")
        XCTAssertFalse(app.buttons["life-undo"].exists)
    }

    @MainActor
    func testCommanderDisabledFixtureHidesTaxAndKeepsLifeControls() {
        let app = launchResetApp(
            additionalArguments: [commanderDisabledArgument]
        )
        startDefaultGame(in: app)

        XCTAssertTrue(app.buttons["life-decrement"].exists)
        XCTAssertTrue(app.buttons["life-total"].exists)
        XCTAssertTrue(app.buttons["life-increment"].exists)
        XCTAssertFalse(app.staticTexts["Commander Tax"].exists)
        XCTAssertFalse(app.buttons["commander-tax-decrement"].exists)
        XCTAssertFalse(app.buttons["commander-tax-increment"].exists)
    }

    @MainActor
    func testOpponentCardsAddDamageAndPersist() {
        let app = launchResetApp()
        startDefaultGame(in: app)

        XCTAssertTrue(app.buttons["add-opponent"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Opponent 1"].exists)
        XCTAssertFalse(app.staticTexts["Opponent 1 life"].exists)

        let total = app.buttons["Set Opponent 1's commander damage"]
        XCTAssertEqual(total.value as? String, "0")
        app.buttons["Add one commander damage from Opponent 1"].tap()
        assertValue("1", for: total)
        assertValue("39", for: app.buttons["life-total"])

        app.buttons["add-opponent"].tap()
        XCTAssertTrue(app.staticTexts["Opponent 4"].waitForExistence(timeout: 2))
        attachScreenshot(named: "phase3b-primary-opponents", app: app)

        app.terminate()
        let restored = launchPreservingApp()
        XCTAssertTrue(element("game-screen", in: restored).waitForExistence(timeout: 3))
        assertValue("1", for: restored.buttons["Set Opponent 1's commander damage"])
        assertValue("39", for: restored.buttons["life-total"])
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
    private func launchResetApp(
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [resetArgument] + additionalArguments
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
    private func startDefaultGame(in app: XCUIApplication) {
        app.buttons["start-game"].tap()
        XCTAssertTrue(
            element("game-screen", in: app).waitForExistence(timeout: 3),
            "Starting a default game did not show the Game screen"
        )
    }

    @MainActor
    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        guard let currentValue = field.value as? String else {
            XCTFail("Expected a text value before replacement")
            return
        }
        field.typeText(
            String(
                repeating: XCUIKeyboardKey.delete.rawValue,
                count: currentValue.count
            )
        )
        field.typeText(text)
    }

    @MainActor
    private func assertValue(
        _ expectedValue: String,
        for element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "value == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 3),
            .completed,
            "Expected value \(expectedValue), got \(String(describing: element.value))",
            file: file,
            line: line
        )
    }

    @MainActor
    private func waitForValueWithoutInitialDelay(
        _ expectedValue: String,
        for element: XCUIElement,
        timeout: TimeInterval = 3
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.value as? String == expectedValue {
                return true
            }
        } while Date() < deadline
        return false
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
