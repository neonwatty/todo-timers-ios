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

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.timer)
    var todoItems: [TodoItem] = []

    var notes: String?

    // Computed Properties (not persisted)
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
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    // Initializer
    init(
        id: UUID = UUID(),
        name: String,
        durationInSeconds: Int,
        icon: String = "timer",
        colorHex: String = "#007AFF",
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.icon = icon
        self.colorHex = colorHex
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Timer {
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        durationInSeconds > 0 &&
        durationInSeconds <= 86400  // Max 24 hours
    }

    func validate() throws {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ValidationError.emptyName
        }
        if durationInSeconds <= 0 {
            throw ValidationError.invalidDuration
        }
        if durationInSeconds > 86400 {
            throw ValidationError.durationTooLong
        }
    }
}

// MARK: - Sample Data

extension Timer {
    static var sampleData: [Timer] {
        [
            Timer(
                name: "Workout",
                durationInSeconds: 1500,  // 25 min
                icon: "figure.run",
                colorHex: "#FF3B30",
                notes: "Remember to hydrate!"
            ),
            Timer(
                name: "Study Session",
                durationInSeconds: 2700,  // 45 min
                icon: "book.fill",
                colorHex: "#007AFF"
            ),
            Timer(
                name: "Coffee Break",
                durationInSeconds: 600,  // 10 min
                icon: "cup.and.saucer.fill",
                colorHex: "#8E8E93"
            ),
            Timer(
                name: "Meditation",
                durationInSeconds: 1200,  // 20 min
                icon: "sparkles",
                colorHex: "#5856D6",
                notes: "Focus on breathing"
            )
        ]
    }
}
