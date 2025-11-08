import Testing
import Foundation
@testable import TodoTimers

@Suite("TimerDTO Tests")
struct TimerDTOTests {

    // MARK: - Conversion Tests

    @Test("Init from Timer copies all fields correctly")
    @MainActor
    func initFromTimer_AllFieldsCopied() {
        let timer = TestDataFactory.makeTimer(
            name: "Workout",
            durationInSeconds: 1800,
            icon: "figure.run",
            colorHex: "#FF3B30",
            notes: "Test notes"
        )

        let dto = TimerDTO(from: timer)

        #expect(dto.id == timer.id)
        #expect(dto.name == timer.name)
        #expect(dto.durationInSeconds == timer.durationInSeconds)
        #expect(dto.icon == timer.icon)
        #expect(dto.colorHex == timer.colorHex)
        #expect(dto.notes == timer.notes)
        #expect(dto.createdAt == timer.createdAt)
        #expect(dto.updatedAt == timer.updatedAt)
    }

    @Test("Init from Timer converts todo items")
    @MainActor
    func initFromTimer_TodoItemsConverted() {
        let timer = TestDataFactory.makeTimerWithTodos(todoCount: 3, completedCount: 1)

        let dto = TimerDTO(from: timer)

        #expect(dto.todoItems.count == 3)
        #expect(dto.todoItems[0].isCompleted == true)
        #expect(dto.todoItems[1].isCompleted == false)
    }

    @Test("ToModel creates timer with all fields")
    @MainActor
    func toModel_AllFieldsCopied() {
        let dto = TestDataFactory.makeTimerDTO(
            name: "Study",
            durationInSeconds: 2700,
            icon: "book.fill",
            colorHex: "#007AFF",
            notes: "Focus time"
        )

        let timer = dto.toModel()

        #expect(timer.id == dto.id)
        #expect(timer.name == dto.name)
        #expect(timer.durationInSeconds == dto.durationInSeconds)
        #expect(timer.icon == dto.icon)
        #expect(timer.colorHex == dto.colorHex)
        #expect(timer.notes == dto.notes)
    }

    @Test("ToModel preserves timestamps")
    @MainActor
    func toModel_PreservesTimestamps() {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)

        let dto = TestDataFactory.makeTimerDTO(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let timer = dto.toModel()

        #expect(timer.createdAt == createdAt)
        #expect(timer.updatedAt == updatedAt)
    }

    // MARK: - Codable Tests

    @Test("Encode produces valid data")
    @MainActor
    func encode_ValidDTO_ProducesData() throws {
        let dto = TestDataFactory.makeTimerDTO()

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        #expect(data.count > 0)
    }

    @Test("Decode valid data produces DTO")
    @MainActor
    func decode_ValidData_ProducesDTO() throws {
        let dto = TestDataFactory.makeTimerDTO(name: "Test Timer")

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        let decodedDTO = try decoder.decode(TimerDTO.self, from: data)

        #expect(decodedDTO.name == "Test Timer")
        #expect(decodedDTO.id == dto.id)
    }

    @Test("Round trip encode/decode preserves data")
    @MainActor
    func roundTrip_EncodeDecode_PreservesData() throws {
        let original = TestDataFactory.makeTimerDTO(
            name: "Original Timer",
            durationInSeconds: 1234,
            icon: "custom.icon",
            colorHex: "#ABCDEF"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.durationInSeconds == original.durationInSeconds)
        #expect(decoded.icon == original.icon)
        #expect(decoded.colorHex == original.colorHex)
    }

    // MARK: - Edge Cases

    @Test("Init from Timer with no todos creates empty array")
    @MainActor
    func initFromTimer_NoTodos_EmptyArray() {
        let timer = TestDataFactory.makeTimer()

        let dto = TimerDTO(from: timer)

        #expect(dto.todoItems.isEmpty)
    }

    @Test("Init from Timer with nil notes preserves nil")
    @MainActor
    func initFromTimer_NoNotes_NilValue() {
        let timer = TestDataFactory.makeTimer(notes: nil)

        let dto = TimerDTO(from: timer)

        #expect(dto.notes == nil)
    }

    // MARK: - Sort Order Tests

    @Test("Init from Timer copies sortOrder")
    @MainActor
    func initFromTimer_CopiesSortOrder() {
        let timer = TestDataFactory.makeTimer()
        timer.sortOrder = 5

        let dto = TimerDTO(from: timer)

        #expect(dto.sortOrder == 5)
    }

    @Test("ToModel preserves sortOrder")
    @MainActor
    func toModel_PreservesSortOrder() {
        let dto = TestDataFactory.makeTimerDTO(sortOrder: 10)

        let timer = dto.toModel()

        #expect(timer.sortOrder == 10)
    }

    @Test("Round trip encode/decode preserves sortOrder")
    @MainActor
    func roundTrip_EncodeDecode_PreservesSortOrder() throws {
        let original = TestDataFactory.makeTimerDTO(sortOrder: 7)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimerDTO.self, from: data)

        #expect(decoded.sortOrder == original.sortOrder)
    }
}
