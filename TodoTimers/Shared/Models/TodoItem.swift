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

    // Validation
    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func validate() throws {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TodoValidationError.emptyText
        }
    }
}
