import XCTest

/// Tests for navigation flows between screens
/// Uses UITestsHelpers for state reset and accessibility identifiers for reliable interactions
final class NavigationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - List to Detail Navigation

    func testNavigateToTimerDetail_OpensDetailView() throws {
        // Create a timer
        createTimer(name: "Navigation Test", minutes: 10)

        // Tap timer card to navigate to detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify we're in detail view
        XCTAssert(app.buttons["startButton"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["resetButton"].exists)
        XCTAssert(app.buttons["addTodoButton"].exists)
    }

    func testNavigateBackToList_ReturnsToTimerList() throws {
        // Create and open timer
        createTimer(name: "Back Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify we're in detail
        XCTAssert(app.buttons["startButton"].waitForExistence(timeout: 5))

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify we're back at list
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Back Test"].exists)
    }

    // MARK: - Create Timer Sheet Navigation

    func testCreateTimerSheet_OpenAndDismiss() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Verify sheet opened
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))

        // Dismiss sheet
        app.buttons["cancelButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify back at list
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
    }

    func testCreateTimerSheet_SaveReturnsToList() throws {
        // Open sheet
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Fill in timer
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Sheet Test Timer")

        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "15")

        // Save
        app.buttons["doneButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify returned to list with new timer
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Sheet Test Timer"].waitForExistence(timeout: 5))
    }

    // MARK: - Edit Timer Sheet Navigation

    func testEditTimerSheet_OpenAndDismiss() throws {
        // Create timer and open detail
        createTimer(name: "Edit Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Open edit sheet
        app.buttons["editTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Verify edit sheet opened
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))

        // Dismiss
        app.buttons["cancelButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify back at detail view
        XCTAssert(app.buttons["startButton"].waitForExistence(timeout: 5))
    }

    // MARK: - Add Todo Sheet Navigation

    func testAddTodoSheet_OpenAndDismiss() throws {
        // Create timer and open detail
        createTimer(name: "Todo Nav Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Open add todo sheet
        app.buttons["addTodoButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Verify sheet opened
        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))

        // Dismiss
        app.buttons["cancelTodoButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify back at detail view
        XCTAssert(app.buttons["addTodoButton"].waitForExistence(timeout: 5))
    }

    // MARK: - Navigation State Tests

    func testNavigationPreservesListState() throws {
        // Create multiple timers
        createTimer(name: "Timer 1", minutes: 5)
        createTimer(name: "Timer 2", minutes: 10)
        createTimer(name: "Timer 3", minutes: 15)

        // Verify all exist
        XCTAssert(app.staticTexts["Timer 1"].exists)
        XCTAssert(app.staticTexts["Timer 2"].exists)
        XCTAssert(app.staticTexts["Timer 3"].exists)

        // Navigate to detail and back
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).element(boundBy: 1)
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify all timers still exist
        XCTAssert(app.staticTexts["Timer 1"].exists)
        XCTAssert(app.staticTexts["Timer 2"].exists)
        XCTAssert(app.staticTexts["Timer 3"].exists)
    }

    // MARK: - Helper Methods

    /// Creates a timer using accessibility identifiers
    private func createTimer(name: String, hours: Int = 0, minutes: Int = 1, seconds: Int = 0) {
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 10))  // Increased from 5
        nameField.clearAndType(name)

        if hours > 0 {
            app.pickers["hoursPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: String(hours))
        }

        if minutes > 0 {
            app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: String(minutes))
        }

        if seconds > 0 {
            app.pickers["secondsPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: String(seconds))
        }

        app.buttons["doneButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Wait for sheet to dismiss
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 10))  // Increased from 5
        waitForUIToSettle(0.3)  // Let list update
    }
}
