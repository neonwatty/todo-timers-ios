import Foundation
import WatchConnectivity
import SwiftData

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isReachable = false

    private var modelContext: ModelContext?
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()

        // Debug: Check if WCSession is supported
        if WCSession.isSupported() {
            print("✅ [iPhone] WCSession is supported")
            session?.delegate = self
            session?.activate()
            print("🔄 [iPhone] WCSession activation requested")
        } else {
            print("❌ [iPhone] WCSession is NOT supported on this device")
        }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("✅ [iPhone] WatchConnectivityService configured with modelContext")
    }

    // MARK: - Sending Methods

    /// Send full sync of all timers to Watch
    func sendFullSync() {
        guard let session = session, session.activationState == .activated else { return }
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<Timer>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let timers = try modelContext.fetch(descriptor)

            let timerDTOs = timers.map { TimerDTO(from: $0) }
            let payload = TimerSyncPayload(timers: timerDTOs, syncTimestamp: Date())

            let data = try JSONEncoder().encode(payload)
            let message: [String: Any] = ["type": "fullSync", "payload": data]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    print("Failed to send full sync: \(error.localizedDescription)")
                }
            } else {
                // Use application context for background delivery
                try session.updateApplicationContext(message)
            }
        } catch {
            print("Failed to send full sync: \(error.localizedDescription)")
        }
    }

    /// Send single timer update to Watch
    func sendTimerUpdate(_ timer: Timer, type: TimerUpdateMessage.UpdateType) {
        guard let session = session, session.activationState == .activated else { return }

        do {
            let timerDTO = type == .deleted ? nil : TimerDTO(from: timer)
            let update = TimerUpdateMessage(type: type, timer: timerDTO, timerID: timer.id)

            let data = try JSONEncoder().encode(update)
            let message: [String: Any] = ["type": "timerUpdate", "payload": data]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    print("Failed to send timer update: \(error.localizedDescription)")
                }
            } else {
                try session.updateApplicationContext(message)
            }
        } catch {
            print("Failed to send timer update: \(error.localizedDescription)")
        }
    }

    /// Send quick action (todo toggle, note update) to Watch
    func sendQuickAction(action: QuickActionMessage.Action, timerID: UUID, todoID: UUID? = nil, todoCompleted: Bool? = nil, noteText: String? = nil) {
        guard let session = session, session.activationState == .activated, session.isReachable else { return }

        do {
            let quickAction = QuickActionMessage(
                action: action,
                timerID: timerID,
                todoID: todoID,
                todoCompleted: todoCompleted,
                noteText: noteText
            )

            let data = try JSONEncoder().encode(quickAction)
            let message: [String: Any] = ["type": "quickAction", "payload": data]

            session.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send quick action: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to send quick action: \(error.localizedDescription)")
        }
    }

    // MARK: - Receiving Methods

    /// Handle incoming timer update from Watch
    private func handleTimerUpdate(_ data: Data) {
        guard let modelContext = modelContext else { return }

        do {
            let update = try JSONDecoder().decode(TimerUpdateMessage.self, from: data)

            switch update.type {
            case .created, .updated:
                guard let timerDTO = update.timer else { return }
                try mergeTimer(timerDTO, in: modelContext)

            case .deleted:
                let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == update.timerID })
                if let existingTimer = try modelContext.fetch(descriptor).first {
                    modelContext.delete(existingTimer)
                    try modelContext.save()
                }
            }
        } catch {
            print("Failed to handle timer update: \(error.localizedDescription)")
        }
    }

    /// Handle incoming quick action from Watch
    private func handleQuickAction(_ data: Data) {
        guard let modelContext = modelContext else { return }

        do {
            let action = try JSONDecoder().decode(QuickActionMessage.self, from: data)

            let timerDescriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == action.timerID })
            guard let timer = try modelContext.fetch(timerDescriptor).first else { return }

            switch action.action {
            case .todoToggled:
                guard let todoID = action.todoID, let completed = action.todoCompleted else { return }
                let todoDescriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == todoID })
                if let todo = try modelContext.fetch(todoDescriptor).first {
                    todo.isCompleted = completed
                    todo.updatedAt = Date()
                    timer.updatedAt = Date()
                    try modelContext.save()
                }

            case .noteUpdated:
                guard let noteText = action.noteText else { return }
                timer.notes = noteText
                timer.updatedAt = Date()
                try modelContext.save()
            }
        } catch {
            print("Failed to handle quick action: \(error.localizedDescription)")
        }
    }

    /// Handle full sync from Watch
    private func handleFullSync(_ data: Data) {
        guard let modelContext = modelContext else { return }

        do {
            let payload = try JSONDecoder().decode(TimerSyncPayload.self, from: data)

            for timerDTO in payload.timers {
                try mergeTimer(timerDTO, in: modelContext)
            }
        } catch {
            print("Failed to handle full sync: \(error.localizedDescription)")
        }
    }

    // MARK: - Database Helpers

    /// Merge timer with conflict resolution (last-write-wins)
    private func mergeTimer(_ dto: TimerDTO, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Timer>(predicate: #Predicate { $0.id == dto.id })
        let existingTimer = try context.fetch(descriptor).first

        if let existing = existingTimer {
            // Conflict resolution: compare timestamps
            if dto.updatedAt > existing.updatedAt {
                // Incoming data is newer, update existing
                existing.name = dto.name
                existing.durationInSeconds = dto.durationInSeconds
                existing.icon = dto.icon
                existing.colorHex = dto.colorHex
                existing.notes = dto.notes
                existing.updatedAt = dto.updatedAt

                // Update todo items
                try mergeTodoItems(existing, dtoTodos: dto.todoItems, in: context)

                try context.save()
            }
            // else: existing data is newer or equal, keep it
        } else {
            // New timer, insert it
            let newTimer = dto.toModel()
            context.insert(newTimer)
            try context.save()
        }
    }

    /// Merge todo items for a timer
    private func mergeTodoItems(_ timer: Timer, dtoTodos: [TodoItemDTO], in context: ModelContext) throws {
        // Build map of existing todos by ID
        var existingTodos: [UUID: TodoItem] = [:]
        for todo in timer.todoItems {
            existingTodos[todo.id] = todo
        }

        // Track which IDs we've seen in the DTO
        var dtoIDs = Set<UUID>()

        for dtoTodo in dtoTodos {
            dtoIDs.insert(dtoTodo.id)

            if let existing = existingTodos[dtoTodo.id] {
                // Existing todo, check timestamps
                if dtoTodo.updatedAt > existing.updatedAt {
                    existing.text = dtoTodo.text
                    existing.isCompleted = dtoTodo.isCompleted
                    existing.sortOrder = dtoTodo.sortOrder
                    existing.updatedAt = dtoTodo.updatedAt
                }
            } else {
                // New todo, create it
                let newTodo = TodoItem(
                    id: dtoTodo.id,
                    text: dtoTodo.text,
                    isCompleted: dtoTodo.isCompleted,
                    sortOrder: dtoTodo.sortOrder
                )
                newTodo.createdAt = dtoTodo.createdAt
                newTodo.updatedAt = dtoTodo.updatedAt
                timer.todoItems.append(newTodo)
            }
        }

        // Remove todos that no longer exist in DTO
        for (id, todo) in existingTodos where !dtoIDs.contains(id) {
            if let index = timer.todoItems.firstIndex(where: { $0.id == id }) {
                timer.todoItems.remove(at: index)
            }
            context.delete(todo)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ [iPhone] WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("✅ [iPhone] WCSession activation complete - State: \(activationState.rawValue)")
                print("🔍 [iPhone] isReachable: \(session.isReachable), isPaired: \(session.isPaired)")

                if activationState == .activated {
                    print("✅ [iPhone] Session is activated and ready")
                } else {
                    print("⚠️ [iPhone] Session activated but state is NOT .activated (state: \(activationState.rawValue))")
                }
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // iOS only
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // iOS only - reactivate for switch to new watch
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("📡 [iPhone] Reachability changed - isReachable: \(session.isReachable)")

            if session.isReachable {
                print("✅ [iPhone] Watch is now reachable")
            } else {
                print("⚠️ [iPhone] Watch is NOT reachable")
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            print("📨 [iPhone] Received message from Watch")

            guard let type = message["type"] as? String,
                  let payloadData = message["payload"] as? Data else {
                print("⚠️ [iPhone] Invalid message format from Watch")
                return
            }

            print("📨 [iPhone] Message type: \(type)")

            switch type {
            case "syncRequest":
                print("📲 [iPhone] Watch requested full sync - sending timers")
                sendFullSync()
            case "fullSync":
                print("📥 [iPhone] Received full sync from Watch")
                handleFullSync(payloadData)
            case "timerUpdate":
                print("📥 [iPhone] Received timer update from Watch")
                handleTimerUpdate(payloadData)
            case "quickAction":
                print("📥 [iPhone] Received quick action from Watch")
                handleQuickAction(payloadData)
            default:
                print("⚠️ [iPhone] Unknown message type: \(type)")
                break
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            guard let type = applicationContext["type"] as? String,
                  let payloadData = applicationContext["payload"] as? Data else { return }

            switch type {
            case "fullSync":
                handleFullSync(payloadData)
            case "timerUpdate":
                handleTimerUpdate(payloadData)
            default:
                break
            }
        }
    }
}
