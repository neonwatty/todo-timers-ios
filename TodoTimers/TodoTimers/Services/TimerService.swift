import Foundation
import Combine
import UIKit

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

    init(timer: Timer, manager: TimerManager, connectivityService: WatchConnectivityService? = nil) {
        self.timer = timer
        self.totalTime = timer.durationInSeconds
        self.currentTime = timer.durationInSeconds
        self.manager = manager
        self.connectivityService = connectivityService ?? WatchConnectivityService.shared
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
}
