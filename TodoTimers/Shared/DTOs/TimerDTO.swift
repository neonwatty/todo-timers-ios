import Foundation

struct TimerDTO: Codable {
    let id: UUID
    let name: String
    let durationInSeconds: Int
    let icon: String
    let colorHex: String
    let sortOrder: Int
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let todoItems: [TodoItemDTO]

    // Custom initializer for testing
    init(
        id: UUID,
        name: String,
        durationInSeconds: Int,
        icon: String,
        colorHex: String,
        sortOrder: Int,
        notes: String?,
        createdAt: Date,
        updatedAt: Date,
        todoItems: [TodoItemDTO]
    ) {
        self.id = id
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.todoItems = todoItems
    }

    // Convert from SwiftData model
    init(from timer: Timer) {
        self.id = timer.id
        self.name = timer.name
        self.durationInSeconds = timer.durationInSeconds
        self.icon = timer.icon
        self.colorHex = timer.colorHex
        self.sortOrder = timer.sortOrder
        self.notes = timer.notes
        self.createdAt = timer.createdAt
        self.updatedAt = timer.updatedAt
        self.todoItems = timer.todoItems.map { TodoItemDTO(from: $0) }
    }

    // Convert to SwiftData model
    func toModel() -> Timer {
        let timer = Timer(
            id: id,
            name: name,
            durationInSeconds: durationInSeconds,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            notes: notes
        )
        timer.createdAt = createdAt
        timer.updatedAt = updatedAt
        return timer
    }
}
