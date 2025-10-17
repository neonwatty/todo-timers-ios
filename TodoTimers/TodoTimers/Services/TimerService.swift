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

    init(timer: Timer, manager: TimerManager) {
        self.timer = timer
        self.totalTime = timer.durationInSeconds
        self.currentTime = timer.durationInSeconds
        self.manager = manager
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
    }

    func resume() {
        guard isPaused else { return }
        start()
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
}
