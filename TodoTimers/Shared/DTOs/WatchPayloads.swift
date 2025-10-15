import Foundation

// MARK: - Bulk Sync Payload

struct TimerSyncPayload: Codable {
    let timers: [TimerDTO]
    let syncTimestamp: Date
}

// MARK: - Single Timer Update Message

struct TimerUpdateMessage: Codable {
    enum UpdateType: String, Codable {
        case created
        case updated
        case deleted
    }

    let type: UpdateType
    let timer: TimerDTO?
    let timerID: UUID  // For deletions
}

// MARK: - Quick Action Message

struct QuickActionMessage: Codable {
    enum Action: String, Codable {
        case todoToggled
        case noteUpdated
    }

    let action: Action
    let timerID: UUID
    let todoID: UUID?
    let todoCompleted: Bool?
    let noteText: String?
}
