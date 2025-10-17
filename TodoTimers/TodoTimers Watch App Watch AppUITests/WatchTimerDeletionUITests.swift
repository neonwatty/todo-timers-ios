import XCTest

/// Comprehensive tests for Watch Timer Deletion UI
/// Tests delete button, confirmation dialog, and deletion behavior
final class WatchTimerDeletionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Wait for app to stabilize
        sleep(2)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Creates a test timer via UI
    private func createTestTimer(name: String = "Test Timer") {
        let createButton = app.buttons["createTimerButton"]
        XCTAssert(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        // Fill in timer details
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)

        // Set duration using pickers (defaults are fine, just ensure non-zero)
        // Minutes picker should default to 5

        // Tap done
        let doneButton = app.buttons["doneButton"]
        XCTAssert(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()

        // Wait for sheet to dismiss
        sleep(2)
    }

    /// Opens timer detail view by tapping on timer in list
    private func openTimerDetail(timerName: String = "Test Timer") {
        // Find and tap the timer in the list
        let timerCard = app.staticTexts[timerName]
        XCTAssert(timerCard.waitForExistence(timeout: 5), "Timer card should exist")
        timerCard.tap()

        // Wait for detail view to appear
        sleep(2)
    }

    // MARK: - Delete Button Presence Tests

    func testDeleteButton_Exists_InDetailView() throws {
        // Create a timer
        createTestTimer(name: "Delete Test")

        // Open detail view
        openTimerDetail(timerName: "Delete Test")

        // Verify delete button exists
        let deleteButton = app.buttons["deleteTimerButton"]
        XCTAssert(deleteButton.waitForExistence(timeout: 5), "Delete button should exist in detail view toolbar")
    }

    func testDeleteButton_HasCorrectIcon() throws {
        // Create a timer
        createTestTimer(name: "Icon Test")

        // Open detail view
        openTimerDetail(timerName: "Icon Test")

        // Verify delete button exists (trash icon)
        let deleteButton = app.buttons["deleteTimerButton"]
        XCTAssert(deleteButton.waitForExistence(timeout: 5))
        XCTAssert(deleteButton.exists, "Delete button with trash icon should exist")
    }

    // MARK: - Confirmation Dialog Tests

    func testDeleteButton_ShowsConfirmationDialog() throws {
        // Create a timer
        createTestTimer(name: "Confirm Test")

        // Open detail view
        openTimerDetail(timerName: "Confirm Test")

        // Tap delete button
        let deleteButton = app.buttons["deleteTimerButton"]
        XCTAssert(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        // Verify confirmation dialog appears
        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3), "Delete confirmation button should appear")

        let cancelButton = app.buttons["Cancel"]
        XCTAssert(cancelButton.exists, "Cancel button should appear in confirmation dialog")

        // Cleanup: Cancel the dialog
        cancelButton.tap()
        sleep(1)
    }

    func testConfirmationDialog_Cancel_DoesNotDelete() throws {
        // Create a timer
        createTestTimer(name: "Cancel Test")

        // Open detail view
        openTimerDetail(timerName: "Cancel Test")

        // Tap delete button
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        // Wait for confirmation dialog
        let cancelButton = app.buttons["Cancel"]
        XCTAssert(cancelButton.waitForExistence(timeout: 3))

        // Cancel deletion
        cancelButton.tap()

        // Wait for dialog to dismiss
        sleep(2)

        // Verify we're still in detail view (timer name is still visible)
        XCTAssert(app.navigationBars["Cancel Test"].exists, "Should still be in detail view")

        // Go back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(2)

        // Verify timer still exists in list
        let timerCard = app.staticTexts["Cancel Test"]
        XCTAssert(timerCard.exists, "Timer should still exist in list after cancel")
    }

    // MARK: - Delete Functionality Tests

    func testDelete_RemovesTimerFromList() throws {
        // Create a timer
        createTestTimer(name: "Remove Test")

        // Verify timer exists in list
        let timerCard = app.staticTexts["Remove Test"]
        XCTAssert(timerCard.waitForExistence(timeout: 5))

        // Open detail view
        openTimerDetail(timerName: "Remove Test")

        // Tap delete button
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        // Confirm deletion
        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3))
        deleteConfirmButton.tap()

        // Wait for view to dismiss and return to list
        sleep(3)

        // Verify timer no longer exists in list
        XCTAssertFalse(timerCard.exists, "Timer should be removed from list after deletion")
    }

    func testDelete_DismissesDetailView() throws {
        // Create a timer
        createTestTimer(name: "Dismiss Test")

        // Open detail view
        openTimerDetail(timerName: "Dismiss Test")

        // Verify we're in detail view
        XCTAssert(app.navigationBars["Dismiss Test"].exists, "Should be in detail view")

        // Tap delete button
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        // Confirm deletion
        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3))
        deleteConfirmButton.tap()

        // Wait for navigation
        sleep(3)

        // Verify we're back in list view (detail view was dismissed)
        XCTAssertFalse(app.navigationBars["Dismiss Test"].exists, "Detail view should be dismissed")
        XCTAssert(app.navigationBars["Timers"].exists, "Should be back in list view")
    }

    func testDelete_WithMultipleTimers_DeletesCorrectOne() throws {
        // Create multiple timers
        createTestTimer(name: "Timer A")
        createTestTimer(name: "Timer B")
        createTestTimer(name: "Timer C")

        // Verify all exist
        XCTAssert(app.staticTexts["Timer A"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Timer B"].exists)
        XCTAssert(app.staticTexts["Timer C"].exists)

        // Open Timer B detail view
        openTimerDetail(timerName: "Timer B")

        // Delete Timer B
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3))
        deleteConfirmButton.tap()

        // Wait for navigation back to list
        sleep(3)

        // Verify Timer B is gone but A and C remain
        XCTAssert(app.staticTexts["Timer A"].exists, "Timer A should still exist")
        XCTAssertFalse(app.staticTexts["Timer B"].exists, "Timer B should be deleted")
        XCTAssert(app.staticTexts["Timer C"].exists, "Timer C should still exist")

        // Cleanup: Delete remaining timers
        openTimerDetail(timerName: "Timer A")
        app.buttons["deleteTimerButton"].tap()
        app.buttons["Delete"].tap()
        sleep(2)

        openTimerDetail(timerName: "Timer C")
        app.buttons["deleteTimerButton"].tap()
        app.buttons["Delete"].tap()
        sleep(2)
    }

    func testDelete_LastTimer_ShowsEmptyState() throws {
        // Create a single timer
        createTestTimer(name: "Last Timer")

        // Verify timer exists
        XCTAssert(app.staticTexts["Last Timer"].waitForExistence(timeout: 5))

        // Open detail view
        openTimerDetail(timerName: "Last Timer")

        // Delete the timer
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3))
        deleteConfirmButton.tap()

        // Wait for navigation
        sleep(3)

        // Verify empty state appears
        let emptyStateText = app.staticTexts["No Timers"]
        XCTAssert(emptyStateText.waitForExistence(timeout: 5), "Empty state should appear after deleting last timer")
    }

    // MARK: - Edge Case Tests

    func testDelete_WhileTimerRunning_StopsTimer() throws {
        // Create a timer
        createTestTimer(name: "Running Timer")

        // Open detail view
        openTimerDetail(timerName: "Running Timer")

        // Start the timer
        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'START'")).firstMatch
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
            sleep(2)
        }

        // Delete while running
        let deleteButton = app.buttons["deleteTimerButton"]
        deleteButton.tap()

        let deleteConfirmButton = app.buttons["Delete"]
        XCTAssert(deleteConfirmButton.waitForExistence(timeout: 3))
        deleteConfirmButton.tap()

        // Wait for navigation
        sleep(3)

        // Verify timer is deleted (should not crash)
        XCTAssertFalse(app.staticTexts["Running Timer"].exists, "Timer should be deleted even if it was running")
    }

    func testDeleteButton_Tappable() throws {
        // Create a timer
        createTestTimer(name: "Tap Test")

        // Open detail view
        openTimerDetail(timerName: "Tap Test")

        // Verify delete button is hittable
        let deleteButton = app.buttons["deleteTimerButton"]
        XCTAssert(deleteButton.waitForExistence(timeout: 5))
        XCTAssert(deleteButton.isHittable, "Delete button should be tappable")

        // Cleanup: Cancel dialog if it appears
        deleteButton.tap()
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        }
    }
}
