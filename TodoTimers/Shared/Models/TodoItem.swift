import SwiftData
import Foundation

@Model
final class TodoItem {
    // Identifiers
    @Attribute(.unique) var id: UUID

    // Properties
    var text: String
    var isCompleted: Bool
    var sortOrder: Int  // For custom ordering

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var timer: Timer?

    // Initializer
    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension TodoItem {
    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func validate() throws {
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            throw TodoValidationError.emptyText
        }
    }
}

// MARK: - Sample Data

extension TodoItem {
    static func sampleData(for timer: Timer) -> [TodoItem] {
        switch timer.name {
        case "Workout":
            return [
                TodoItem(text: "Warm up 5 minutes", sortOrder: 0),
                TodoItem(text: "20 push-ups", sortOrder: 1),
                TodoItem(text: "30 squats", sortOrder: 2),
                TodoItem(text: "Plank 1 minute", sortOrder: 3),
                TodoItem(text: "Cool down stretch", sortOrder: 4)
            ]
        case "Study Session":
            return [
                TodoItem(text: "Review chapter 3", sortOrder: 0),
                TodoItem(text: "Complete practice problems", sortOrder: 1)
            ]
        default:
            return []
        }
    }
}
