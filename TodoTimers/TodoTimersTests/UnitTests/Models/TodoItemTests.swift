import Testing
import Foundation
@testable import TodoTimers

@Suite("TodoItem Model Tests")
struct TodoItemTests {

    // MARK: - Initialization Tests

    @Test("TodoItem initialization with default values")
    func todoItemInitialization_DefaultValues() {
        let todo = TodoItem(text: "Test Todo")

        #expect(todo.text == "Test Todo")
        #expect(todo.isCompleted == false)
        #expect(todo.sortOrder == 0)
        #expect(todo.timer == nil)
    }

    @Test("TodoItem is not completed by default")
    func todoItemInitialization_NotCompletedByDefault() {
        let todo = TodoItem(text: "Test Todo")

        #expect(todo.isCompleted == false)
    }

    @Test("TodoItem initialization with custom values")
    func todoItemInitialization_CustomValues() {
        let todo = TodoItem(
            text: "Custom Todo",
            isCompleted: true,
            sortOrder: 5
        )

        #expect(todo.text == "Custom Todo")
        #expect(todo.isCompleted == true)
        #expect(todo.sortOrder == 5)
    }

    @Test("TodoItem initialization sets timestamps")
    func todoItemInitialization_SetsTimestamps() {
        let before = Date()
        let todo = TodoItem(text: "Test")
        let after = Date()

        #expect(todo.createdAt >= before && todo.createdAt <= after)
        #expect(todo.updatedAt >= before && todo.updatedAt <= after)
    }

    // MARK: - Validation Tests

    @Test("Validation succeeds for valid todo")
    func validate_ValidTodo_DoesNotThrow() throws {
        let todo = TodoItem(text: "Valid Todo")

        try todo.validate()
        #expect(todo.isValid == true)
    }

    @Test("Validation fails for empty text")
    func validate_EmptyText_ThrowsError() {
        let todo = TodoItem(text: "")

        #expect(todo.isValid == false)
        #expect(throws: TodoValidationError.self) {
            try todo.validate()
        }
    }

    @Test("Validation fails for whitespace-only text")
    func validate_WhitespaceText_ThrowsError() {
        let todo = TodoItem(text: "   ")

        #expect(todo.isValid == false)
        #expect(throws: TodoValidationError.self) {
            try todo.validate()
        }
    }

    // MARK: - Behavior Tests

    @Test("isValid returns true for non-empty text")
    func isValid_NonEmptyText_ReturnsTrue() {
        let todo = TodoItem(text: "Valid text")

        #expect(todo.isValid == true)
    }

    @Test("isValid returns false for empty text")
    func isValid_EmptyText_ReturnsFalse() {
        let todo = TodoItem(text: "")

        #expect(todo.isValid == false)
    }

    @Test("isValid returns false for whitespace text")
    func isValid_WhitespaceText_ReturnsFalse() {
        let todo = TodoItem(text: "   ")

        #expect(todo.isValid == false)
    }
}
