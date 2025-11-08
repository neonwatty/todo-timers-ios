import SwiftData
import Foundation

@Model
final class Timer {
    // Identifiers
    @Attribute(.unique) var id: UUID

    // Timer Properties
    var name: String
    var durationInSeconds: Int  // Total duration
    var icon: String            // SF Symbol name
    var colorHex: String        // Hex color code for UI
    var sortOrder: Int          // For custom ordering

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.timer)
    var todoItems: [TodoItem] = []

    var notes: String?

    // Computed Properties
    var hours: Int {
        durationInSeconds / 3600
    }

    var minutes: Int {
        (durationInSeconds % 3600) / 60
    }

    var seconds: Int {
        durationInSeconds % 60
    }

    var formattedDuration: String {
        let h = hours
        let m = minutes
        let s = seconds

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        durationInSeconds: Int,
        icon: String = "timer",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Validation
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && durationInSeconds > 0
    }

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        guard durationInSeconds > 0 else {
            throw ValidationError.invalidDuration
        }
    }
}
