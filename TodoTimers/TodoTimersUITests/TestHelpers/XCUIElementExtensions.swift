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

    /// Wait until element is hittable (exists AND can be interacted with)
    /// - Parameter timeout: Maximum wait time in seconds
    /// - Returns: true if element became hittable within timeout, false otherwise
    @discardableResult
    func waitUntilHittable(timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Tap with retry logic for flaky UI
    /// - Parameters:
    ///   - maxAttempts: Maximum number of tap attempts
    ///   - waitBetween: Time to wait between attempts
    func tapWithRetry(maxAttempts: Int = 3, waitBetween: TimeInterval = 0.5) {
        for attempt in 1...maxAttempts {
            if waitUntilHittable(timeout: 5) {
                tap()
                return
            }
            if attempt < maxAttempts {
                Thread.sleep(forTimeInterval: waitBetween)
            }
        }
        XCTFail("Failed to tap element after \(maxAttempts) attempts")
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

/// Helper extensions for XCTestCase
extension XCTestCase {
    /// Wait for UI to settle after animations and state changes
    /// - Parameter duration: Time to wait in seconds (default 1.0)
    /// - Note: Use this after navigation, sheet dismissal, or state changes to allow SwiftUI to complete rendering
    func waitForUIToSettle(_ duration: TimeInterval = 1.0) {
        Thread.sleep(forTimeInterval: duration)
    }
}
