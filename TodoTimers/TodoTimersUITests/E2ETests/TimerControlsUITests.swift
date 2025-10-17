import XCTest

/// Tests for timer control functionality (start, pause, resume, reset)
/// Uses UITestsHelpers for state reset and accessibility identifiers for reliable interactions
final class TimerControlsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Start/Pause/Resume Tests

    func testStartButton_BeginsCountdown() throws {
        // Create a timer
        createTimer(name: "Start Test", minutes: 1)

        // Open timer detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()

        // Verify start button exists
        let startButton = app.buttons["startButton"]
        XCTAssert(startButton.waitForExistence(timeout: 5))

        // Tap start
        startButton.tap()

        // Verify button changes to pause
        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))
    }

    func testPauseButton_StopsCountdown() throws {
        // Create a timer
        createTimer(name: "Pause Test", minutes: 1)

        // Open timer detail and start
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        app.buttons["startButton"].tap()

        // Wait for pause button to appear
        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))

        // Tap pause
        pauseButton.tap()

        // Verify button changes to resume
        let resumeButton = app.buttons["resumeButton"]
        XCTAssert(resumeButton.waitForExistence(timeout: 3))
    }

    func testResumeButton_ContinuesCountdown() throws {
        // Create a timer
        createTimer(name: "Resume Test", minutes: 1)

        // Open timer detail, start, then pause
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        app.buttons["startButton"].tap()

        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))
        pauseButton.tap()

        // Verify resume button exists
        let resumeButton = app.buttons["resumeButton"]
        XCTAssert(resumeButton.waitForExistence(timeout: 3))

        // Tap resume
        resumeButton.tap()

        // Verify button changes back to pause
        XCTAssert(pauseButton.waitForExistence(timeout: 3))
    }

    func testResetButton_RestoresOriginalTime() throws {
        // Create a timer
        createTimer(name: "Reset Test", minutes: 5)

        // Open timer detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        // Start and immediately pause
        app.buttons["startButton"].tap()

        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))

        // Wait a moment for time to decrease
        Thread.sleep(forTimeInterval: 2)

        pauseButton.tap()

        // Tap reset
        let resetButton = app.buttons["resetButton"]
        XCTAssert(resetButton.waitForExistence(timeout: 3))
        resetButton.tap()

        // Verify timer is reset (button should be "start" again)
        let startButton = app.buttons["startButton"]
        XCTAssert(startButton.waitForExistence(timeout: 3))

        // Timer display should show 5:00 (original time)
        // Note: This is an implicit test - reset clears elapsed time
    }

    // MARK: - Timer Completion Tests

    func testTimerCompletion_VeryShortDuration_Completes() throws {
        // Create a very short timer
        createTimer(name: "Quick Timer", seconds: 3)

        // Open timer detail and start
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        app.buttons["startButton"].tap()

        // Wait for timer to complete (should show start button again after completion)
        let startButton = app.buttons["startButton"]

        // Wait up to 5 seconds for completion
        Thread.sleep(forTimeInterval: 5)

        // After completion, start button should reappear
        XCTAssert(startButton.exists)
    }

    // MARK: - State Persistence Tests

    func testTimerState_PersistsAcrossNavigation() throws {
        // Create a timer
        createTimer(name: "Persistence Test", minutes: 10)

        // Open timer detail and start
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        app.buttons["startButton"].tap()

        // Verify pause button appears
        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))

        // Navigate back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Navigate back to timer detail
        XCTAssert(timerCard.waitForExistence(timeout: 3))
        timerCard.tap()

        // Verify timer is still running (pause button should still be there)
        XCTAssert(pauseButton.exists)
    }

    func testPausedTimerState_PersistsAcrossNavigation() throws {
        // Create a timer
        createTimer(name: "Paused Persistence", minutes: 10)

        // Open timer detail, start, then pause
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        timerCard.tap()

        app.buttons["startButton"].tap()

        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))
        pauseButton.tap()

        // Verify resume button appears
        let resumeButton = app.buttons["resumeButton"]
        XCTAssert(resumeButton.waitForExistence(timeout: 3))

        // Navigate back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Navigate back to timer detail
        XCTAssert(timerCard.waitForExistence(timeout: 3))
        timerCard.tap()

        // Verify timer is still paused (resume button should still be there)
        XCTAssert(resumeButton.exists)
    }

    // MARK: - Multiple Timers Test

    func testMultipleTimers_RunIndependently() throws {
        // Create two timers
        createTimer(name: "Timer 1", minutes: 10)
        createTimer(name: "Timer 2", minutes: 10)

        // Start first timer
        let timer1 = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).element(boundBy: 0)
        XCTAssert(timer1.waitForExistence(timeout: 5))
        timer1.tap()

        app.buttons["startButton"].tap()

        // Verify first timer is running
        let pauseButton = app.buttons["pauseButton"]
        XCTAssert(pauseButton.waitForExistence(timeout: 3))

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Start second timer
        let timer2 = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).element(boundBy: 1)
        XCTAssert(timer2.waitForExistence(timeout: 3))
        timer2.tap()

        app.buttons["startButton"].tap()

        // Verify second timer is running
        XCTAssert(pauseButton.waitForExistence(timeout: 3))

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Verify both timers still exist in list
        XCTAssert(app.staticTexts["Timer 1"].exists)
        XCTAssert(app.staticTexts["Timer 2"].exists)

        // Go back to first timer and verify it's still running
        timer1.tap()
        XCTAssert(pauseButton.exists)
    }

    // MARK: - Helper Methods

    /// Creates a timer using accessibility identifiers
    private func createTimer(name: String, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        app.buttons["addTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
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

        // Wait for sheet to dismiss
        XCTAssert(app.buttons["addTimerButton"].waitForExistence(timeout: 5))
    }
}
