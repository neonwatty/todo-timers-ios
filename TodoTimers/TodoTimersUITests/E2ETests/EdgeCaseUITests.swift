import XCTest

/// Tests for edge cases and error conditions
/// Uses UITestsHelpers for state reset and accessibility identifiers for reliable interactions
final class EdgeCaseUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Timer Validation Edge Cases

    func testCreateTimer_EmptyName_DisablesDoneButton() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))

        // Don't enter a name
        let doneButton = app.buttons["doneButton"]
        XCTAssert(doneButton.exists)

        // Done button should be disabled
        XCTAssertFalse(doneButton.isEnabled)
    }

    func testCreateTimer_ZeroDuration_DisablesDoneButton() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Zero Duration Test")

        // Leave duration at 0:0:0 (default)
        // All pickers should be at 0

        let doneButton = app.buttons["doneButton"]

        // Done button should be disabled
        XCTAssertFalse(doneButton.isEnabled)
    }

    func testCreateTimer_VeryLongName_HandlesGracefully() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))

        // Enter very long name (100 characters)
        let longName = String(repeating: "A", count: 100)
        nameField.clearAndType(longName)

        // Set duration
        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "5")

        // Save
        app.buttons["doneButton"].tap()

        // Verify timer was created (name may be truncated in display)
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
    }

    func testCreateTimer_MaximumDuration_HandlesCorrectly() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Max Duration Timer")

        // Set to maximum duration (23 hours, 59 minutes, 59 seconds)
        app.pickers["hoursPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "23")
        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "59")
        app.pickers["secondsPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "59")

        // Save
        app.buttons["doneButton"].tap()

        // Verify timer was created
        XCTAssert(app.staticTexts["Max Duration Timer"].waitForExistence(timeout: 5))
    }

    // MARK: - Todo Validation Edge Cases

    func testAddTodo_EmptyText_PreventsSave() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Todo Validation Test")

        // Try to add empty todo
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))

        // Don't enter text, tap add button
        let addButton = app.buttons["addTodoConfirmButton"]
        addButton.tap()

        // Verify sheet is still present (validation prevented add)
        XCTAssert(todoField.exists)
    }

    func testAddTodo_VeryLongText_HandlesGracefully() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Long Todo Test")

        // Add todo with very long text
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))

        // Enter very long text (200 characters)
        let longText = String(repeating: "Lorem ipsum dolor sit amet ", count: 8)
        todoField.clearAndType(longText)

        app.buttons["addTodoConfirmButton"].tap()

        // Verify todo was added (text may be truncated in display)
        let todoRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        ).firstMatch
        XCTAssert(todoRow.waitForExistence(timeout: 5))
    }

    // MARK: - Stress Tests

    func testCreateMultipleTimers_RapidSuccession_HandlesCorrectly() throws {
        // Create 5 timers rapidly
        for i in 1...5 {
            app.buttons["addTimerButton"].tap()

            let nameField = app.textFields["timerNameField"]
            XCTAssert(nameField.waitForExistence(timeout: 5))
            nameField.clearAndType("Rapid Timer \(i)")

            app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: String(i))

            app.buttons["doneButton"].tap()

            // Wait for sheet to dismiss
            XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
        }

        // Verify all timers were created
        XCTAssert(app.staticTexts["Rapid Timer 1"].exists)
        XCTAssert(app.staticTexts["Rapid Timer 2"].exists)
        XCTAssert(app.staticTexts["Rapid Timer 3"].exists)
        XCTAssert(app.staticTexts["Rapid Timer 4"].exists)
        XCTAssert(app.staticTexts["Rapid Timer 5"].exists)
    }

    func testToggleTodos_RapidClicks_HandlesCorrectly() throws {
        // Create timer and add multiple todos
        createTimerAndOpenDetail(name: "Rapid Toggle Test")

        addTodo(text: "Todo 1")
        addTodo(text: "Todo 2")
        addTodo(text: "Todo 3")

        // Get all checkboxes
        let checkboxes = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoCheckbox-'")
        )

        // Toggle all rapidly
        for i in 0..<3 {
            checkboxes.element(boundBy: i).tap()
        }

        // Toggle back
        for i in 0..<3 {
            checkboxes.element(boundBy: i).tap()
        }

        // Verify todos still exist
        XCTAssert(app.staticTexts["Todo 1"].exists)
        XCTAssert(app.staticTexts["Todo 2"].exists)
        XCTAssert(app.staticTexts["Todo 3"].exists)
    }

    // MARK: - Special Characters Edge Cases

    func testCreateTimer_SpecialCharacters_HandlesCorrectly() throws {
        // Open create sheet
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))

        // Enter name with special characters
        nameField.clearAndType("Timer!@#$%^&*()")

        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "5")

        app.buttons["doneButton"].tap()

        // Verify timer was created
        XCTAssert(app.staticTexts["Timer!@#$%^&*()"].waitForExistence(timeout: 5))
    }

    func testAddTodo_EmojisAndSpecialCharacters_HandlesCorrectly() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Special Char Todo Test")

        // Add todo with emojis and special characters
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))
        todoField.clearAndType("🎉 Party! 🎊 @#$% time")

        app.buttons["addTodoConfirmButton"].tap()

        // Verify todo was added
        XCTAssert(app.staticTexts["🎉 Party! 🎊 @#$% time"].waitForExistence(timeout: 5))
    }

    // MARK: - Helper Methods

    /// Creates a timer and opens its detail view
    private func createTimerAndOpenDetail(name: String) {
        // Create timer
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType(name)

        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "5")
        app.buttons["doneButton"].tap()

        // Wait for sheet to dismiss
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))

        // Open timer detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()

        // Verify we're in detail view
        XCTAssert(app.buttons["addTodoButton"].waitForExistence(timeout: 5))
    }

    /// Adds a todo to the current timer detail view
    private func addTodo(text: String) {
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))
        todoField.clearAndType(text)

        app.buttons["addTodoConfirmButton"].tap()

        // Wait for sheet to dismiss
        XCTAssert(app.buttons["addTodoButton"].waitForExistence(timeout: 5))
    }
}
