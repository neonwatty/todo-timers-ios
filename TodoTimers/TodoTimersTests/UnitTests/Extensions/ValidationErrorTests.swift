import Testing
import Foundation
@testable import TodoTimers

/// Tests for ValidationError and TodoValidationError
/// Pure value tests - no dependencies
@Suite("ValidationError Tests")
struct ValidationErrorTests {

    // MARK: - ValidationError Description Tests

    @Test("Empty name error has correct description")
    func emptyName_HasCorrectDescription() {
        let error = ValidationError.emptyName

        #expect(error.errorDescription == "Timer name cannot be empty")
    }

    @Test("Invalid duration error has correct description")
    func invalidDuration_HasCorrectDescription() {
        let error = ValidationError.invalidDuration

        #expect(error.errorDescription == "Duration must be greater than 0")
    }

    @Test("Duration too long error has correct description")
    func durationTooLong_HasCorrectDescription() {
        let error = ValidationError.durationTooLong

        #expect(error.errorDescription == "Duration cannot exceed 24 hours")
    }

    // MARK: - ValidationError LocalizedError Conformance

    @Test("ValidationError conforms to LocalizedError")
    func validationError_ConformsToLocalizedError() {
        let error: LocalizedError = ValidationError.emptyName

        // Verify it can be used as LocalizedError
        #expect(error.errorDescription != nil)
    }

    @Test("ValidationError can be thrown and caught")
    func validationError_CanBeThrown() throws {
        func validateTimer(name: String) throws {
            if name.isEmpty {
                throw ValidationError.emptyName
            }
        }

        // Should throw
        #expect(throws: ValidationError.self) {
            try validateTimer(name: "")
        }

        // Should not throw
        #expect(throws: Never.self) {
            try validateTimer(name: "Valid Name")
        }
    }

    // MARK: - TodoValidationError Description Tests

    @Test("Empty text error has correct description")
    func emptyText_HasCorrectDescription() {
        let error = TodoValidationError.emptyText

        #expect(error.errorDescription == "To-do text cannot be empty")
    }

    // MARK: - TodoValidationError LocalizedError Conformance

    @Test("TodoValidationError conforms to LocalizedError")
    func todoValidationError_ConformsToLocalizedError() {
        let error: LocalizedError = TodoValidationError.emptyText

        // Verify it can be used as LocalizedError
        #expect(error.errorDescription != nil)
    }

    @Test("TodoValidationError can be thrown and caught")
    func todoValidationError_CanBeThrown() throws {
        func validateTodo(text: String) throws {
            if text.isEmpty {
                throw TodoValidationError.emptyText
            }
        }

        // Should throw
        #expect(throws: TodoValidationError.self) {
            try validateTodo(text: "")
        }

        // Should not throw
        #expect(throws: Never.self) {
            try validateTodo(text: "Valid Text")
        }
    }

    // MARK: - Error Equality Tests

    @Test("ValidationError cases are equatable")
    func validationError_IsEquatable() {
        let error1 = ValidationError.emptyName
        let error2 = ValidationError.emptyName
        let error3 = ValidationError.invalidDuration

        // Swift enums with no associated values are automatically Equatable
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("TodoValidationError cases are equatable")
    func todoValidationError_IsEquatable() {
        let error1 = TodoValidationError.emptyText
        let error2 = TodoValidationError.emptyText

        // Swift enums with no associated values are automatically Equatable
        #expect(error1 == error2)
    }

    // MARK: - Error Switch Exhaustiveness Tests

    @Test("ValidationError switch is exhaustive")
    func validationError_SwitchIsExhaustive() {
        // Verify all cases have error descriptions
        let errors: [ValidationError] = [.emptyName, .invalidDuration, .durationTooLong]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.isEmpty == false)
        }
    }

    @Test("TodoValidationError switch is exhaustive")
    func todoValidationError_SwitchIsExhaustive() {
        // Verify all cases have error descriptions
        let errors: [TodoValidationError] = [.emptyText]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description!.isEmpty == false)
        }
    }
}

// MARK: - Test Documentation

/// TESTING APPROACH
///
/// ValidationError and TodoValidationError are simple enum-based error types.
/// These tests verify:
///
/// 1. **Error Descriptions**
///    - Each case has appropriate, user-friendly error message
///    - Messages are clear and actionable
///    - No empty or missing descriptions
///
/// 2. **Protocol Conformance**
///    - Conforms to LocalizedError
///    - Can be thrown and caught properly
///    - Works with Swift error handling mechanisms
///
/// 3. **Enum Behavior**
///    - Cases are equatable (automatic for enums without associated values)
///    - Switch statements are exhaustive
///    - No runtime surprises
///
/// COVERAGE:
/// - ✅ All error cases tested
/// - ✅ Error descriptions verified
/// - ✅ LocalizedError conformance
/// - ✅ Throwing/catching behavior
/// - ✅ Enum equality
/// - ✅ Exhaustiveness verification
///
/// No testability issues - these are pure value types with no dependencies.
