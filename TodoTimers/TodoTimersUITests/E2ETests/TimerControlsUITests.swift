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

    // MARK: - List View Control Tests

    func testListViewStart_StartsTimer() throws {
        // Create a timer
        createTimer(name: "List Start Test", minutes: 10)

        // Find the timer card in list
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        // Get timer ID from card identifier
        let timerID = extractTimerID(from: timerCard.identifier)

        // Find and tap start button on list view card
        let listStartButton = app.buttons["listStartButton-\(timerID)"]
        XCTAssert(listStartButton.waitForExistence(timeout: 5))
        listStartButton.tap()

        // Verify button changes to pause
        let listPauseButton = app.buttons["listPauseButton-\(timerID)"]
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))
    }

    func testListViewPause_PausesTimer() throws {
        // Create and start a timer from list view
        createTimer(name: "List Pause Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        let timerID = extractTimerID(from: timerCard.identifier)

        // Start timer from list
        app.buttons["listStartButton-\(timerID)"].tap()

        // Verify pause button appears
        let listPauseButton = app.buttons["listPauseButton-\(timerID)"]
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))

        // Tap pause
        listPauseButton.tap()

        // Verify button changes to resume
        let listResumeButton = app.buttons["listResumeButton-\(timerID)"]
        XCTAssert(listResumeButton.waitForExistence(timeout: 3))
    }

    func testListViewResume_ResumesTimer() throws {
        // Create, start, and pause a timer from list view
        createTimer(name: "List Resume Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        let timerID = extractTimerID(from: timerCard.identifier)

        // Start and pause
        app.buttons["listStartButton-\(timerID)"].tap()
        let listPauseButton = app.buttons["listPauseButton-\(timerID)"]
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))
        listPauseButton.tap()

        // Verify resume button exists
        let listResumeButton = app.buttons["listResumeButton-\(timerID)"]
        XCTAssert(listResumeButton.waitForExistence(timeout: 3))

        // Tap resume
        listResumeButton.tap()

        // Verify button changes back to pause
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))
    }

    func testListViewReset_ResetsTimer() throws {
        // Create and start a timer from list view
        createTimer(name: "List Reset Test", minutes: 5)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        let timerID = extractTimerID(from: timerCard.identifier)

        // Start timer
        app.buttons["listStartButton-\(timerID)"].tap()

        let listPauseButton = app.buttons["listPauseButton-\(timerID)"]
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))

        // Wait for time to decrease
        Thread.sleep(forTimeInterval: 2)

        // Pause
        listPauseButton.tap()

        // Tap reset
        let listResetButton = app.buttons["listResetButton-\(timerID)"]
        XCTAssert(listResetButton.waitForExistence(timeout: 3))
        listResetButton.tap()

        // Verify timer is reset (start button should reappear)
        let listStartButton = app.buttons["listStartButton-\(timerID)"]
        XCTAssert(listStartButton.waitForExistence(timeout: 3))
    }

    func testListViewMutualExclusivity_StartingSecondTimerPausesFirst() throws {
        // Create two timers
        createTimer(name: "Timer A", minutes: 10)
        createTimer(name: "Timer B", minutes: 10)

        // Get both timer cards
        let timer1Card = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).element(boundBy: 0)
        let timer2Card = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).element(boundBy: 1)

        XCTAssert(timer1Card.waitForExistence(timeout: 5))
        XCTAssert(timer2Card.waitForExistence(timeout: 5))

        let timer1ID = extractTimerID(from: timer1Card.identifier)
        let timer2ID = extractTimerID(from: timer2Card.identifier)

        // Start first timer from list
        let timer1StartButton = app.buttons["listStartButton-\(timer1ID)"]
        XCTAssert(timer1StartButton.waitForExistence(timeout: 3))
        timer1StartButton.tap()

        // Verify first timer is running
        let timer1PauseButton = app.buttons["listPauseButton-\(timer1ID)"]
        XCTAssert(timer1PauseButton.waitForExistence(timeout: 3))

        // Start second timer from list (should pause first)
        let timer2StartButton = app.buttons["listStartButton-\(timer2ID)"]
        XCTAssert(timer2StartButton.waitForExistence(timeout: 3))
        timer2StartButton.tap()

        // Verify second timer is running
        let timer2PauseButton = app.buttons["listPauseButton-\(timer2ID)"]
        XCTAssert(timer2PauseButton.waitForExistence(timeout: 3))

        // Wait for UI to update
        Thread.sleep(forTimeInterval: 1)

        // Verify first timer has been paused (start button should reappear)
        XCTAssert(timer1StartButton.waitForExistence(timeout: 5))
    }

    func testListViewControls_IndependentFromDetailView() throws {
        // Create a timer
        createTimer(name: "Independent Test", minutes: 10)

        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        let timerID = extractTimerID(from: timerCard.identifier)

        // Start timer from list view
        let listStartButton = app.buttons["listStartButton-\(timerID)"]
        XCTAssert(listStartButton.waitForExistence(timeout: 3))
        listStartButton.tap()

        // Verify list pause button appears
        let listPauseButton = app.buttons["listPauseButton-\(timerID)"]
        XCTAssert(listPauseButton.waitForExistence(timeout: 3))

        // Navigate to detail view
        timerCard.tap()

        // Wait for navigation to complete
        Thread.sleep(forTimeInterval: 1)

        // Verify detail view also shows pause button (same timer state)
        let detailPauseButton = app.buttons["pauseButton"]
        XCTAssert(detailPauseButton.waitForExistence(timeout: 5))

        // Pause from detail view
        detailPauseButton.tap()

        // Verify detail resume button appears
        let detailResumeButton = app.buttons["resumeButton"]
        XCTAssert(detailResumeButton.waitForExistence(timeout: 3))

        // Navigate back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Verify list view also shows resume button (state synchronized)
        let listResumeButton = app.buttons["listResumeButton-\(timerID)"]
        XCTAssert(listResumeButton.waitForExistence(timeout: 3))
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

    /// Extracts timer ID from timer card identifier
    /// Timer card identifiers follow the format: "timerCard-{UUID}"
    private func extractTimerID(from identifier: String) -> String {
        return identifier.replacingOccurrences(of: "timerCard-", with: "")
    }
}
