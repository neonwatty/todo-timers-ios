import Foundation
@testable import TodoTimers

// Type alias to avoid ambiguity with Foundation.Timer
typealias TimerModel = TodoTimers.Timer

/// Factory for creating test data with configurable parameters
@MainActor
struct TestDataFactory {
    // MARK: - Timer Factory Methods

    /// Creates a basic timer with default values
    static func makeTimer(
        id: UUID = UUID(),
        name: String = "Test Timer",
        durationInSeconds: Int = 1500,
        icon: String = "timer",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        notes: String? = nil
    ) -> TimerModel {
        TimerModel(
            id: id,
            name: name,
            durationInSeconds: durationInSeconds,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            notes: notes
        )
    }

    /// Creates a timer with invalid name (for validation tests)
    static func makeInvalidTimer_EmptyName() -> TimerModel {
        TimerModel(
            name: "",
            durationInSeconds: 1500,
            icon: "timer",
            colorHex: "#007AFF"
        )
    }

    /// Creates a timer with invalid duration (for validation tests)
    static func makeInvalidTimer_ZeroDuration() -> TimerModel {
        TimerModel(
            name: "Test Timer",
            durationInSeconds: 0,
            icon: "timer",
            colorHex: "#007AFF"
        )
    }

    /// Creates a timer with excessive duration (for validation tests)
    static func makeInvalidTimer_ExcessiveDuration() -> TimerModel {
        TimerModel(
            name: "Test Timer",
            durationInSeconds: 86401,  // >24 hours
            icon: "timer",
            colorHex: "#007AFF"
        )
    }

    /// Creates a timer with todos attached
    static func makeTimerWithTodos(
        todoCount: Int = 3,
        completedCount: Int = 1
    ) -> TimerModel {
        let timer = makeTimer()

        for i in 0..<todoCount {
            let todo = makeTodoItem(
                text: "Todo \(i + 1)",
                isCompleted: i < completedCount,
                sortOrder: i
            )
            timer.todoItems.append(todo)
        }

        return timer
    }

    // MARK: - TodoItem Factory Methods

    /// Creates a basic todo item with default values
    static func makeTodoItem(
        id: UUID = UUID(),
        text: String = "Test Todo",
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) -> TodoItem {
        TodoItem(
            id: id,
            text: text,
            isCompleted: isCompleted,
            sortOrder: sortOrder
        )
    }

    /// Creates a todo item with invalid text (for validation tests)
    static func makeInvalidTodoItem_EmptyText() -> TodoItem {
        TodoItem(
            text: "",
            sortOrder: 0
        )
    }

    // MARK: - DTO Factory Methods

    /// Creates a TimerDTO from a Timer
    static func makeTimerDTO(from timer: TimerModel) -> TimerDTO {
        TimerDTO(from: timer)
    }

    /// Creates a TimerDTO with custom values
    static func makeTimerDTO(
        id: UUID = UUID(),
        name: String = "Test Timer",
        durationInSeconds: Int = 1500,
        icon: String = "timer",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        todoItems: [TodoItemDTO] = []
    ) -> TimerDTO {
        TimerDTO(
            id: id,
            name: name,
            durationInSeconds: durationInSeconds,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            todoItems: todoItems
        )
    }

    /// Creates a TodoItemDTO with custom values
    static func makeTodoItemDTO(
        id: UUID = UUID(),
        text: String = "Test Todo",
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> TodoItemDTO {
        TodoItemDTO(
            id: id,
            text: text,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Watch Payload Factory Methods

    /// Creates a TimerSyncPayload
    static func makeTimerSyncPayload(
        timers: [TimerDTO] = [],
        syncTimestamp: Date = Date()
    ) -> TimerSyncPayload {
        TimerSyncPayload(
            timers: timers,
            syncTimestamp: syncTimestamp
        )
    }

    /// Creates a TimerUpdateMessage
    static func makeTimerUpdateMessage(
        type: TimerUpdateMessage.UpdateType,
        timer: TimerDTO? = nil,
        timerID: UUID = UUID()
    ) -> TimerUpdateMessage {
        TimerUpdateMessage(
            type: type,
            timer: timer,
            timerID: timerID
        )
    }

    /// Creates a QuickActionMessage
    static func makeQuickActionMessage(
        action: QuickActionMessage.Action,
        timerID: UUID = UUID(),
        todoID: UUID? = nil,
        todoCompleted: Bool? = nil,
        noteText: String? = nil
    ) -> QuickActionMessage {
        QuickActionMessage(
            action: action,
            timerID: timerID,
            todoID: todoID,
            todoCompleted: todoCompleted,
            noteText: noteText
        )
    }
}
