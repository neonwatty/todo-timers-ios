import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class TimerManager {
    static let shared = TimerManager()

    private var activeTimers: [UUID: TimerService] = [:]
    private(set) var runningTimerID: UUID?
    private var modelContext: ModelContext?

    private init() {}

    /// Configure the timer manager with model context for state persistence
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getTimerService(for timer: Timer) -> TimerService {
        if let existing = activeTimers[timer.id] {
            return existing
        }

        let service = TimerService(timer: timer, manager: self, modelContext: modelContext)
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

    // MARK: - Lifecycle Management

    /// Save state of all timers when app is about to background
    func saveAllTimersState() {
        for (_, service) in activeTimers {
            service.saveStateForBackground()
        }
        print("💾 [TimerManager] Saved state for \(activeTimers.count) active timers")
    }

    // MARK: - Remote State Sync

    /// Apply timer state change received from remote device via WatchConnectivity
    func applyRemoteTimerState(timerID: UUID, action: TimerStateMessage.Action, currentTime: Int) {
        print("🔄 [TimerManager] Applying remote state: \(action.rawValue) for timer \(timerID)")

        // Only apply state if TimerService already exists (active timer)
        guard let service = activeTimers[timerID] else {
            print("⚠️ [TimerManager] No active service for timer \(timerID), ignoring remote state")
            return
        }

        switch action {
        case .started:
            service.startFromRemote(currentTime: currentTime)
        case .paused:
            service.pauseFromRemote()
        case .resumed:
            service.resumeFromRemote()
        case .reset:
            service.resetFromRemote()
        case .completed:
            service.completeFromRemote()
        }
    }
}
