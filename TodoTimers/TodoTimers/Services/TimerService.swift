import Foundation
import Combine
import UIKit
import SwiftData

@MainActor
@Observable
class TimerService {
    private(set) var currentTime: Int
    private(set) var isRunning = false
    private(set) var isPaused = false

    private let totalTime: Int
    private let timer: Timer
    private var timerCancellable: AnyCancellable?
    private var startTime: Date?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private weak var manager: TimerManager?
    private let connectivityService: WatchConnectivityService?
    private var modelContext: ModelContext?

    init(timer: Timer, manager: TimerManager, connectivityService: WatchConnectivityService? = nil, modelContext: ModelContext? = nil) {
        self.timer = timer
        self.totalTime = timer.durationInSeconds
        self.currentTime = timer.durationInSeconds
        self.manager = manager
        self.connectivityService = connectivityService ?? WatchConnectivityService.shared
        self.modelContext = modelContext

        // Restore state if available
        restoreStateIfNeeded()
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        isPaused = false
        startTime = Date()

        // Notify manager to enforce mutual exclusivity
        manager?.notifyTimerStarted(timerID: timer.id)

        // Schedule notification for when timer completes
        let completionTime = Date().addingTimeInterval(TimeInterval(currentTime))
        NotificationService.shared.scheduleTimerCompletion(for: timer, completionTime: completionTime)

        // Start background task to continue running in background
        startBackgroundTask()

        // Persist state for background recovery
        persistState()

        timerCancellable = Foundation.Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Sync state to remote device
        connectivityService?.sendTimerState(timerID: timer.id, action: .started, currentTime: currentTime)
    }

    func pause() {
        guard isRunning else { return }

        isRunning = false
        isPaused = true
        timerCancellable?.cancel()

        // Notify manager that timer stopped
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification since timer is paused
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Persist paused state
        persistState()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Sync state to remote device
        connectivityService?.sendTimerState(timerID: timer.id, action: .paused, currentTime: currentTime)
    }

    func resume() {
        guard isPaused else { return }
        start()
        // Note: sendTimerState for .resumed will be sent by start() as .started
        // If we need explicit .resumed action, add: connectivityService?.sendTimerState(timerID: timer.id, action: .resumed, currentTime: currentTime)
    }

    func reset() {
        isRunning = false
        isPaused = false
        currentTime = totalTime
        startTime = nil
        timerCancellable?.cancel()

        // Notify manager that timer stopped
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Clear persisted state
        clearPersistedState()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Sync state to remote device
        connectivityService?.sendTimerState(timerID: timer.id, action: .reset, currentTime: currentTime)
    }

    private func tick() {
        guard currentTime > 0 else {
            complete()
            return
        }

        currentTime -= 1
    }

    private func complete() {
        isRunning = false
        isPaused = false
        timerCancellable?.cancel()

        // Notify manager that timer stopped
        manager?.notifyTimerStopped(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Clear persisted state
        clearPersistedState()

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Clear badge
        NotificationService.shared.clearBadge()

        // Sync state to remote device
        connectivityService?.sendTimerState(timerID: timer.id, action: .completed, currentTime: 0)
    }

    func cleanup() {
        timerCancellable?.cancel()
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)
        endBackgroundTask()
    }

    // MARK: - Background Task Support

    private func startBackgroundTask() {
        endBackgroundTask() // End any existing task first

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - Remote State Sync Methods

    /// Start timer from remote device (prevents infinite message loops)
    func startFromRemote(currentTime: Int) {
        print("🔄 [TimerService] Starting from remote - currentTime: \(currentTime)")
        guard !isRunning else { return }

        self.currentTime = currentTime
        isRunning = true
        isPaused = false
        startTime = Date()

        // Notify manager to enforce mutual exclusivity
        manager?.notifyTimerStarted(timerID: timer.id)

        // Schedule notification for when timer completes
        let completionTime = Date().addingTimeInterval(TimeInterval(currentTime))
        NotificationService.shared.scheduleTimerCompletion(for: timer, completionTime: completionTime)

        // Start background task
        startBackgroundTask()

        timerCancellable = Foundation.Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Pause timer from remote device
    func pauseFromRemote() {
        print("🔄 [TimerService] Pausing from remote")
        guard isRunning else { return }

        isRunning = false
        isPaused = true
        timerCancellable?.cancel()

        // Notify manager
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Resume timer from remote device
    func resumeFromRemote() {
        print("🔄 [TimerService] Resuming from remote")
        guard isPaused else { return }
        startFromRemote(currentTime: currentTime)
    }

    /// Reset timer from remote device
    func resetFromRemote() {
        print("🔄 [TimerService] Resetting from remote")
        isRunning = false
        isPaused = false
        currentTime = totalTime
        startTime = nil
        timerCancellable?.cancel()

        // Notify manager
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Complete timer from remote device
    func completeFromRemote() {
        print("🔄 [TimerService] Completing from remote")
        isRunning = false
        isPaused = false
        currentTime = 0
        timerCancellable?.cancel()

        // Notify manager
        manager?.notifyTimerStopped(timerID: timer.id)

        // End background task
        endBackgroundTask()

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Clear badge
        NotificationService.shared.clearBadge()
    }

    // MARK: - State Persistence & Restoration

    /// Persist current timer state to database for background/termination recovery
    private func persistState() {
        guard let modelContext = modelContext else {
            print("⚠️ [TimerService] No modelContext available for state persistence")
            return
        }

        do {
            // Find or create runtime state
            let timerID = timer.id
            let descriptor = FetchDescriptor<TimerRuntimeState>(
                predicate: #Predicate { $0.timerID == timerID }
            )
            let existingStates = try modelContext.fetch(descriptor)
            let runtimeState: TimerRuntimeState

            if let existing = existingStates.first {
                runtimeState = existing
            } else {
                runtimeState = TimerRuntimeState(timerID: timer.id)
                modelContext.insert(runtimeState)
            }

            // Update state
            runtimeState.isRunning = isRunning
            runtimeState.isPaused = isPaused
            runtimeState.remainingSeconds = currentTime
            runtimeState.startTimestamp = startTime
            runtimeState.pauseTimestamp = isPaused ? Date() : nil
            runtimeState.lastUpdateTimestamp = Date()

            try modelContext.save()
            print("✅ [TimerService] Persisted state for timer \(timer.id): \(currentTime)s remaining, running: \(isRunning)")
        } catch {
            print("❌ [TimerService] Failed to persist state: \(error.localizedDescription)")
        }
    }

    /// Restore timer state from database (called on init)
    private func restoreStateIfNeeded() {
        guard let modelContext = modelContext else { return }

        do {
            let timerID = timer.id
            let descriptor = FetchDescriptor<TimerRuntimeState>(
                predicate: #Predicate { $0.timerID == timerID }
            )
            let existingStates = try modelContext.fetch(descriptor)

            guard let runtimeState = existingStates.first else {
                print("ℹ️ [TimerService] No saved state found for timer \(timer.id)")
                return
            }

            // Check if timer should have completed while app was backgrounded
            if runtimeState.shouldHaveCompleted {
                print("⏰ [TimerService] Timer \(timer.id) completed while backgrounded")
                handleBackgroundCompletion()
                return
            }

            // Restore state
            if runtimeState.isRunning {
                // Calculate actual remaining time based on elapsed time
                currentTime = runtimeState.calculatedRemainingSeconds
                isRunning = true
                isPaused = false
                startTime = runtimeState.startTimestamp

                // Restart the timer
                print("🔄 [TimerService] Restoring running timer \(timer.id): \(currentTime)s remaining")

                // Notify manager
                manager?.notifyTimerStarted(timerID: timer.id)

                // Reschedule notification
                let completionTime = Date().addingTimeInterval(TimeInterval(currentTime))
                NotificationService.shared.scheduleTimerCompletion(for: timer, completionTime: completionTime)

                // Restart countdown
                timerCancellable = Foundation.Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.tick()
                    }
            } else if runtimeState.isPaused {
                // Restore paused state
                currentTime = runtimeState.remainingSeconds
                isRunning = false
                isPaused = true
                print("⏸️ [TimerService] Restoring paused timer \(timer.id): \(currentTime)s remaining")
            }
        } catch {
            print("❌ [TimerService] Failed to restore state: \(error.localizedDescription)")
        }
    }

    /// Clear persisted state from database (when timer completes or is reset)
    private func clearPersistedState() {
        guard let modelContext = modelContext else { return }

        do {
            let timerID = timer.id
            let descriptor = FetchDescriptor<TimerRuntimeState>(
                predicate: #Predicate { $0.timerID == timerID }
            )
            let existingStates = try modelContext.fetch(descriptor)

            for state in existingStates {
                modelContext.delete(state)
            }

            try modelContext.save()
            print("🗑️ [TimerService] Cleared persisted state for timer \(timer.id)")
        } catch {
            print("❌ [TimerService] Failed to clear state: \(error.localizedDescription)")
        }
    }

    /// Save state when app is about to background
    func saveStateForBackground() {
        if isRunning || isPaused {
            persistState()
        }
    }

    /// Handle timer that completed while app was backgrounded
    private func handleBackgroundCompletion() {
        currentTime = 0
        isRunning = false
        isPaused = false

        // Clear persisted state
        clearPersistedState()

        // Notification was already delivered by iOS, but ensure it's cleared from notification center
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // Clear badge if this was the only active timer
        NotificationService.shared.clearBadge()

        // Notify manager
        manager?.notifyTimerStopped(timerID: timer.id)

        // Sync completion to remote device (Watch)
        connectivityService?.sendTimerState(timerID: timer.id, action: .completed, currentTime: 0)

        print("✅ [TimerService] Timer \(timer.id) marked as completed from background")
    }
}
