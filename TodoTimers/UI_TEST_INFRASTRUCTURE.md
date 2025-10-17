# UI Test Infrastructure

## Overview

This document describes the UI test infrastructure built for the TodoTimers app, including accessibility identifiers, test helpers, and state management.

## Accessibility Identifiers

All UI elements have been tagged with accessibility identifiers for reliable test automation.

### Timer List View
- `addTimerButton` - Plus button in top-right toolbar
- `emptyStateView` - Empty state view when no timers exist
- `timerCard-{UUID}` - Each timer card (unique per timer)

### Create/Edit Timer View
- `timerNameField` - TextField for timer name
- `hoursPicker` - Hours picker wheel
- `minutesPicker` - Minutes picker wheel
- `secondsPicker` - Seconds picker wheel
- `notesField` - TextEditor for notes (EditTimerView only)
- `cancelButton` - Cancel button
- `doneButton` / `saveButton` - Done/Save button

### Timer Detail View
- `editTimerButton` - Edit button in top-right toolbar
- `startButton` - Start timer button
- `pauseButton` - Pause timer button (when running)
- `resumeButton` - Resume timer button (when paused)
- `resetButton` - Reset timer button
- `addTodoButton` - Plus button to add todo

### Todo Management
- `todoTextField` - TextField for todo text
- `cancelTodoButton` - Cancel button in AddTodoView
- `addTodoConfirmButton` - Add button in AddTodoView
- `todoRow-{UUID}` - Entire todo row
- `todoCheckbox-{UUID}` - Todo completion checkbox
- `todoText-{UUID}` - Todo text label

### Component Views
- `icon-{name}` - Icon selection buttons (e.g., `icon-timer`)
- `color-{hex}` - Color selection buttons (e.g., `color-#007AFF`)

## Test State Management

### UITestsHelpers (Main App)

Location: `TodoTimers/Helpers/UITestsHelpers.swift`

Provides automatic state reset when running UI tests:

```swift
struct UITestsHelpers {
    static var isUITesting: Bool  // Detects --uitesting launch arg
    static func resetAppState(modelContext: ModelContext)
}
```

State reset includes:
- SwiftData model deletion (all timers and todos)
- UserDefaults reset
- Timer services cleanup

Integration: Called automatically in `TodoTimersApp.init()` when `--uitesting` launch argument is present.

### XCUIElement Extensions (UI Tests)

Location: `TodoTimersUITests/TestHelpers/XCUIElementExtensions.swift`

Provides test utilities and helper methods:

#### XCUIApplication Extensions
```swift
app.launchAndClearState()  // Launches with --uitesting flag and resets state
```

#### XCUIElement Extensions
```swift
element.waitForExistence(timeout: 5)  // Wait for element to appear
element.tapIfExists()  // Tap if element exists
element.clearText()  // Clear text from field
element.clearAndType("text")  // Clear and type new text
element.scrollToElement()  // Scroll to make element visible
```

## Writing UI Tests

### Basic Test Template

```swift
import XCTest

final class MyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchAndClearState()  // Clean state
    }

    func testCreateTimer() {
        // Tap add button
        app.buttons["addTimerButton"].tap()

        // Enter timer name
        let nameField = app.textFields["timerNameField"]
        XCTAssert(nameField.waitForExistence(timeout: 5))
        nameField.clearAndType("Workout Timer")

        // Tap done
        app.buttons["doneButton"].tap()

        // Verify timer appears
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
    }

    func testAddTodo() {
        // Create timer first
        app.buttons["addTimerButton"].tap()
        let nameField = app.textFields["timerNameField"]
        nameField.waitForExistence(timeout: 5)
        nameField.clearAndType("Test Timer")
        app.buttons["doneButton"].tap()

        // Tap timer to open detail
        let timerCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
        ).firstMatch
        XCTAssert(timerCard.waitForExistence(timeout: 5))
        timerCard.tap()

        // Add todo
        app.buttons["addTodoButton"].tap()
        let todoField = app.textFields["todoTextField"]
        XCTAssert(todoField.waitForExistence(timeout: 5))
        todoField.clearAndType("Buy groceries")
        app.buttons["addTodoConfirmButton"].tap()

        // Verify todo appears
        let todoRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'todoRow-'")
        ).firstMatch
        XCTAssert(todoRow.waitForExistence(timeout: 5))
    }
}
```

### Best Practices

1. **Always use `launchAndClearState()`** - Ensures clean state
2. **Use accessibility identifiers** - More reliable than text or image matching
3. **Use helper extensions** - `waitForExistence()`, `tapIfExists()`, `clearAndType()` instead of manual operations
4. **Avoid hardcoded waits** - Use `waitForExistence()` instead of `sleep()`
5. **Test one thing per test** - Focused, maintainable tests
6. **Use descriptive test names** - `testCreateTimer_WithValidName_ShowsInList`

### Common Patterns

#### Finding Dynamic Elements
```swift
// Find timer by partial ID match
let timerCard = app.buttons.matching(
    NSPredicate(format: "identifier BEGINSWITH 'timerCard-'")
).firstMatch

// Find specific timer by full ID (if known)
let timerId = UUID(uuidString: "...")!
let timerCard = app.buttons["timerCard-\(timerId)"]
```

#### Testing Timer Controls
```swift
// Start timer
app.buttons["startButton"].tapAfterWaiting()

// Verify button changed to pause
XCTAssert(app.buttons["pauseButton"].waitForExistence(timeout: 2))

// Pause timer
app.buttons["pauseButton"].tap()

// Verify button changed to resume
XCTAssert(app.buttons["resumeButton"].waitForExistence(timeout: 2))
```

#### Testing Todo Completion
```swift
// Find first todo checkbox
let checkbox = app.buttons.matching(
    NSPredicate(format: "identifier BEGINSWITH 'todoCheckbox-'")
).firstMatch

// Toggle completion
checkbox.tapAfterWaiting()

// Verify state changed (implementation-specific)
```

## Running Tests

### Command Line
```bash
# Run all unit tests
xcodebuild test \
  -project TodoTimers.xcodeproj \
  -scheme TodoTimers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TodoTimersTests

# Run all UI tests
xcodebuild test \
  -project TodoTimers.xcodeproj \
  -scheme TodoTimers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TodoTimersUITests

# Run specific test
xcodebuild test \
  -project TodoTimers.xcodeproj \
  -scheme TodoTimers \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TodoTimersUITests/MyUITests/testCreateTimer
```

### Xcode
1. Open TodoTimers.xcodeproj
2. Select target simulator (⌘+Shift+<)
3. Open Test Navigator (⌘+6)
4. Run tests (⌘+U)

## Troubleshooting

### Tests Failing Due to State
- Ensure `app.launchForTesting()` is called in `setUp()`
- Verify `--uitesting` launch argument is set
- Check that state reset code runs (look for console logs)

### Elements Not Found
- Verify accessibility identifier is correct
- Use Xcode's Accessibility Inspector
- Check element exists before interaction: `element.waitForExistence()`
- Use `po app.debugDescription` in LLDB to see UI hierarchy

### Timing Issues
- Increase timeout values if needed: `element.waitForExistence(timeout: 10)`
- Use `waitFor()` helper for complex conditions
- Avoid `sleep()` - use proper waiting mechanisms

### Simulator Issues
- Reset simulator: Device → Erase All Content and Settings
- Quit Simulator and restart
- Clean build folder: Product → Clean Build Folder (⌘+Shift+K)

## Future Enhancements

Potential improvements to consider:

1. **Page Object Pattern** - Create page objects for each screen
2. **Screenshot on Failure** - Automatically capture screenshots when tests fail
3. **Test Recordings** - Record test runs for debugging
4. **Parallel Testing** - Run tests in parallel for faster execution
5. **Custom Matchers** - Create custom XCTest assertions
6. **Test Coverage** - Track code coverage for UI paths
7. **CI Integration** - Automate tests in CI/CD pipeline

## References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [Accessibility for iOS](https://developer.apple.com/accessibility/ios/)
