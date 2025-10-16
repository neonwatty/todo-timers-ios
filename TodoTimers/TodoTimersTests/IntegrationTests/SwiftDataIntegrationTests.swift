import Testing
import SwiftData
import Foundation
@testable import TodoTimers

@Suite("SwiftData Integration Tests")
@MainActor
struct SwiftDataIntegrationTests {

    // MARK: - Timer CRUD Tests

    @Test("Create timer saves and fetches successfully")
    func createTimer_SaveAndFetch_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer(name: "Integration Test Timer")
        context.insert(timer)
        try context.save()

        let descriptor = FetchDescriptor<Timer>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Integration Test Timer")
    }

    @Test("Update timer saves and reflects changes")
    func updateTimer_SaveAndFetch_ChangesReflected() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer(name: "Original Name")
        context.insert(timer)
        try context.save()

        timer.name = "Updated Name"
        timer.durationInSeconds = 2000
        try context.save()

        let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timer.id })
        let fetched = try context.fetch(descriptor).first

        #expect(fetched?.name == "Updated Name")
        #expect(fetched?.durationInSeconds == 2000)
    }

    @Test("Delete timer cascade deletes todos")
    func deleteTimer_CascadeDeletesTodos() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 3)
        context.insert(timer)
        try context.save()

        let timerID = timer.id
        context.delete(timer)
        try context.save()

        // Verify timer deleted
        let timerDescriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timerID })
        let fetchedTimers = try context.fetch(timerDescriptor)
        #expect(fetchedTimers.isEmpty)

        // Verify todos cascade deleted
        let todoDescriptor = FetchDescriptor<TodoItem>()
        let fetchedTodos = try context.fetch(todoDescriptor)
        #expect(fetchedTodos.isEmpty)
    }

    @Test("Fetch multiple timers sorted by createdAt")
    func fetchMultipleTimers_SortedByCreatedAt() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer1 = TestDataFactory.makeTimer(name: "First")
        let timer2 = TestDataFactory.makeTimer(name: "Second")
        let timer3 = TestDataFactory.makeTimer(name: "Third")

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        let descriptor = FetchDescriptor<Timer>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 3)
        #expect(fetched[0].createdAt <= fetched[1].createdAt)
        #expect(fetched[1].createdAt <= fetched[2].createdAt)
    }

    // MARK: - TodoItem CRUD Tests

    @Test("Create todo item attached to timer succeeds")
    func createTodoItem_AttachToTimer_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer()
        let todo = TestDataFactory.makeTodoItem(text: "Test Todo")

        timer.todoItems.append(todo)
        context.insert(timer)
        try context.save()

        let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timer.id })
        let fetched = try context.fetch(descriptor).first

        #expect(fetched?.todoItems.count == 1)
        #expect(fetched?.todoItems.first?.text == "Test Todo")
    }

    @Test("Toggle todo completion and save updates state")
    func toggleTodoCompletion_SaveAndFetch_Updated() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 1, completedCount: 0)
        context.insert(timer)
        try context.save()

        let todo = timer.todoItems.first!
        todo.isCompleted = true
        try context.save()

        let todoDescriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == todo.id })
        let fetched = try context.fetch(todoDescriptor).first

        #expect(fetched?.isCompleted == true)
    }

    @Test("Delete todo item removes from timer")
    func deleteTodoItem_RemovedFromTimer() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 3)
        context.insert(timer)
        try context.save()

        let todoToDelete = timer.todoItems.first!
        let todoID = todoToDelete.id

        if let index = timer.todoItems.firstIndex(where: { $0.id == todoID }) {
            timer.todoItems.remove(at: index)
        }
        context.delete(todoToDelete)
        try context.save()

        let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timer.id })
        let fetched = try context.fetch(descriptor).first

        #expect(fetched?.todoItems.count == 2)

        let todoDescriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == todoID })
        let fetchedTodos = try context.fetch(todoDescriptor)
        #expect(fetchedTodos.isEmpty)
    }

    // MARK: - Relationship Tests

    @Test("Timer todo relationship maintains bidirectional integrity")
    func timerTodoRelationship_BidirectionalIntegrity() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer()
        let todo = TestDataFactory.makeTodoItem()

        timer.todoItems.append(todo)
        context.insert(timer)
        try context.save()

        #expect(todo.timer?.id == timer.id)
        #expect(timer.todoItems.contains(where: { $0.id == todo.id }))
    }

    @Test("Cascade delete removes all todos when timer deleted")
    func cascadeDelete_RemovesAllTodos() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 5)
        context.insert(timer)
        try context.save()

        let todoIDs = timer.todoItems.map { $0.id }

        context.delete(timer)
        try context.save()

        for todoID in todoIDs {
            let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == todoID })
            let fetched = try context.fetch(descriptor)
            #expect(fetched.isEmpty)
        }
    }

    @Test("Multiple todos maintain independent state")
    func multipleTodos_IndependentState() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 3, completedCount: 1)
        context.insert(timer)
        try context.save()

        #expect(timer.todoItems[0].isCompleted == true)
        #expect(timer.todoItems[1].isCompleted == false)
        #expect(timer.todoItems[2].isCompleted == false)
    }

    // MARK: - Query Tests

    @Test("Fetch timer by ID using predicate succeeds")
    func fetchTimerByID_Predicate_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer(name: "Target Timer")
        context.insert(timer)
        try context.save()

        let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timer.id })
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Target Timer")
    }

    @Test("Fetch todos by timer using predicate succeeds")
    func fetchTodosByTimer_Predicate_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer1 = TestDataFactory.makeTimerWithTodos(todoCount: 2)
        let timer2 = TestDataFactory.makeTimerWithTodos(todoCount: 3)

        context.insert(timer1)
        context.insert(timer2)
        try context.save()

        #expect(timer1.todoItems.count == 2)
        #expect(timer2.todoItems.count == 3)
    }

    @Test("Fetch todos sorted by sortOrder")
    func fetchTodosSorted_BySortOrder_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        let timer = TestDataFactory.makeTimer()
        let todo1 = TestDataFactory.makeTodoItem(text: "Third", sortOrder: 2)
        let todo2 = TestDataFactory.makeTodoItem(text: "First", sortOrder: 0)
        let todo3 = TestDataFactory.makeTodoItem(text: "Second", sortOrder: 1)

        timer.todoItems = [todo1, todo2, todo3]
        context.insert(timer)
        try context.save()

        let sorted = timer.todoItems.sorted { $0.sortOrder < $1.sortOrder }

        #expect(sorted[0].text == "First")
        #expect(sorted[1].text == "Second")
        #expect(sorted[2].text == "Third")
    }
}
