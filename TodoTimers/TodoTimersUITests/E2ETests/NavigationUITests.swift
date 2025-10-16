import XCTest

final class NavigationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - List to Detail Navigation

    func testListToDetail_TapTimer_OpensDetail() throws {
        // Create a timer first
        createTestTimer(name: "Navigation Test")

        // Tap on timer to navigate to detail
        app.staticTexts["Navigation Test"].tap()

        // Verify navigation bar shows timer name
        let navBar = app.navigationBars["Navigation Test"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 2))

        // Verify detail view elements exist
        XCTAssertTrue(app.buttons["Start"].exists)
    }

    func testDetailToList_BackButton_ReturnsToList() throws {
        // Create and open a timer
        createTestTimer(name: "Back Test")
        app.staticTexts["Back Test"].tap()

        // Verify we're in detail view
        XCTAssertTrue(app.navigationBars["Back Test"].exists)

        // Tap back button
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Verify we're back on list view
        let listNavBar = app.navigationBars["My Timers"]
        XCTAssertTrue(listNavBar.waitForExistence(timeout: 2))
    }

    // MARK: - Create Timer Sheet

    func testCreateTimerSheet_Opens_Dismisses() throws {
        // Tap + button to open create timer sheet
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Verify sheet opened (nav bar shows "New Timer")
        let sheetNavBar = app.navigationBars["New Timer"]
        XCTAssertTrue(sheetNavBar.waitForExistence(timeout: 2))

        // Tap Cancel to dismiss
        app.navigationBars.buttons["Cancel"].tap()

        // Verify sheet dismissed (back to "My Timers")
        let listNavBar = app.navigationBars["My Timers"]
        XCTAssertTrue(listNavBar.waitForExistence(timeout: 2))
    }

    func testCreateTimerSheet_Cancel_DismissesWithoutSaving() throws {
        // Count initial timers
        let initialCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Timer'")).count

        // Open sheet, enter data, then cancel
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText("Should Not Save")

        app.navigationBars.buttons["Cancel"].tap()

        // Verify no new timer added
        let finalCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Timer'")).count
        XCTAssertEqual(initialCount, finalCount)
    }

    // MARK: - Add Todo Sheet

    func testAddTodoSheet_Opens_Dismisses() throws {
        // Create timer and open detail
        createTestTimer(name: "Todo Sheet Test")
        app.staticTexts["Todo Sheet Test"].tap()

        // Tap + button to add todo
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus.circle'")).element
        addButton.tap()

        // Verify sheet opened
        let sheetNavBar = app.navigationBars["Add To-Do"]
        XCTAssertTrue(sheetNavBar.waitForExistence(timeout: 2))

        // Tap Cancel
        app.navigationBars.buttons["Cancel"].tap()

        // Verify sheet dismissed (back to timer detail)
        XCTAssertTrue(app.navigationBars["Todo Sheet Test"].exists)
    }

    func testAddTodoSheet_Cancel_DismissesWithoutSaving() throws {
        // Create timer and open detail
        createTestTimer(name: "Cancel Todo Test")
        app.staticTexts["Cancel Todo Test"].tap()

        // Count initial todos (should be 0)
        let initialTodoCount = app.staticTexts.matching(NSPredicate(format: "label != 'To-Do Items' AND label != 'No to-dos yet'")).count

        // Open sheet, enter text, then cancel
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus.circle'")).element
        addButton.tap()

        let textField = app.textFields["Enter to-do text"]
        textField.tap()
        textField.typeText("Should Not Save")

        app.navigationBars.buttons["Cancel"].tap()

        // Verify no todo added
        let finalTodoCount = app.staticTexts.matching(NSPredicate(format: "label != 'To-Do Items' AND label != 'No to-dos yet'")).count
        XCTAssertEqual(initialTodoCount, finalTodoCount)
    }

    // MARK: - Deep Navigation Flow

    func testFullNavigationFlow_ListToDetailToSheetAndBack() throws {
        // Start at list
        XCTAssertTrue(app.navigationBars["My Timers"].exists)

        // Create timer
        createTestTimer(name: "Full Flow Test")

        // Navigate to detail
        app.staticTexts["Full Flow Test"].tap()
        XCTAssertTrue(app.navigationBars["Full Flow Test"].exists)

        // Open add todo sheet
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus.circle'")).element
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add To-Do"].exists)

        // Add a todo
        let textField = app.textFields["Enter to-do text"]
        textField.tap()
        textField.typeText("Complete flow")
        app.navigationBars.buttons["Add"].tap()

        // Verify back at detail
        XCTAssertTrue(app.navigationBars["Full Flow Test"].exists)

        // Go back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["My Timers"].exists)
    }

    // MARK: - Sheet Behavior

    func testMultipleSheetDismissals_WorkCorrectly() throws {
        // Open and dismiss create timer sheet multiple times
        for _ in 1...3 {
            app.navigationBars.buttons.matching(identifier: "plus").element.tap()
            XCTAssertTrue(app.navigationBars["New Timer"].waitForExistence(timeout: 2))

            app.navigationBars.buttons["Cancel"].tap()
            XCTAssertTrue(app.navigationBars["My Timers"].waitForExistence(timeout: 2))
        }

        // Verify we're still on the list view
        XCTAssertTrue(app.navigationBars["My Timers"].exists)
    }

    func testNavigationStack_BackFromMultipleLevels() throws {
        // Create timer
        createTestTimer(name: "Stack Test")

        // Navigate to detail
        app.staticTexts["Stack Test"].tap()

        // Add a todo (goes into sheet, then back to detail)
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus.circle'")).element
        addButton.tap()

        let textField = app.textFields["Enter to-do text"]
        textField.tap()
        textField.typeText("Test Todo")
        app.navigationBars.buttons["Add"].tap()

        // Now back to list
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Verify we're at the root
        XCTAssertTrue(app.navigationBars["My Timers"].exists)
    }

    // MARK: - Helper Methods

    /// Creates a test timer with given parameters
    private func createTestTimer(name: String, minutes: Int = 10) {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let nameField = app.textFields["Enter timer name"]
        nameField.tap()
        nameField.typeText(name)

        let minutesPicker = app.pickerWheels.element(boundBy: 1)
        minutesPicker.adjust(toPickerWheelValue: String(minutes))

        app.navigationBars.buttons["Done"].tap()
    }
}
