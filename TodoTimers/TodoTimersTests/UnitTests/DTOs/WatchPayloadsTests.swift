import Testing
import Foundation
@testable import TodoTimers

@Suite("Watch Payload Tests")
struct WatchPayloadsTests {

    // MARK: - TimerSyncPayload Tests

    @Test("TimerSyncPayload encodes successfully")
    @MainActor
    func timerSyncPayload_Encode_Success() throws {
        let timerDTOs = [
            TestDataFactory.makeTimerDTO(name: "Timer 1"),
            TestDataFactory.makeTimerDTO(name: "Timer 2")
        ]

        let payload = TestDataFactory.makeTimerSyncPayload(timers: timerDTOs)

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        #expect(data.count > 0)
    }

    @Test("TimerSyncPayload decodes successfully")
    @MainActor
    func timerSyncPayload_Decode_Success() throws {
        let timerDTOs = [
            TestDataFactory.makeTimerDTO(name: "Timer 1")
        ]

        let payload = TestDataFactory.makeTimerSyncPayload(timers: timerDTOs)

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers.count == 1)
        #expect(decoded.timers[0].name == "Timer 1")
    }

    @Test("TimerSyncPayload with empty timers succeeds")
    @MainActor
    func timerSyncPayload_EmptyTimers_Success() throws {
        let payload = TestDataFactory.makeTimerSyncPayload(timers: [])

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers.isEmpty)
    }

    // MARK: - TimerUpdateMessage Tests

    @Test("TimerUpdateMessage .created encodes correctly")
    @MainActor
    func timerUpdateMessage_Created_EncodesCorrectly() throws {
        let timerDTO = TestDataFactory.makeTimerDTO(name: "New Timer")
        let message = TestDataFactory.makeTimerUpdateMessage(
            type: .created,
            timer: timerDTO,
            timerID: timerDTO.id
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        #expect(decoded.type == .created)
        #expect(decoded.timer?.name == "New Timer")
    }

    @Test("TimerUpdateMessage .updated encodes correctly")
    @MainActor
    func timerUpdateMessage_Updated_EncodesCorrectly() throws {
        let timerDTO = TestDataFactory.makeTimerDTO(name: "Updated Timer")
        let message = TestDataFactory.makeTimerUpdateMessage(
            type: .updated,
            timer: timerDTO,
            timerID: timerDTO.id
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        #expect(decoded.type == .updated)
        #expect(decoded.timer != nil)
    }

    @Test("TimerUpdateMessage .deleted has nil timer")
    @MainActor
    func timerUpdateMessage_Deleted_NilTimer() throws {
        let timerID = UUID()
        let message = TestDataFactory.makeTimerUpdateMessage(
            type: .deleted,
            timer: nil,
            timerID: timerID
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerUpdateMessage.self, from: data)

        #expect(decoded.type == .deleted)
        #expect(decoded.timer == nil)
        #expect(decoded.timerID == timerID)
    }

    // MARK: - QuickActionMessage Tests

    @Test("QuickActionMessage todoToggled has all fields")
    @MainActor
    func quickActionMessage_TodoToggled_AllFieldsPresent() throws {
        let timerID = UUID()
        let todoID = UUID()

        let message = TestDataFactory.makeQuickActionMessage(
            action: .todoToggled,
            timerID: timerID,
            todoID: todoID,
            todoCompleted: true
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

    @Test("QuickActionMessage noteUpdated has correct fields")
    @MainActor
    func quickActionMessage_NoteUpdated_CorrectFields() throws {
        let timerID = UUID()

        let message = TestDataFactory.makeQuickActionMessage(
            action: .noteUpdated,
            timerID: timerID,
            noteText: "Updated notes"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QuickActionMessage.self, from: data)

        #expect(decoded.action == .noteUpdated)
        #expect(decoded.timerID == timerID)
        #expect(decoded.noteText == "Updated notes")
        #expect(decoded.todoID == nil)
        #expect(decoded.todoCompleted == nil)
    }

    // MARK: - Round Trip Tests

    @Test("TimerSyncPayload round trip preserves data")
    @MainActor
    func timerSyncPayload_RoundTrip_PreservesData() throws {
        let original = TestDataFactory.makeTimerSyncPayload(
            timers: [
                TestDataFactory.makeTimerDTO(name: "Timer 1"),
                TestDataFactory.makeTimerDTO(name: "Timer 2")
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerSyncPayload.self, from: data)

        #expect(decoded.timers.count == original.timers.count)
        #expect(decoded.timers[0].name == "Timer 1")
        #expect(decoded.timers[1].name == "Timer 2")
    }
}
