import SwiftUI
import SwiftData

@MainActor
@Observable
class NotificationHandler {
    var selectedTimerID: UUID?

    private var modelContext: ModelContext?

    init() {
        setupNotificationObservers()
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func setupNotificationObservers() {
        // Open timer detail when notification is tapped
        NotificationCenter.default.addObserver(
            forName: .openTimerFromNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let timerID = notification.userInfo?["timerID"] as? UUID else { return }
            self?.selectedTimerID = timerID
        }

        // Restart timer from notification action
        NotificationCenter.default.addObserver(
            forName: .restartTimerFromNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let timerID = notification.userInfo?["timerID"] as? UUID else { return }
            self?.restartTimer(timerID: timerID)
        }

        // Mark timer complete (clear all todos) from notification action
        NotificationCenter.default.addObserver(
            forName: .markTimerCompleteFromNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let timerID = notification.userInfo?["timerID"] as? UUID else { return }
            self?.markTimerComplete(timerID: timerID)
        }
    }

    private func restartTimer(timerID: UUID) {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timerID })
            guard let timer = try modelContext.fetch(descriptor).first else { return }

            // Navigate to timer and start it
            selectedTimerID = timerID

            // Post notification to start timer (TimerDetailView will handle)
            NotificationCenter.default.post(
                name: .startTimerFromNotification,
                object: nil,
                userInfo: ["timerID": timerID]
            )
        } catch {
            print("Failed to restart timer: \(error.localizedDescription)")
        }
    }

    private func markTimerComplete(timerID: UUID) {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == timerID })
            guard let timer = try modelContext.fetch(descriptor).first else { return }

            // Mark all todos as complete
            for todo in timer.todoItems {
                todo.isCompleted = true
                todo.updatedAt = Date()
            }

            try modelContext.save()

            // Send haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)

        } catch {
            print("Failed to mark timer complete: \(error.localizedDescription)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let startTimerFromNotification = Notification.Name("startTimerFromNotification")
}
