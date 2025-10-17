import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifiers
    private enum NotificationIdentifier {
        static func timerCompletion(timerID: UUID) -> String {
            "timer-complete-\(timerID.uuidString)"
        }
    }

    // Notification categories
    private enum NotificationCategory {
        static let timerCompletion = "TIMER_COMPLETION"
    }

    // Notification actions
    private enum NotificationAction {
        static let restart = "RESTART_TIMER"
        static let markComplete = "MARK_COMPLETE"
        static let dismiss = "DISMISS"
    }

    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        Task {
            await checkPermissionStatus()
        }
    }

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkPermissionStatus()
            return granted
        } catch {
            print("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    // MARK: - Notification Scheduling

    func scheduleTimerCompletion(for timer: Timer, completionTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "\(timer.name) has finished"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.timerCompletion

        // Add timer ID to userInfo for action handling
        content.userInfo = [
            "timerID": timer.id.uuidString,
            "timerName": timer.name
        ]

        // Add badge (optional - can show count of completed timers)
        content.badge = 1

        // Create trigger based on completion time
        let timeInterval = completionTime.timeIntervalSinceNow
        guard timeInterval > 0 else {
            // Timer already completed, send immediately
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(
                identifier: NotificationIdentifier.timerCompletion(timerID: timer.id),
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.timerCompletion(timerID: timer.id),
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Scheduled timer completion notification for \(timer.name) at \(completionTime)")
            }
        }
    }

    func cancelTimerNotification(timerID: UUID) {
        let identifier = NotificationIdentifier.timerCompletion(timerID: timerID)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled notification for timer: \(timerID)")
    }

    func cancelAllTimerNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Badge Management

    func updateBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: - Notification Categories

    private func setupNotificationCategories() {
        // Create actions
        let restartAction = UNNotificationAction(
            identifier: NotificationAction.restart,
            title: "Restart Timer",
            options: [.foreground]
        )

        let markCompleteAction = UNNotificationAction(
            identifier: NotificationAction.markComplete,
            title: "Mark Complete",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss,
            title: "Dismiss",
            options: [.destructive]
        )

        // Create category
        let timerCompletionCategory = UNNotificationCategory(
            identifier: NotificationCategory.timerCompletion,
            actions: [restartAction, markCompleteAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Register categories
        notificationCenter.setNotificationCategories([timerCompletionCategory])
    }

    // MARK: - Action Handlers

    private func handleRestartTimer(timerID: UUID) {
        print("Restart timer action: \(timerID)")
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .restartTimerFromNotification,
            object: nil,
            userInfo: ["timerID": timerID]
        )
    }

    private func handleMarkComplete(timerID: UUID) {
        print("Mark complete action: \(timerID)")
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .markTimerCompleteFromNotification,
            object: nil,
            userInfo: ["timerID": timerID]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap and actions
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        guard let timerIDString = userInfo["timerID"] as? String,
              let timerID = UUID(uuidString: timerIDString) else {
            completionHandler()
            return
        }

        Task { @MainActor in
            switch response.actionIdentifier {
            case NotificationAction.restart:
                handleRestartTimer(timerID: timerID)

            case NotificationAction.markComplete:
                handleMarkComplete(timerID: timerID)

            case UNNotificationDefaultActionIdentifier:
                // User tapped notification, open timer detail
                NotificationCenter.default.post(
                    name: .openTimerFromNotification,
                    object: nil,
                    userInfo: ["timerID": timerID]
                )

            case NotificationAction.dismiss, UNNotificationDismissActionIdentifier:
                // User dismissed notification
                break

            default:
                break
            }

            completionHandler()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openTimerFromNotification = Notification.Name("openTimerFromNotification")
    static let restartTimerFromNotification = Notification.Name("restartTimerFromNotification")
    static let markTimerCompleteFromNotification = Notification.Name("markTimerCompleteFromNotification")
}
