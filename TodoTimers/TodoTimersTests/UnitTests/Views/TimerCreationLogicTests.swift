import Testing
import SwiftData
import Foundation
@testable import TodoTimers

@Suite("Timer Creation Logic Tests")
@MainActor
struct TimerCreationLogicTests {

    // MARK: - SortOrder Assignment Tests

    @Test("New timer with no existing timers gets sortOrder 0")
    func newTimer_NoExistingTimers_GetsZeroSortOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Simulate empty timer list
        let existingTimers: [TodoTimers.Timer] = []

        // Calculate sortOrder (logic from CreateTimerView)
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Verify first timer gets sortOrder 0
        #expect(nextSortOrder == 0)

        // Create and insert timer
        let timer = TodoTimers.Timer(
            name: "First Timer",
            durationInSeconds: 300,
            sortOrder: nextSortOrder
        )
        context.insert(timer)
        try context.save()

        // Verify persisted correctly
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.sortOrder == 0)
    }

    @Test("New timer with existing timers gets max sortOrder + 1")
    func newTimer_WithExistingTimers_GetsIncrementedSortOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create existing timers with sortOrder 0, 1, 2
        let timer1 = TestDataFactory.makeTimer(name: "Timer 1", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "Timer 2", sortOrder: 1)
        let timer3 = TestDataFactory.makeTimer(name: "Timer 3", sortOrder: 2)

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // Fetch existing timers (simulate CreateTimerView's @Query)
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let existingTimers = try context.fetch(descriptor)

        // Calculate sortOrder for new timer
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Verify new timer gets sortOrder 3
        #expect(nextSortOrder == 3)

        // Create and insert new timer
        let newTimer = TodoTimers.Timer(
            name: "Timer 4",
            durationInSeconds: 300,
            sortOrder: nextSortOrder
        )
        context.insert(newTimer)
        try context.save()

        // Verify new timer has correct sortOrder
        let allTimers = try context.fetch(descriptor)
        #expect(allTimers.count == 4)
        let lastTimer = allTimers.first(where: { $0.name == "Timer 4" })
        #expect(lastTimer?.sortOrder == 3)
    }

    @Test("New timer with gaps in sortOrder sequence uses max + 1")
    func newTimer_WithGapsInSortOrder_UsesMaxPlusOne() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create timers with non-sequential sortOrder (0, 2, 5 - missing 1, 3, 4)
        let timer1 = TestDataFactory.makeTimer(name: "Timer 1", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "Timer 2", sortOrder: 2)
        let timer3 = TestDataFactory.makeTimer(name: "Timer 3", sortOrder: 5)

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // Fetch existing timers
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let existingTimers = try context.fetch(descriptor)

        // Calculate sortOrder
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Should use max (5) + 1 = 6, not fill gaps
        #expect(nextSortOrder == 6)
    }

    @Test("New timer after reordering gets correct sortOrder")
    func newTimer_AfterReordering_GetsCorrectSortOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create initial timers
        let timer1 = TestDataFactory.makeTimer(name: "Timer A", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "Timer B", sortOrder: 1)
        let timer3 = TestDataFactory.makeTimer(name: "Timer C", sortOrder: 2)

        context.insert(timer1)
        context.insert(timer2)
        context.insert(timer3)
        try context.save()

        // Simulate reordering (reverse order)
        timer1.sortOrder = 2
        timer2.sortOrder = 1
        timer3.sortOrder = 0
        try context.save()

        // Fetch existing timers after reorder
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let existingTimers = try context.fetch(descriptor)

        // Calculate sortOrder for new timer
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Should append after highest sortOrder (2)
        #expect(nextSortOrder == 3)

        // Create new timer
        let newTimer = TodoTimers.Timer(
            name: "Timer D",
            durationInSeconds: 300,
            sortOrder: nextSortOrder
        )
        context.insert(newTimer)
        try context.save()

        // Verify appears at end when sorted by sortOrder
        let sortedDescriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor<TodoTimers.Timer>(\.sortOrder)]
        )
        let sorted = try context.fetch(sortedDescriptor)
        #expect(sorted.last?.name == "Timer D")
        #expect(sorted.last?.sortOrder == 3)
    }

    @Test("Multiple new timers created sequentially get incrementing sortOrder")
    func multipleNewTimers_CreatedSequentially_GetIncrementingSortOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create 5 new timers sequentially (simulating user creating multiple timers)
        for i in 0..<5 {
            let descriptor = FetchDescriptor<TodoTimers.Timer>()
            let existingTimers = try context.fetch(descriptor)

            let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
            let nextSortOrder = maxSortOrder + 1

            let timer = TodoTimers.Timer(
                name: "Timer \(i)",
                durationInSeconds: 300,
                sortOrder: nextSortOrder
            )
            context.insert(timer)
            try context.save()

            // Verify each timer gets correct sequential sortOrder
            #expect(timer.sortOrder == i)
        }

        // Verify all timers have sequential sortOrder
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor<TodoTimers.Timer>(\.sortOrder)]
        )
        let allTimers = try context.fetch(descriptor)
        #expect(allTimers.count == 5)

        for (index, timer) in allTimers.enumerated() {
            #expect(timer.sortOrder == index)
            #expect(timer.name == "Timer \(index)")
        }
    }

    @Test("SortOrder calculation handles edge case of single timer with high sortOrder")
    func newTimer_SingleTimerWithHighSortOrder_CalculatesCorrectly() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create single timer with high sortOrder (e.g., 100)
        let timer = TestDataFactory.makeTimer(name: "Timer", sortOrder: 100)
        context.insert(timer)
        try context.save()

        // Fetch existing timers
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let existingTimers = try context.fetch(descriptor)

        // Calculate sortOrder
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Should be 101
        #expect(nextSortOrder == 101)
    }

    // MARK: - Edge Cases

    @Test("Empty array max returns nil correctly handled by nil coalescing")
    func emptyArray_MaxReturnsNil_HandledByNilCoalescing() {
        let existingTimers: [TodoTimers.Timer] = []

        // Test the nil coalescing operator
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1

        // Should return -1 when array is empty
        #expect(maxSortOrder == -1)

        // Next sortOrder should be 0
        let nextSortOrder = maxSortOrder + 1
        #expect(nextSortOrder == 0)
    }

    @Test("SortOrder calculation is independent of timer creation order")
    func sortOrderCalculation_IndependentOfCreationOrder() throws {
        let container = try TestModelContainer.create()
        let context = container.mainContext

        // Create timers in random order with specific sortOrder values
        let timer3 = TestDataFactory.makeTimer(name: "C", sortOrder: 2)
        let timer1 = TestDataFactory.makeTimer(name: "A", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "B", sortOrder: 1)

        // Insert in reverse sortOrder
        context.insert(timer3)
        context.insert(timer1)
        context.insert(timer2)
        try context.save()

        // Calculate sortOrder for new timer
        let descriptor = FetchDescriptor<TodoTimers.Timer>()
        let existingTimers = try context.fetch(descriptor)
        let maxSortOrder = existingTimers.map(\.sortOrder).max() ?? -1
        let nextSortOrder = maxSortOrder + 1

        // Should still get 3 (max of [0,1,2] + 1)
        #expect(nextSortOrder == 3)
    }
}
