import Testing
import Foundation
@testable import TodoTimers

@Suite("TodoItemDTO Tests")
struct TodoItemDTOTests {

    // MARK: - Conversion Tests

    @Test("Init from TodoItem copies all fields correctly")
    @MainActor
    func initFromTodoItem_AllFieldsCopied() {
        let todo = TestDataFactory.makeTodoItem(
            text: "Test Todo",
            isCompleted: true,
            sortOrder: 5
        )

        let dto = TodoItemDTO(from: todo)

        #expect(dto.id == todo.id)
        #expect(dto.text == todo.text)
        #expect(dto.isCompleted == todo.isCompleted)
        #expect(dto.sortOrder == todo.sortOrder)
        #expect(dto.createdAt == todo.createdAt)
        #expect(dto.updatedAt == todo.updatedAt)
    }

    @Test("ToModel creates todo with all fields")
    @MainActor
    func toModel_AllFieldsCopied() {
        let dto = TestDataFactory.makeTodoItemDTO(
            text: "Study chapter 3",
            isCompleted: false,
            sortOrder: 2
        )

        let todo = dto.toModel()

        #expect(todo.id == dto.id)
        #expect(todo.text == dto.text)
        #expect(todo.isCompleted == dto.isCompleted)
        #expect(todo.sortOrder == dto.sortOrder)
    }

    @Test("ToModel preserves timestamps")
    @MainActor
    func toModel_PreservesTimestamps() {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)

        let dto = TestDataFactory.makeTodoItemDTO(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let todo = dto.toModel()

        #expect(todo.createdAt == createdAt)
        #expect(todo.updatedAt == updatedAt)
    }

    // MARK: - Codable Tests

    @Test("Encode produces valid data")
    @MainActor
    func encode_ValidDTO_ProducesData() throws {
        let dto = TestDataFactory.makeTodoItemDTO()

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        #expect(data.count > 0)
    }

    @Test("Decode valid data produces DTO")
    @MainActor
    func decode_ValidData_ProducesDTO() throws {
        let dto = TestDataFactory.makeTodoItemDTO(text: "Decode Test")

        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        let decodedDTO = try decoder.decode(TodoItemDTO.self, from: data)

        #expect(decodedDTO.text == "Decode Test")
        #expect(decodedDTO.id == dto.id)
    }

    @Test("Round trip encode/decode preserves data")
    @MainActor
    func roundTrip_EncodeDecode_PreservesData() throws {
        let original = TestDataFactory.makeTodoItemDTO(
            text: "Original Todo",
            isCompleted: true,
            sortOrder: 7
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TodoItemDTO.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.text == original.text)
        #expect(decoded.isCompleted == original.isCompleted)
        #expect(decoded.sortOrder == original.sortOrder)
    }

    // MARK: - Edge Cases

    @Test("Completed todo converts correctly")
    @MainActor
    func initFromTodoItem_Completed_ConvertsCorrectly() {
        let todo = TestDataFactory.makeTodoItem(isCompleted: true)

        let dto = TodoItemDTO(from: todo)

        #expect(dto.isCompleted == true)
    }

    @Test("Uncompleted todo converts correctly")
    @MainActor
    func initFromTodoItem_Uncompleted_ConvertsCorrectly() {
        let todo = TestDataFactory.makeTodoItem(isCompleted: false)

        let dto = TodoItemDTO(from: todo)

        #expect(dto.isCompleted == false)
    }
}
