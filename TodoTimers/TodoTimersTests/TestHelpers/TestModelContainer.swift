import Foundation
import SwiftData
@testable import TodoTimers

/// Helper to create in-memory SwiftData containers for testing
@MainActor
struct TestModelContainer {
    /// Creates an in-memory ModelContainer for testing
    /// - Returns: A configured ModelContainer with in-memory storage
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Timer.self,
            TodoItem.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Creates an in-memory ModelContainer with sample data
    /// - Returns: A configured ModelContainer with pre-populated test data
    static func createWithSampleData() throws -> ModelContainer {
        let container = try create()
        let context = container.mainContext

        // Create sample timer with todos
        let timer = Timer(
            name: "Test Timer",
            durationInSeconds: 1500,
            icon: "timer",
            colorHex: "#007AFF"
        )

        let todo1 = TodoItem(text: "Test Todo 1", sortOrder: 0)
        let todo2 = TodoItem(text: "Test Todo 2", isCompleted: true, sortOrder: 1)

        timer.todoItems = [todo1, todo2]

        context.insert(timer)
        try context.save()

        return container
    }
}
