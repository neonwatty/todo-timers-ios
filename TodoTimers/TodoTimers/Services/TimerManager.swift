import Foundation
import SwiftUI

@MainActor
@Observable
class TimerManager {
    static let shared = TimerManager()

    private var activeTimers: [UUID: TimerService] = [:]
    private(set) var runningTimerID: UUID?

    private init() {}

    func getTimerService(for timer: Timer) -> TimerService {
        if let existing = activeTimers[timer.id] {
            return existing
        }

        let service = TimerService(timer: timer, manager: self)
        activeTimers[timer.id] = service
        return service
    }

    /// Check if a specific timer is currently running
    func isTimerRunning(timerID: UUID) -> Bool {
        return runningTimerID == timerID
    }

    /// Get all active timer services (for UI observation)
    func getAllActiveTimers() -> [UUID: TimerService] {
        return activeTimers
    }

    /// Stop all timers except the specified one (for mutual exclusivity)
    func stopAllTimersExcept(timerID: UUID) {
        for (id, service) in activeTimers where id != timerID {
            if service.isRunning {
                service.pause()
            }
        }
        runningTimerID = timerID
    }

    /// Notify manager when a timer starts (called by TimerService)
    func notifyTimerStarted(timerID: UUID) {
        stopAllTimersExcept(timerID: timerID)
    }

    /// Notify manager when a timer pauses/stops (called by TimerService)
    func notifyTimerStopped(timerID: UUID) {
        if runningTimerID == timerID {
            runningTimerID = nil
        }
    }

    func removeTimerService(timerID: UUID) {
        if let service = activeTimers[timerID] {
            service.cleanup()
            activeTimers.removeValue(forKey: timerID)
        }
        if runningTimerID == timerID {
            runningTimerID = nil
        }
    }

    func cleanupAll() {
        for (_, service) in activeTimers {
            service.cleanup()
        }
        activeTimers.removeAll()
        runningTimerID = nil
    }
}
