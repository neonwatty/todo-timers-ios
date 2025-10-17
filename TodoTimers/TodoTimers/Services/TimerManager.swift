import Foundation
import SwiftUI

@MainActor
@Observable
class TimerManager {
    static let shared = TimerManager()

    private var activeTimers: [UUID: TimerService] = [:]

    private init() {}

    func getTimerService(for timer: Timer) -> TimerService {
        if let existing = activeTimers[timer.id] {
            return existing
        }

        let service = TimerService(timer: timer)
        activeTimers[timer.id] = service
        return service
    }

    func removeTimerService(timerID: UUID) {
        if let service = activeTimers[timerID] {
            service.cleanup()
            activeTimers.removeValue(forKey: timerID)
        }
    }

    func cleanupAll() {
        for (_, service) in activeTimers {
            service.cleanup()
        }
        activeTimers.removeAll()
    }
}
