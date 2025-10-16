import Foundation
import Combine
import UIKit

@Observable
class TimerService {
    private(set) var currentTime: Int
    private(set) var isRunning = false
    private(set) var isPaused = false

    private let totalTime: Int
    private var timerCancellable: AnyCancellable?

    init(timer: Timer) {
        self.totalTime = timer.durationInSeconds
        self.currentTime = timer.durationInSeconds
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        isPaused = false

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
        timerCancellable?.cancel()

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

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // TODO: Send notification (Phase 6 - Notifications)
        // NotificationService.shared.sendTimerCompleteNotification()
    }

    func cleanup() {
        timerCancellable?.cancel()
    }
}
