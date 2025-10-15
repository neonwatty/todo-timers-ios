import Foundation

// MARK: - Timer Validation Errors

enum ValidationError: LocalizedError {
    case emptyName
    case invalidDuration
    case durationTooLong

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Timer name cannot be empty"
        case .invalidDuration:
            return "Duration must be greater than 0"
        case .durationTooLong:
            return "Duration cannot exceed 24 hours"
        }
    }
}

// MARK: - TodoItem Validation Errors

enum TodoValidationError: LocalizedError {
    case emptyText

    var errorDescription: String? {
        "To-do text cannot be empty"
    }
}
