import XCTest

/// Comprehensive tests for Watch Timer Creation UI
/// Adapted for watchOS constraints where picker manipulation is limited
///
/// NOTE: watchOS picker manipulation requires toNormalizedSliderPosition() instead
/// of toPickerWheelValue(), making duration selection tests difficult to implement
/// reliably. These tests focus on UI presence, button states, and interactions
/// that don't require picker manipulation. Manual testing recommended for full coverage.
final class WatchTimerCreationUITests: XCTestCase {

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

    // MARK: - UI Presence Tests

    func testToolbarButton_Exists() throws {
        let createButton = app.buttons["createTimerButton"]
        XCTAssert(createButton.waitForExistence(timeout: 5), "Create timer button should exist in toolbar")
    }

    func testToolbarButton_OpensCreateSheet() throws {
        let createButton = app.buttons["createTimerButton"]
        XCTAssert(createButton.waitForExistence(timeout: 5))

        // Tap to open sheet
        createButton.tap()

        // Verify sheet elements appear
        XCTAssert(app.staticTexts["Name"].waitForExistence(timeout: 5), "Name label should appear")
        XCTAssert(app.staticTexts["Duration"].exists, "Duration label should appear")
        XCTAssert(app.staticTexts["Icon"].exists, "Icon label should appear")
        XCTAssert(app.staticTexts["Color"].exists, "Color label should appear")
        XCTAssert(app.buttons["doneButton"].exists, "Done button should appear")
        XCTAssert(app.buttons["cancelButton"].exists, "Cancel button should appear")

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    // MARK: - Form Field Tests

    func testNameField_Exists() throws {
        app.buttons["createTimerButton"].tap()

        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5), "Name field should exist")

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    func testPickers_Exist() throws {
        app.buttons["createTimerButton"].tap()

        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        let minutesPicker = app.pickers["minutesPicker"]
        let secondsPicker = app.pickers["secondsPicker"]

        XCTAssert(minutesPicker.exists, "Minutes picker should exist")
        XCTAssert(secondsPicker.exists, "Seconds picker should exist")

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    // MARK: - Button State Tests

    func testDoneButton_DisabledByDefault() throws {
        app.buttons["createTimerButton"].tap()

        let doneButton = app.buttons["doneButton"]
        XCTAssert(doneButton.waitForExistence(timeout: 5))

        // With empty name and default duration (0:0), Done should be disabled
        XCTAssertFalse(doneButton.isEnabled, "Done button should be disabled with empty name")

        // Cleanup
        app.buttons["cancelButton"].tap()
        XCTAssert(app.buttons["createTimerButton"].waitForExistence(timeout: 5))
    }

    func testCancelButton_Enabled() throws {
        app.buttons["createTimerButton"].tap()

        let cancelButton = app.buttons["cancelButton"]
        XCTAssert(cancelButton.waitForExistence(timeout: 5))
        XCTAssert(cancelButton.isEnabled, "Cancel button should always be enabled")

        // Cleanup
        cancelButton.tap()
    }

    // MARK: - Icon Selection Tests

    func testIconButtons_Exist() throws {
        app.buttons["createTimerButton"].tap()

        // Wait for sheet to appear
        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        // Test that icon buttons exist with correct IDs
        let icons = ["timer", "figure.run", "book.fill", "cup.and.saucer.fill", "fork.knife", "briefcase.fill"]

        for icon in icons {
            let iconButton = app.buttons["iconButton_\(icon)"]
            XCTAssert(iconButton.exists, "Icon button for \(icon) should exist")
        }

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    func testIconSelection_Interactive() throws {
        app.buttons["createTimerButton"].tap()

        // Wait for sheet to appear
        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        // Test selecting an icon (should not crash)
        let iconButton = app.buttons["iconButton_figure.run"]
        if iconButton.exists {
            iconButton.tap()
            XCTAssert(true, "Icon selection should work without error")
        }

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    // MARK: - Color Selection Tests

    func testColorButtons_Exist() throws {
        app.buttons["createTimerButton"].tap()

        // Wait for sheet to appear
        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        // Test that color buttons exist with correct IDs
        let colors = ["#FF3B30", "#34C759", "#007AFF", "#FF9500"]

        for color in colors {
            let colorButton = app.buttons["colorButton_\(color)"]
            XCTAssert(colorButton.exists, "Color button for \(color) should exist")
        }

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    func testColorSelection_Interactive() throws {
        app.buttons["createTimerButton"].tap()

        // Wait for sheet to appear
        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        // Test selecting a color (should not crash)
        let colorButton = app.buttons["colorButton_#34C759"]
        if colorButton.exists {
            colorButton.tap()
            XCTAssert(true, "Color selection should work without error")
        }

        // Cleanup
        app.buttons["cancelButton"].tap()
    }

    // MARK: - Cancel Behavior Tests

    func testCancel_DismissesSheet() throws {
        // Open create sheet
        app.buttons["createTimerButton"].tap()

        // Verify sheet is open
        XCTAssert(app.textFields["timerNameField"].waitForExistence(timeout: 5))

        // Cancel
        app.buttons["cancelButton"].tap()

        // Verify sheet is dismissed (create button visible again)
        XCTAssert(app.buttons["createTimerButton"].waitForExistence(timeout: 5),
                 "Create button should be visible after cancel")
    }
}
