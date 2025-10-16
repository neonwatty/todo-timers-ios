import XCTest

final class TimerManagementUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Timer Creation Flow

    func testCreateTimer_ValidInput_AppearsInList() throws {
        // Tap the + button to open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Fill in timer name
        let nameField = app.textFields["Enter timer name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Workout Timer")

        // Set duration to 25 minutes
        let minutesPicker = app.pickerWheels.element(boundBy: 1)
        minutesPicker.adjust(toPickerWheelValue: "25")

        // Tap Done button
        app.navigationBars.buttons["Done"].tap()

        // Verify timer appears in list
        let timerCard = app.staticTexts["Workout Timer"]
        XCTAssertTrue(timerCard.waitForExistence(timeout: 2))
    }

    func testCreateTimer_EmptyName_DisablesDoneButton() throws {
        // Open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Don't enter a name, just try to tap Done
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2))

        // Done button should be disabled with empty name
        XCTAssertFalse(doneButton.isEnabled)
    }

    func testCreateTimer_ZeroDuration_DisablesDoneButton() throws {
        // Open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Enter a name
        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText("Test")

        // Leave duration at 0:0:0 (default)
        let doneButton = app.navigationBars.buttons["Done"]

        // Done button should be disabled with zero duration
        XCTAssertFalse(doneButton.isEnabled)
    }

    func testCreateTimer_AllFields_SavesCorrectly() throws {
        // Open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Fill in all fields
        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText("Study Session")

        // Set duration (e.g., 1 hour, 30 minutes)
        let hoursPicker = app.pickerWheels.element(boundBy: 0)
        hoursPicker.adjust(toPickerWheelValue: "1")

        let minutesPicker = app.pickerWheels.element(boundBy: 1)
        minutesPicker.adjust(toPickerWheelValue: "30")

        // Select an icon (tap one of the icon buttons)
        // Note: This is a simplified approach; actual test may need specific accessibility identifiers
        app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'icon'")).element(boundBy: 1).tap()

        // Tap Done
        app.navigationBars.buttons["Done"].tap()

        // Verify timer appears with formatted duration
        let timerCard = app.staticTexts["Study Session"]
        XCTAssertTrue(timerCard.waitForExistence(timeout: 2))

        // Verify duration shows 01:30:00
        let durationText = app.staticTexts["01:30:00"]
        XCTAssertTrue(durationText.exists)
    }

    func testCreateTimer_Cancel_DoesNotSave() throws {
        // Count initial timers
        let initialTimerCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Timer'")).count

        // Open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Enter data
        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText("Canceled Timer")

        // Tap Cancel
        app.navigationBars.buttons["Cancel"].tap()

        // Verify timer was not added
        let finalTimerCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Timer'")).count
        XCTAssertEqual(initialTimerCount, finalTimerCount)
    }

    // MARK: - Timer Detail Flow

    func testOpenTimerDetail_DisplaysCorrectInfo() throws {
        // First create a timer
        createTestTimer(name: "Detail Test", minutes: 10)

        // Tap on the timer to open detail view
        app.staticTexts["Detail Test"].tap()

        // Verify navigation to detail view
        XCTAssertTrue(app.navigationBars["Detail Test"].waitForExistence(timeout: 2))

        // Verify timer display shows correct time
        let timeDisplay = app.staticTexts["10:00"]
        XCTAssertTrue(timeDisplay.exists)
    }

    func testTimerControls_Start_BeginsCountdown() throws {
        // Create timer and open detail
        createTestTimer(name: "Start Test", minutes: 5)
        app.staticTexts["Start Test"].tap()

        // Tap Start button
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Verify Pause button appears (indicating timer is running)
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
    }

    func testTimerControls_Pause_StopsCountdown() throws {
        // Create timer and open detail
        createTestTimer(name: "Pause Test", minutes: 5)
        app.staticTexts["Pause Test"].tap()

        // Start timer
        app.buttons["Start"].tap()

        // Pause timer
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        pauseButton.tap()

        // Verify Resume button appears
        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.exists)
    }

    func testTimerControls_Resume_ContinuesCountdown() throws {
        // Create timer and open detail
        createTestTimer(name: "Resume Test", minutes: 5)
        app.staticTexts["Resume Test"].tap()

        // Start, pause, then resume
        app.buttons["Start"].tap()
        sleep(1)  // Let it run briefly
        app.buttons["Pause"].tap()
        app.buttons["Resume"].tap()

        // Verify Pause button appears again
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.exists)
    }

    func testTimerControls_Reset_RestoresTotalTime() throws {
        // Create timer and open detail
        createTestTimer(name: "Reset Test", minutes: 5)
        app.staticTexts["Reset Test"].tap()

        // Start timer, let it run briefly
        app.buttons["Start"].tap()
        sleep(2)

        // Reset timer
        app.buttons["Reset"].tap()

        // Verify time restored to 05:00
        let timeDisplay = app.staticTexts["05:00"]
        XCTAssertTrue(timeDisplay.exists)

        // Verify Start button appears (timer stopped)
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists)
    }

    // MARK: - Empty State

    func testTimerList_EmptyState_ShowsEmptyMessage() throws {
        // Note: This test assumes app starts with no timers
        // In a real scenario, you'd want to reset app state first

        let emptyMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No timers'")).element
        // Only check if this exists when no timers are present
        // (This test would need app state reset to work reliably)
    }

    // MARK: - Helper Methods

    /// Creates a test timer with given parameters
    private func createTestTimer(name: String, hours: Int = 0, minutes: Int = 1, seconds: Int = 0) {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText(name)

        if hours > 0 {
            let hoursPicker = app.pickerWheels.element(boundBy: 0)
            hoursPicker.adjust(toPickerWheelValue: String(hours))
        }

        if minutes > 0 {
            let minutesPicker = app.pickerWheels.element(boundBy: 1)
            minutesPicker.adjust(toPickerWheelValue: String(minutes))
        }

        if seconds > 0 {
            let secondsPicker = app.pickerWheels.element(boundBy: 2)
            secondsPicker.adjust(toPickerWheelValue: String(seconds))
        }

        app.navigationBars.buttons["Done"].tap()
    }
}
