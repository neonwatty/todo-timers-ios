import XCTest

/// UI tests for timer reordering functionality
/// Tests drag-and-drop reordering and persistence of timer order
final class TimerReorderingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Creates a timer with the given name
    private func createTimer(name: String, minutes: Int = 5) {
        app.buttons["addTimerButton"].tap()
        waitForUIToSettle(0.5)

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType(name)

        app.pickers["minutesPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "\(minutes)")

        app.buttons["doneButton"].tap()
        waitForUIToSettle(0.5)
    }

    /// Gets the timer card at the given index
    private func getTimerCard(at index: Int) -> XCUIElement {
        let timerCards = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        )
        return timerCards.element(boundBy: index)
    }

    /// Gets the text of the timer at the given index
    private func getTimerName(at index: Int) -> String? {
        let timerCard = getTimerCard(at: index)
        // The timer name is in a static text within the card
        return timerCard.staticTexts.element(boundBy: 0).label
    }

    // MARK: - Edit Mode Tests

    func testEditButton_TappingEnablesEditMode() throws {
        // Create at least one timer to enable edit button
        createTimer(name: "Timer 1")

        // Tap edit button
        let editButton = app.buttons["editTimersButton"]
        XCTAssert(editButton.waitForExistence(timeout: 5))
        editButton.tap()
        waitForUIToSettle(0.3)

        // Verify done button appears
        let doneButton = app.buttons["doneEditingButton"]
        XCTAssert(doneButton.exists)
    }

    func testDoneButton_TappingDisablesEditMode() throws {
        // Create a timer and enter edit mode
        createTimer(name: "Timer 1")
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.3)

        // Tap done button
        let doneButton = app.buttons["doneEditingButton"]
        XCTAssert(doneButton.exists)
        doneButton.tap()
        waitForUIToSettle(0.3)

        // Verify edit button appears again
        let editButton = app.buttons["editTimersButton"]
        XCTAssert(editButton.exists)
    }

    // MARK: - Reordering Tests

    func testReorderTimers_MoveFirstToLast_OrderChanges() throws {
        // Create three timers
        createTimer(name: "Timer A", minutes: 5)
        createTimer(name: "Timer B", minutes: 10)
        createTimer(name: "Timer C", minutes: 15)
        waitForUIToSettle(0.5)

        // Verify initial order (newest first due to creation)
        XCTAssertEqual(getTimerName(at: 0), "Timer C")
        XCTAssertEqual(getTimerName(at: 1), "Timer B")
        XCTAssertEqual(getTimerName(at: 2), "Timer A")

        // Enter edit mode
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.5)

        // Move first timer (Timer C) to last position
        let firstTimer = getTimerCard(at: 0)
        let lastTimer = getTimerCard(at: 2)

        // Perform drag operation
        firstTimer.press(forDuration: 0.5, thenDragTo: lastTimer)
        waitForUIToSettle(0.5)

        // Exit edit mode
        app.buttons["doneEditingButton"].tap()
        waitForUIToSettle(0.3)

        // Verify new order
        XCTAssertEqual(getTimerName(at: 0), "Timer B")
        XCTAssertEqual(getTimerName(at: 1), "Timer A")
        XCTAssertEqual(getTimerName(at: 2), "Timer C")
    }

    func testReorderTimers_MoveMiddleToTop_OrderChanges() throws {
        // Create three timers
        createTimer(name: "Timer 1", minutes: 5)
        createTimer(name: "Timer 2", minutes: 10)
        createTimer(name: "Timer 3", minutes: 15)
        waitForUIToSettle(0.5)

        // Enter edit mode
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.5)

        // Move middle timer to top
        let middleTimer = getTimerCard(at: 1)
        let topTimer = getTimerCard(at: 0)

        middleTimer.press(forDuration: 0.5, thenDragTo: topTimer)
        waitForUIToSettle(0.5)

        // Exit edit mode
        app.buttons["doneEditingButton"].tap()
        waitForUIToSettle(0.3)

        // Verify the middle timer is now first
        let firstTimerName = getTimerName(at: 0)
        XCTAssertEqual(firstTimerName, "Timer 2")
    }

    func testReorderTimers_OrderPersistsAfterRestart() throws {
        // Create two timers
        createTimer(name: "First Timer", minutes: 5)
        createTimer(name: "Second Timer", minutes: 10)
        waitForUIToSettle(0.5)

        // Enter edit mode and reorder
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.5)

        let firstTimer = getTimerCard(at: 0)
        let secondTimer = getTimerCard(at: 1)
        firstTimer.press(forDuration: 0.5, thenDragTo: secondTimer)
        waitForUIToSettle(0.5)

        app.buttons["doneEditingButton"].tap()
        waitForUIToSettle(0.3)

        // Capture order before restart
        let orderBeforeRestart = [getTimerName(at: 0), getTimerName(at: 1)]

        // Restart app (simulates app termination and relaunch)
        app.terminate()
        app.launch()
        waitForUIToSettle(1.0)

        // Verify order persists
        let orderAfterRestart = [getTimerName(at: 0), getTimerName(at: 1)]
        XCTAssertEqual(orderBeforeRestart, orderAfterRestart)
    }

    // MARK: - Edge Cases

    func testReorderTimers_WithSingleTimer_NoChangesPossible() throws {
        // Create one timer
        createTimer(name: "Only Timer", minutes: 5)
        waitForUIToSettle(0.5)

        // Enter edit mode
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.5)

        // Verify timer name remains the same
        let timerName = getTimerName(at: 0)
        XCTAssertEqual(timerName, "Only Timer")

        // Exit edit mode
        app.buttons["doneEditingButton"].tap()
        waitForUIToSettle(0.3)

        // Verify timer is still there
        XCTAssertEqual(getTimerName(at: 0), "Only Timer")
    }

    func testReorderTimers_NewTimerAppearsAtEnd() throws {
        // Create two timers
        createTimer(name: "Timer A", minutes: 5)
        createTimer(name: "Timer B", minutes: 10)
        waitForUIToSettle(0.5)

        // Reorder them
        app.buttons["editTimersButton"].tap()
        waitForUIToSettle(0.5)

        let firstTimer = getTimerCard(at: 0)
        let secondTimer = getTimerCard(at: 1)
        firstTimer.press(forDuration: 0.5, thenDragTo: secondTimer)
        waitForUIToSettle(0.5)

        app.buttons["doneEditingButton"].tap()
        waitForUIToSettle(0.3)

        // Create a new timer
        createTimer(name: "Timer C", minutes: 15)
        waitForUIToSettle(0.5)

        // Verify new timer appears at the end
        let lastTimerName = getTimerName(at: 2)
        XCTAssertEqual(lastTimerName, "Timer C")
    }
}
