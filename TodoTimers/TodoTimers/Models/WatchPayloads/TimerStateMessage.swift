import Foundation

/// Message for syncing timer runtime state (start/pause/resume/reset) between devices
struct TimerStateMessage: Codable {
    enum Action: String, Codable {
        case started
        case paused
        case resumed
        case reset
        case completed
    }

    let timerID: UUID
    let action: Action
    let currentTime: Int  // Current countdown time in seconds
    let timestamp: Date

    init(timerID: UUID, action: Action, currentTime: Int) {
        self.timerID = timerID
        self.action = action
        self.currentTime = currentTime
        self.timestamp = Date()
    }
}
