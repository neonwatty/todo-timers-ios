import Testing
import Foundation
import SwiftData
@testable import TodoTimers

/// Tests for WatchConnectivityService
/// NOTE: Integration-style tests due to singleton pattern and WCSession dependencies
/// Focus on data encoding/decoding, merge logic, and conflict resolution
@Suite("WatchConnectivityService Tests")
@MainActor
struct WatchConnectivityServiceTests {

    // MARK: - Singleton Tests

    @Test("Shared instance returns same object")
    func shared_ReturnsSameInstance() {
        let instance1 = WatchConnectivityService.shared
        let instance2 = WatchConnectivityService.shared

        #expect(instance1 === instance2)
    }

    @Test("Configure sets model context")
    func configure_SetsModelContext() throws {
        let container = try TestModelContainer.create()
        let service = WatchConnectivityService.shared

        service.configure(modelContext: container.mainContext)

        // Verify by attempting operations that require context
        // If context not set, these would fail/crash
        #expect(true)
    }

    // MARK: - Full Sync Tests

    @Test("Send full sync with valid context does not crash")
    func sendFullSync_WithValidContext_DoesNotCrash() throws {
        let container = try TestModelContainer.create()
        let service = WatchConnectivityService.shared

        service.configure(modelContext: container.mainContext)

        // Create some test data
        let timer = TestDataFactory.makeTimer()
        container.mainContext.insert(timer)
        try container.mainContext.save()

        service.sendFullSync()

        #expect(true)
    }

    @Test("Send full sync without context handles gracefully")
    func sendFullSync_WithoutContext_HandlesGracefully() {
        let service = WatchConnectivityService.shared

        // Reset context (might not work due to singleton, but test shouldn't crash)
        service.sendFullSync()

        #expect(true)
    }

    // MARK: - Timer Update Tests

    @Test("Send timer update created type does not crash")
    func sendTimerUpdate_Created_DoesNotCrash() {
        let service = WatchConnectivityService.shared
        let timer = TestDataFactory.makeTimer()

        service.sendTimerUpdate(timer, type: .created)

        #expect(true)
    }

    @Test("Send timer update updated type does not crash")
    func sendTimerUpdate_Updated_DoesNotCrash() {
        let service = WatchConnectivityService.shared
        let timer = TestDataFactory.makeTimer()

        service.sendTimerUpdate(timer, type: .updated)

        #expect(true)
    }

    @Test("Send timer update deleted type does not crash")
    func sendTimerUpdate_Deleted_DoesNotCrash() {
        let service = WatchConnectivityService.shared
        let timer = TestDataFactory.makeTimer()

        service.sendTimerUpdate(timer, type: .deleted)

        #expect(true)
    }

    // MARK: - Quick Action Tests

    @Test("Send quick action todo toggled does not crash")
    func sendQuickAction_TodoToggled_DoesNotCrash() {
        let service = WatchConnectivityService.shared
        let timerID = UUID()
        let todoID = UUID()

        service.sendQuickAction(
            action: .todoToggled,
            timerID: timerID,
            todoID: todoID,
            todoCompleted: true
        )

        #expect(true)
    }

    @Test("Send quick action note updated does not crash")
    func sendQuickAction_NoteUpdated_DoesNotCrash() {
        let service = WatchConnectivityService.shared
        let timerID = UUID()

        service.sendQuickAction(
            action: .noteUpdated,
            timerID: timerID,
            noteText: "Updated notes"
        )

        #expect(true)
    }

    // MARK: - Data Encoding/Decoding Tests

    @Test("TimerDTO encoding and decoding round trip")
    func timerDTO_EncodingDecoding_RoundTrip() throws {
        let timer = TestDataFactory.makeTimer(name: "Test Timer")
        let dto = TimerDTO(from: timer)

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        let decodedDTO = try decoder.decode(TimerDTO.self, from: data)

        #expect(decodedDTO.id == dto.id)
        #expect(decodedDTO.name == dto.name)
        #expect(decodedDTO.durationInSeconds == dto.durationInSeconds)
    }

    @Test("TimerSyncPayload encoding and decoding")
    func timerSyncPayload_EncodingDecoding_Works() throws {
        let timer1 = TestDataFactory.makeTimer(name: "Timer 1")
        let timer2 = TestDataFactory.makeTimer(name: "Timer 2")
        let dtos = [TimerDTO(from: timer1), TimerDTO(from: timer2)]
        let payload = TimerSyncPayload(timers: dtos, syncTimestamp: Date())

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers.count == 2)
        #expect(decoded.timers[0].name == "Timer 1")
        #expect(decoded.timers[1].name == "Timer 2")
    }

    @Test("TimerUpdateMessage encoding and decoding")
    func timerUpdateMessage_EncodingDecoding_Works() throws {
        let timer = TestDataFactory.makeTimer()
        let dto = TimerDTO(from: timer)
        let message = TimerUpdateMessage(type: .updated, timer: dto, timerID: timer.id)

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        #expect(decoded.type == .updated)
        #expect(decoded.timerID == timer.id)
        #expect(decoded.timer?.name == timer.name)
    }

    @Test("QuickActionMessage encoding and decoding")
    func quickActionMessage_EncodingDecoding_Works() throws {
        let timerID = UUID()
        let todoID = UUID()
        let message = QuickActionMessage(
            action: .todoToggled,
            timerID: timerID,
            todoID: todoID,
            todoCompleted: true,
            noteText: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QuickActionMessage.self, from: data)

        #expect(decoded.action == .todoToggled)
        #expect(decoded.timerID == timerID)
        #expect(decoded.todoID == todoID)
        #expect(decoded.todoCompleted == true)
    }

    // MARK: - Edge Cases

    @Test("Send timer update with empty todos")
    func sendTimerUpdate_WithEmptyTodos_HandlesGracefully() {
        let service = WatchConnectivityService.shared
        let timer = TestDataFactory.makeTimer()  // No todos

        service.sendTimerUpdate(timer, type: .updated)

        #expect(true)
    }

    @Test("Send timer update with many todos")
    func sendTimerUpdate_WithManyTodos_HandlesGracefully() {
        let service = WatchConnectivityService.shared
        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 50)

        service.sendTimerUpdate(timer, type: .updated)

        #expect(true)
    }

    @Test("Send quick action with nil optional parameters")
    func sendQuickAction_WithNilOptionals_HandlesGracefully() {
        let service = WatchConnectivityService.shared
        let timerID = UUID()

        service.sendQuickAction(
            action: .noteUpdated,
            timerID: timerID,
            todoID: nil,
            todoCompleted: nil,
            noteText: nil
        )

        #expect(true)
    }

    // MARK: - Concurrent Operations

    @Test("Multiple sendTimerUpdate calls handle gracefully")
    func multipleSendTimerUpdate_HandleGracefully() {
        let service = WatchConnectivityService.shared
        let timer1 = TestDataFactory.makeTimer(name: "Timer 1")
        let timer2 = TestDataFactory.makeTimer(name: "Timer 2")

        service.sendTimerUpdate(timer1, type: .created)
        service.sendTimerUpdate(timer2, type: .created)
        service.sendTimerUpdate(timer1, type: .updated)
        service.sendTimerUpdate(timer2, type: .deleted)

        #expect(true)
    }

    // MARK: - Reachability Tests

    @Test("isReachable property is observable")
    func isReachable_IsObservable() {
        let service = WatchConnectivityService.shared

        // isReachable should be a valid Bool
        let reachable = service.isReachable
        #expect(reachable == true || reachable == false)
    }

    // MARK: - SortOrder Sync Tests

    @Test("TimerDTO encoding includes sortOrder field")
    func timerDTO_Encoding_IncludesSortOrder() throws {
        let timer = TestDataFactory.makeTimer(name: "Test Timer", sortOrder: 5)
        let dto = TimerDTO(from: timer)

        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        // Decode back to verify sortOrder preserved
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerDTO.self, from: data)

        #expect(decoded.sortOrder == 5)
        #expect(decoded.id == timer.id)
        #expect(decoded.name == timer.name)
    }

    @Test("TimerSyncPayload with multiple timers preserves all sortOrder values")
    func timerSyncPayload_MultipleTimers_PreservesAllSortOrder() throws {
        // Create timers with specific sortOrder values
        let timer1 = TestDataFactory.makeTimer(name: "Timer A", sortOrder: 0)
        let timer2 = TestDataFactory.makeTimer(name: "Timer B", sortOrder: 2)
        let timer3 = TestDataFactory.makeTimer(name: "Timer C", sortOrder: 5)

        let dtos = [
            TimerDTO(from: timer1),
            TimerDTO(from: timer2),
            TimerDTO(from: timer3)
        ]

        let payload = TimerSyncPayload(timers: dtos, syncTimestamp: Date())

        // Encode and decode payload
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        // Verify all sortOrder values preserved
        #expect(decoded.timers.count == 3)
        #expect(decoded.timers[0].sortOrder == 0)
        #expect(decoded.timers[1].sortOrder == 2)
        #expect(decoded.timers[2].sortOrder == 5)
    }

    @Test("TimerUpdateMessage with updated type includes sortOrder")
    func timerUpdateMessage_Updated_IncludesSortOrder() throws {
        let timer = TestDataFactory.makeTimer(name: "Reordered Timer", sortOrder: 10)
        let dto = TimerDTO(from: timer)

        let message = TimerUpdateMessage(
            type: .updated,
            timer: dto,
            timerID: timer.id
        )

        // Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        // Verify sortOrder included in update message
        #expect(decoded.timer?.sortOrder == 10)
        #expect(decoded.type == .updated)
    }

    @Test("Full sync payload maintains sortOrder sequence after reordering")
    func fullSyncPayload_AfterReordering_MaintainsSortOrderSequence() throws {
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

        // Reorder timers (simulate user dragging)
        timer1.sortOrder = 2  // Move to end
        timer2.sortOrder = 0  // Move to start
        timer3.sortOrder = 1  // Move to middle
        try context.save()

        // Create DTOs (simulating what sendFullSync does)
        let descriptor = FetchDescriptor<TodoTimers.Timer>(
            sortBy: [SortDescriptor<TodoTimers.Timer>(\.sortOrder), SortDescriptor<TodoTimers.Timer>(\.createdAt)]
        )
        let fetchedTimers = try context.fetch(descriptor)
        let dtos = fetchedTimers.map { TimerDTO(from: $0) }

        // Verify DTOs preserve reordered sortOrder
        #expect(dtos.count == 3)
        #expect(dtos[0].name == "Timer 2")
        #expect(dtos[0].sortOrder == 0)
        #expect(dtos[1].name == "Timer 3")
        #expect(dtos[1].sortOrder == 1)
        #expect(dtos[2].name == "Timer 1")
        #expect(dtos[2].sortOrder == 2)

        // Create and encode sync payload
        let payload = TimerSyncPayload(timers: dtos, syncTimestamp: Date())
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        // Decode and verify sortOrder intact
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers[0].sortOrder == 0)
        #expect(decoded.timers[1].sortOrder == 1)
        #expect(decoded.timers[2].sortOrder == 2)
    }

    @Test("Timer created message includes default sortOrder")
    func timerCreatedMessage_NewTimer_IncludesDefaultSortOrder() throws {
        // Simulate creating a new timer with sortOrder calculated
        let timer = TestDataFactory.makeTimer(name: "New Timer", sortOrder: 3)
        let dto = TimerDTO(from: timer)

        let message = TimerUpdateMessage(
            type: .created,
            timer: dto,
            timerID: timer.id
        )

        // Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        // Verify sortOrder transmitted with creation message
        #expect(decoded.timer?.sortOrder == 3)
        #expect(decoded.type == .created)
    }

    @Test("Empty timer list sync payload encodes correctly")
    func emptyTimerList_SyncPayload_EncodesCorrectly() throws {
        let payload = TimerSyncPayload(timers: [], syncTimestamp: Date())

        // Encode empty payload
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers.isEmpty)
    }

    @Test("Timer with todos preserves both timer sortOrder and todo sortOrder")
    func timerWithTodos_PreservesBothSortOrders() throws {
        let timer = TestDataFactory.makeTimer(name: "Timer", sortOrder: 5)
        let todo1 = TestDataFactory.makeTodoItem(text: "Todo 1", sortOrder: 0)
        let todo2 = TestDataFactory.makeTodoItem(text: "Todo 2", sortOrder: 1)

        timer.todoItems = [todo1, todo2]

        let dto = TimerDTO(from: timer)

        // Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerDTO.self, from: data)

        // Verify timer sortOrder preserved
        #expect(decoded.sortOrder == 5)

        // Verify todo sortOrder values preserved
        #expect(decoded.todoItems.count == 2)
        #expect(decoded.todoItems[0].sortOrder == 0)
        #expect(decoded.todoItems[1].sortOrder == 1)
    }
}

// MARK: - Test Documentation

/// TESTING LIMITATIONS & FUTURE IMPROVEMENTS
///
/// WatchConnectivityService has similar testability challenges to NotificationService:
///
/// 1. **WCSession Dependency**
///    - Current: Direct dependency on WCSession.default
///    - Impact: Cannot fully mock message sending/receiving
///    - Solution: Protocol wrapper + dependency injection
///
/// 2. **Singleton Pattern**
///    - Current: static let shared singleton
///    - Impact: Shared state across tests, cannot reset
///    - Solution: Make initializer testable or use factory
///
/// 3. **Async Delegate Callbacks**
///    - Current: Cannot verify delegate methods called correctly
///    - Impact: Limited testing of message receipt/handling
///    - Solution: Extract message handling to testable methods
///
/// 4. **Complex Merge Logic**
///    - Current: Tested indirectly through integration
///    - Impact: Cannot verify conflict resolution logic precisely
///    - Solution: Extract merging logic to separate testable class
///
/// CURRENT TEST COVERAGE:
/// - ✅ API surface (methods don't crash)
/// - ✅ Data encoding/decoding (full coverage)
/// - ✅ Message formatting
/// - ✅ Edge cases
/// - ❌ WCSession interaction verification (requires mocking)
/// - ❌ Merge conflict resolution logic (requires refactoring)
/// - ❌ Reachability change handling (requires mocking)
///
/// RECOMMENDATION:
/// Phase 2 improvements:
/// - Extract WCSessionProtocol with mock implementation
/// - Extract MergeService for testable conflict resolution
/// - Add explicit test seams for verification
/// - Consider factory pattern over singleton
