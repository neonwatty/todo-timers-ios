import XCTest

/// Helper extensions for XCUIElement to reduce boilerplate in UI tests
extension XCUIElement {
    /// Taps the element if it exists
    /// - Returns: true if the element was tapped, false otherwise
    @discardableResult
    func tapIfExists() -> Bool {
        if exists {
            tap()
            return true
        }
        return false
    }

    /// Waits for the element to exist with a specified timeout
    /// - Parameter timeout: Maximum wait time in seconds (default: 5)
    /// - Returns: true if the element appeared within timeout, false otherwise
    @discardableResult
    func waitForExistence(timeout: TimeInterval = 5) -> Bool {
        return waitForExistence(timeout: timeout)
    }

    /// Clears text from a text field
    func clearText() {
        guard let stringValue = value as? String else {
            return
        }

        tap()

        // Select all text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }

    /// Types text after clearing existing text
    /// - Parameter text: The text to type
    func clearAndType(_ text: String) {
        clearText()
        typeText(text)
    }

    /// Checks if the element is enabled (exists and is enabled)
    var isEnabled: Bool {
        return exists && isEnabled
    }

    /// Scrolls to make the element visible (for elements inside scroll views)
    func scrollToElement() {
        if !isHittable {
            swipeUp()
        }
    }
}

/// Helper extensions for XCUIApplication
extension XCUIApplication {
    /// Launches the app and clears its state
    func launchAndClearState() {
        launchArguments.append("--uitesting")
        launchEnvironment["RESET_STATE"] = "1"
        launch()
    }
}
