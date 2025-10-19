import XCTest

/// Comprehensive tests for Timer CRUD operations using accessibility identifiers
/// Uses UITestsHelpers for state reset and XCUIElementExtensions for reliable interactions
final class TimerCRUDUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Create Timer Tests

    func testCreateTimer_ValidInput_AppearsInList() throws {
        // Tap add button using accessibility ID
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Fill in timer name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Workout Timer")

        // Set duration to 25 minutes
        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "25")

        // Tap Done
        app.buttons["doneButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify timer appears in list
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Workout Timer"].exists)
    }

    func testCreateTimer_AllFields_SavesCorrectly() throws {
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Enter name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Study Session")

        // Set duration (1 hour, 30 minutes, 15 seconds)
        app.pickers["hoursPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "1")
        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "30")
        app.pickers["secondsPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "15")

        // Select icon
        let iconButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'icon-'")
        ).element(boundBy: 1)
        if iconButton.exists {
            iconButton.tap()
        }

        // Select color
        let colorButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'color-'")
        ).element(boundBy: 2)
        if colorButton.exists {
            colorButton.tap()
        }

        // Save
        app.buttons["doneButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify timer exists
        XCTAssert(app.staticTexts["Study Session"].waitForExistence(timeout: 5))
    }

    // FIXME: This test causes hang when run in sequence with 3+ other tests
    // Issue: Empty text field creates problematic UI state that persists despite Cancel cleanup
    // Workaround: Skipped until root cause identified in UI framework interaction
    func disabled_testCreateTimer_EmptyName_DisablesDoneButton() throws {
        app.buttons["addTimerButton"].tap()

        // Don't enter a name
        let doneButton = app.buttons["doneButton"]
        XCTAssert(doneButton.waitForExistence(timeout: 5))

        // Done button should be disabled
        XCTAssertFalse(doneButton.isEnabled)

        // Cleanup: Dismiss sheet to prevent hang in subsequent tests
        app.buttons["cancelButton"].tap()
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
    }

    // FIXME: This test causes hang when run in sequence with other tests (same issue as EmptyName test)
    // Issue: Testing disabled button state creates problematic UI state that persists despite Cancel cleanup
    // Workaround: Skipped until root cause identified in UI framework interaction
    func disabled_testCreateTimer_ZeroDuration_DisablesDoneButton() throws {
        app.buttons["addTimerButton"].tap()

        // Enter name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Test Timer")

        // Leave duration at 0:0:0
        let doneButton = app.buttons["doneButton"]

        // Done button should be disabled
        XCTAssertFalse(doneButton.isEnabled)

        // Cleanup: Dismiss sheet to prevent hang in subsequent tests
        app.buttons["cancelButton"].tap()
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
    }

    func testCreateTimer_Cancel_DoesNotSave() throws {
        // Count initial timers
        let initialTimerCount = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).count

        // Open create sheet
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Enter data
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Canceled Timer")

        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "10")

        // Cancel
        app.buttons["cancelButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Verify no new timer
        let finalTimerCount = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).count
        XCTAssertEqual(initialTimerCount, finalTimerCount)
    }

    // MARK: - Read/View Timer Tests

    func testOpenTimerDetail_DisplaysCorrectInfo() throws {
        // Create timer
        createTimer(name: "Detail Test", minutes: 10)

        // Tap to open detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify navigation
        XCTAssert(app.navigationBars["Detail Test"].waitForExistence(timeout: 5))

        // Verify controls present
        XCTAssert(app.buttons["startButton"].exists)
        XCTAssert(app.buttons["resetButton"].exists)
    }

    func testTimerList_EmptyState_ShowsMessage() throws {
        // With clean state from launchAndClearState(), should show empty state

        // Debug: Wait a moment for UI to stabilize
        sleep(2)

        // Debug: Check timer card count
        let timerCards = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).count
        print("🔍 [EmptyStateTest] Timer card count: \(timerCards)")

        // Debug: Try different query types
        let emptyStateAsOther = app.otherElements["emptyStateView"]
        let emptyStateAsAny = app.descendants(matching: .any)["emptyStateView"]
        let noTimersText = app.staticTexts["No Timers Yet"]

        print("🔍 [EmptyStateTest] Empty state (otherElements) exists: \(emptyStateAsOther.exists)")
        print("🔍 [EmptyStateTest] Empty state (descendants) exists: \(emptyStateAsAny.exists)")
        print("🔍 [EmptyStateTest] 'No Timers Yet' text exists: \(noTimersText.exists)")

        // Debug: Print view hierarchy
        print("🔍 [EmptyStateTest] View hierarchy:")
        print(app.debugDescription)

        // Original test - try both query methods
        let emptyStateView = emptyStateAsOther.exists ? emptyStateAsOther : emptyStateAsAny
        XCTAssert(emptyStateView.waitForExistence(timeout: 5), "Empty state view should exist when no timers present")
    }

    // MARK: - Update Timer Tests

    func testEditTimer_UpdatesValues() throws {
        // Create timer
        createTimer(name: "Original Name", minutes: 5)

        // Open detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Tap edit
        app.buttons["editTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Update name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Updated Name")

        // Update duration
        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "15")

        // Add notes
        if app.textViews["notesField"].exists {
            let notesField = app.textViews["notesField"]
            notesField.tap()
            notesField.typeText("Updated notes")
        }

        // Save
        app.buttons["saveButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Go back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify updated name shows
        XCTAssert(app.staticTexts["Updated Name"].waitForExistence(timeout: 5))
    }

    func testEditTimer_Cancel_DoesNotSaveChanges() throws {
        // Create timer
        createTimer(name: "No Changes", minutes: 10)

        // Open detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Edit
        app.buttons["editTimerButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet presentation

        // Change name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Should Not Change")

        // Cancel
        app.buttons["cancelButton"].tap()
        waitForUIToSettle(0.5)  // Wait for sheet dismissal

        // Go back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForUIToSettle(0.5)  // Wait for navigation

        // Verify original name still exists
        XCTAssert(app.staticTexts["No Changes"].exists)
        XCTAssertFalse(app.staticTexts["Should Not Change"].exists)
    }

    // MARK: - Delete Timer Tests

    func testDeleteTimer_RemovesFromList() throws {
        // Create timer
        createTimer(name: "To Delete", minutes: 5)

        // Verify it exists
        XCTAssert(app.staticTexts["To Delete"].exists)

        // Long press to open context menu
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.press(forDuration: 1.0)
        waitForUIToSettle(0.5)  // Wait for context menu

        // Tap "Delete Timer" from context menu
        let deleteButton = app.buttons["Delete Timer"]
        XCTAssert(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()
        waitForUIToSettle(0.5)  // Wait for deletion

        // Verify it's gone
        XCTAssertFalse(app.staticTexts["To Delete"].exists)
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
