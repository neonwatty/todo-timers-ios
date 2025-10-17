import Foundation
import Combine
import WatchKit
import UserNotifications

@MainActor
@Observable
class WatchTimerService {
    private(set) var currentTime: Int
    private(set) var isRunning = false
    private(set) var isPaused = false

    private let totalTime: Int
    private let timer: Timer
    private var timerCancellable: AnyCancellable?
    private weak var manager: WatchTimerManager?

    init(timer: Timer, manager: WatchTimerManager) {
        self.timer = timer
        self.totalTime = timer.durationInSeconds
        self.currentTime = timer.durationInSeconds
        self.manager = manager
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        isPaused = false

        // Notify manager to enforce mutual exclusivity
        manager?.notifyTimerStarted(timerID: timer.id)

        // Schedule local notification for timer completion
        scheduleNotification()

        timerCancellable = Foundation.Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        guard isRunning else { return }

        isRunning = false
        isPaused = true
        timerCancellable?.cancel()

        // Notify manager that timer stopped
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification
        cancelNotification()

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
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

        // Notify manager that timer stopped
        manager?.notifyTimerStopped(timerID: timer.id)

        // Cancel notification
        cancelNotification()

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
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

        // Haptic feedback (more pronounced for completion)
        WKInterfaceDevice.current().play(.success)

        // Additional haptic pattern for timer completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.notification)
        }
    }

    func cleanup() {
        timerCancellable?.cancel()
        cancelNotification()
    }

    // MARK: - Notification Support

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()

        // Request permission first
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Timer Complete!"
                content.body = "\(self.timer.name) has finished"
                content.sound = .defaultCritical

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(self.currentTime),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "timer-\(self.timer.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule Watch notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["timer-\(timer.id.uuidString)"])
    }
}
