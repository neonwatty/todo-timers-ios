import Foundation

struct TodoItemDTO: Codable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date

    // Custom initializer for testing
    init(
        id: UUID,
        text: String,
        isCompleted: Bool,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convert from SwiftData model
    init(from todoItem: TodoItem) {
        self.id = todoItem.id
        self.text = todoItem.text
        self.isCompleted = todoItem.isCompleted
        self.sortOrder = todoItem.sortOrder
        self.createdAt = todoItem.createdAt
        self.updatedAt = todoItem.updatedAt
    }

    // Convert to SwiftData model
    func toModel() -> TodoItem {
        let todo = TodoItem(
            id: id,
            text: text,
            isCompleted: isCompleted,
            sortOrder: sortOrder
        )
        todo.createdAt = createdAt
        todo.updatedAt = updatedAt
        return todo
    }
}
