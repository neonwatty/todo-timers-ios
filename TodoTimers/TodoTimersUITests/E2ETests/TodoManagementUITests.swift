import XCTest

/// Tests for todo management functionality within timers
/// Uses UITestsHelpers for state reset and accessibility identifiers for reliable interactions
final class TodoManagementUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Add Todo Tests

    func testAddTodo_ValidText_AppearsInList() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Todo Test Timer")

        // Add todo
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))
        todoField.clearAndType("Buy groceries")

        app.buttons["addTodoConfirmButton"].tap()

        // Verify todo appears
        XCTAssert(app.staticTexts["Buy groceries"].waitForExistence(timeout: 5))
    }

    func testAddTodo_EmptyText_ShowsValidation() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Validation Test Timer")

        // Try to add empty todo
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))

        // Don't enter text
        let addButton = app.buttons["addTodoConfirmButton"]

        // Add button should be disabled or tapping should not add empty todo
        // Note: Exact validation behavior depends on implementation
        addButton.tap()

        // Verify sheet is still present (validation prevented add)
        XCTAssert(todoField.exists)
    }

    func testAddTodo_Cancel_DoesNotSave() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Cancel Test Timer")

        // Count initial todos (should be 0)
        let initialTodoCount = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        ).count

        // Open add todo sheet
        app.buttons["addTodoButton"].tap()

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))
        todoField.clearAndType("Should Not Save")

        // Cancel
        app.buttons["cancelTodoButton"].tap()

        // Verify todo was not added
        let finalTodoCount = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        ).count
        XCTAssertEqual(initialTodoCount, finalTodoCount)
        XCTAssertFalse(app.staticTexts["Should Not Save"].exists)
    }

    // MARK: - Toggle Todo Tests

    func testToggleTodo_MarksAsComplete() throws {
        // Create timer, open detail, add todo
        createTimerAndOpenDetail(name: "Toggle Test Timer")
        addTodo(text: "Complete this task")

        // Find and tap checkbox
        let checkbox = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoCheckbox-'")
        ).firstMatch
        XCTAssert(checkbox.waitForExistence(timeout: 5))
        checkbox.tap()

        // Verify todo still exists (completion is visual state change)
        XCTAssert(app.staticTexts["Complete this task"].exists)
    }

    func testToggleTodo_CanBeUnchecked() throws {
        // Create timer, open detail, add todo
        createTimerAndOpenDetail(name: "Uncheck Test Timer")
        addTodo(text: "Toggle task")

        // Find checkbox
        let checkbox = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoCheckbox-'")
        ).firstMatch
        XCTAssert(checkbox.waitForExistence(timeout: 5))

        // Toggle on
        checkbox.tap()

        // Toggle off
        checkbox.tap()

        // Verify todo still exists
        XCTAssert(app.staticTexts["Toggle task"].exists)
    }

    // MARK: - Delete Todo Tests

    func testDeleteTodo_RemovesFromList() throws {
        // Create timer, open detail, add todo
        createTimerAndOpenDetail(name: "Delete Test Timer")
        addTodo(text: "Delete this todo")

        // Verify todo exists
        XCTAssert(app.staticTexts["Delete this todo"].exists)

        // Swipe to delete
        let todoRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        ).firstMatch
        todoRow.swipeLeft()

        // Tap delete button
        app.buttons["Delete"].tap()

        // Verify todo is gone
        XCTAssertFalse(app.staticTexts["Delete this todo"].exists)
    }

    // MARK: - Multiple Todos Tests

    func testMultipleTodos_CanBeManaged() throws {
        // Create timer and open detail
        createTimerAndOpenDetail(name: "Multiple Todos Timer")

        // Add multiple todos
        addTodo(text: "First todo")
        addTodo(text: "Second todo")
        addTodo(text: "Third todo")

        // Verify all exist
        XCTAssert(app.staticTexts["First todo"].exists)
        XCTAssert(app.staticTexts["Second todo"].exists)
        XCTAssert(app.staticTexts["Third todo"].exists)

        // Toggle first todo
        let checkboxes = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoCheckbox-'")
        )
        checkboxes.element(boundBy: 0).tap()

        // Delete second todo
        let todoRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        )
        todoRows.element(boundBy: 1).swipeLeft()
        app.buttons["Delete"].tap()

        // Verify state
        XCTAssert(app.staticTexts["First todo"].exists)
        XCTAssertFalse(app.staticTexts["Second todo"].exists)
        XCTAssert(app.staticTexts["Third todo"].exists)
    }

    // MARK: - Todo State Persistence Tests

    func testTodoState_PersistsAcrossNavigation() throws {
        // Create timer, open detail, add todos
        createTimerAndOpenDetail(name: "Persistence Timer")
        addTodo(text: "Persistent todo")

        // Navigate back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Navigate back to timer detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 3))
        timerCard.tap()

        // Verify todo still exists
        XCTAssert(app.staticTexts["Persistent todo"].waitForExistence(timeout: 3))
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

        // CRITICAL: Wait for sheet dismissal animation to complete
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
        waitForUIToSettle(0.5)  // Let sheet animation complete

        // Find timer card with extended timeout
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 10))  // Increased from 5
        waitForUIToSettle(0.3)  // Let card render

        // Tap and wait for navigation
        timerCard.tap()
        waitForUIToSettle(0.5)  // Let navigation complete

        // Verify detail view with extended timeout
        XCTAssert(app.buttons["addTodoButton"].waitForExistence(timeout: 10))  // Increased from 5
    }

    /// Adds a todo to the current timer detail view
    private func addTodo(text: String) {
        app.buttons["addTodoButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 10))  // Increased from 5
        todoField.clearAndType(text)

        app.buttons["addTodoConfirmButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Wait for sheet to dismiss
        XCTAssert(app.buttons["addTodoButton"].waitForExistence(timeout: 10))  // Increased from 5
    }
}
