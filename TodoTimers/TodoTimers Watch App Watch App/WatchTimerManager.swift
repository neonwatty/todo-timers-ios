import Foundation

/// Singleton manager that maintains active timer services across the Watch app lifecycle.
/// Ensures timers continue running when navigating between views.
@MainActor
@Observable
class WatchTimerManager {
    static let shared = WatchTimerManager()

    /// Active timer services keyed by timer UUID
    private var activeTimers: [UUID: WatchTimerService] = [:]
    private(set) var runningTimerID: UUID?

    private init() {}

    /// Get or create a timer service for the given timer
    /// - Parameter timer: The timer to get a service for
    /// - Returns: Existing service if active, or newly created service
    func getTimerService(for timer: Timer) -> WatchTimerService {
        if let existing = activeTimers[timer.id] {
            return existing
        }

        let service = WatchTimerService(timer: timer, manager: self)
        activeTimers[timer.id] = service
        return service
    }

    /// Check if a timer is currently running
    /// - Parameter timerID: The UUID of the timer to check
    /// - Returns: True if the timer is active and running
    func isTimerRunning(timerID: UUID) -> Bool {
        return runningTimerID == timerID
    }

    /// Get all active timer services (for UI observation)
    func getAllActiveTimers() -> [UUID: WatchTimerService] {
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

    /// Notify manager when a timer starts (called by WatchTimerService)
    func notifyTimerStarted(timerID: UUID) {
        stopAllTimersExcept(timerID: timerID)
    }

    /// Notify manager when a timer pauses/stops (called by WatchTimerService)
    func notifyTimerStopped(timerID: UUID) {
        if runningTimerID == timerID {
            runningTimerID = nil
        }
    }

    /// Remove and cleanup a specific timer service
    /// - Parameter timerID: The UUID of the timer to remove
    func removeTimerService(timerID: UUID) {
        if let service = activeTimers[timerID] {
            service.cleanup()
            activeTimers.removeValue(forKey: timerID)
        }
        if runningTimerID == timerID {
            runningTimerID = nil
        }
    }

    /// Cleanup all active timer services
    func cleanupAll() {
        for (_, service) in activeTimers {
            service.cleanup()
        }
        activeTimers.removeAll()
        runningTimerID = nil
    }
}
