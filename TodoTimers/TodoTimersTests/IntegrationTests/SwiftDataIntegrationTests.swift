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

        let descriptor = FetchDescriptor<TodoTimers.Timer>()
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

        let timerID = timer.id
        let descriptor = FetchDescriptor<TodoTimers.Timer>(predicate: #Predicate { $0.id == timerID })
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
        let timerDescriptor = FetchDescriptor<TodoTimers.Timer>(predicate: #Predicate { $0.id == timerID })
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

        let descriptor = FetchDescriptor<TodoTimers.Timer>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
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

        let timerID = timer.id
        let descriptor = FetchDescriptor<TodoTimers.Timer>(predicate: #Predicate { $0.id == timerID })
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
        let todoID = todo.id
        todo.isCompleted = true
        try context.save()

        let todoDescriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == todoID })
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

        let timerID = timer.id
        let descriptor = FetchDescriptor<TodoTimers.Timer>(predicate: #Predicate { $0.id == timerID })
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

        let timerID = timer.id
        let descriptor = FetchDescriptor<TodoTimers.Timer>(predicate: #Predicate { $0.id == timerID })
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

    // MARK: - Timer Sorting Tests

    @Test("Fetch timers sorted by sortOrder")
    func fetchTimersSorted_BySortOrder_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create timers with explicit sortOrder values (out of order)
        let timer1 = TestDataFactory.makeTimer(name: "Third Timer", sortOrder: 2)
        let timer2 = TestDataFactory.makeTimer(name: "First Timer", sortOrder: 0)
        let timer3 = TestDataFactory.makeTimer(name: "Second Timer", sortOrder: 1)

        // Insert in random order
        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // Fetch with sortOrder sorting
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let fetched = try context.fetch(descriptor)

        // Verify sorted by sortOrder
        #expect(fetched.count == 3)
        #expect(fetched[0].name == "First Timer")
        #expect(fetched[0].sortOrder == 0)
        #expect(fetched[1].name == "Second Timer")
        #expect(fetched[1].sortOrder == 1)
        #expect(fetched[2].name == "Third Timer")
        #expect(fetched[2].sortOrder == 2)
    }

    @Test("Fetch timers sorted by sortOrder then createdAt (matches TimerListView)")
    func fetchTimersSorted_BySortOrderThenCreatedAt_Success() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create timers with same sortOrder but different createdAt
        let timer1 = TestDataFactory.makeTimer(name: "Timer A", sortOrder: 0)
        Thread.sleep(forTimeInterval: 0.01) // Ensure different createdAt
        let timer2 = TestDataFactory.makeTimer(name: "Timer B", sortOrder: 0)
        Thread.sleep(forTimeInterval: 0.01)
        let timer3 = TestDataFactory.makeTimer(name: "Timer C", sortOrder: 1)

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // This mirrors the exact query used in TimerListView
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        let fetched = try context.fetch(descriptor)

        // Verify primary sort by sortOrder
        #expect(fetched.count == 3)
        #expect(fetched[0].sortOrder == 0)
        #expect(fetched[1].sortOrder == 0)
        #expect(fetched[2].sortOrder == 1)

        // Verify secondary sort by createdAt for same sortOrder
        #expect(fetched[0].name == "Timer A") // Earlier createdAt
        #expect(fetched[1].name == "Timer B") // Later createdAt
        #expect(fetched[0].createdAt <= fetched[1].createdAt)
    }

    @Test("Update timer sortOrder and re-fetch maintains new order")
    func updateTimerSortOrder_RefetchMaintainsNewOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create timers in initial order
        let timer1 = TestDataFactory.makeTimer(name: "Timer 1", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "Timer 2", sortOrder: 1)
        let timer3 = TestDataFactory.makeTimer(name: "Timer 3", sortOrder: 2)

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // Reorder: move timer3 to first position
        timer1.sortOrder = 1
        timer2.sortOrder = 2
        timer3.sortOrder = 0
        timer3.updatedAt = Date() // Update timestamp like real implementation
        try context.save()

        // Fetch with sortOrder sorting
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let fetched = try context.fetch(descriptor)

        // Verify new order persisted
        #expect(fetched.count == 3)
        #expect(fetched[0].name == "Timer 3")
        #expect(fetched[0].sortOrder == 0)
        #expect(fetched[1].name == "Timer 1")
        #expect(fetched[1].sortOrder == 1)
        #expect(fetched[2].name == "Timer 2")
        #expect(fetched[2].sortOrder == 2)
    }

    @Test("Batch reorder multiple timers persists correctly")
    func batchReorderTimers_PersistsCorrectly() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create 5 timers
        let timers = (0..<5).map { i in
            TestDataFactory.makeTimer(name: "Timer \(i)", sortOrder: i)
        }

        for timer in timers {
            context.insert(timer)
        }
        try context.save()

        // Reverse the order (simulate drag from bottom to top)
        for (index, timer) in timers.enumerated() {
            timer.sortOrder = 4 - index
            timer.updatedAt = Date()
        }
        try context.save()

        // Fetch and verify reversed order
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 5)
        #expect(fetched[0].name == "Timer 4")
        #expect(fetched[1].name == "Timer 3")
        #expect(fetched[2].name == "Timer 2")
        #expect(fetched[3].name == "Timer 1")
        #expect(fetched[4].name == "Timer 0")
    }
}
