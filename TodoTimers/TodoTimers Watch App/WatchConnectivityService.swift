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
            print("✅ [Watch] WCSession is supported")
            session?.delegate = self
            session?.activate()
            print("🔄 [Watch] WCSession activation requested")
        } else {
            print("❌ [Watch] WCSession is NOT supported on this device")
        }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("✅ [Watch] WatchConnectivityService configured with modelContext")
    }

    // MARK: - Sending Methods

    /// Send quick action (todo toggle, note update) to iPhone
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

    /// Request full sync from iPhone
    func requestFullSync() {
        guard let session = session, session.activationState == .activated, session.isReachable else { return }

        let message: [String: Any] = ["type": "syncRequest"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to request sync: \(error.localizedDescription)")
        }
    }

    // MARK: - Receiving Methods

    /// Handle incoming timer update from iPhone
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

    /// Handle full sync from iPhone
    private func handleFullSync(_ data: Data) {
        guard let modelContext = modelContext else { return }

        do {
            let payload = try JSONDecoder().decode(TimerSyncPayload.self, from: data)

            for timerDTO in payload.timers {
                try mergeTimer(timerDTO, in: modelContext)
            }

            // Clean up timers that no longer exist on iPhone
            let receivedIDs = Set(payload.timers.map { $0.id })
            let descriptor = FetchDescriptor<Timer>()
            let allTimers = try modelContext.fetch(descriptor)

            for timer in allTimers where !receivedIDs.contains(timer.id) {
                modelContext.delete(timer)
            }

            try modelContext.save()
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
                mergeTodoItems(existing, dtoTodos: dto.todoItems, in: context)

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
                    sortOrder: dtoTodo.sortOrder,
                    createdAt: dtoTodo.createdAt,
                    updatedAt: dtoTodo.updatedAt
                )
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
                print("❌ [Watch] WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("✅ [Watch] WCSession activation complete - State: \(activationState.rawValue)")
                print("🔍 [Watch] isReachable: \(session.isReachable), isPaired: \(session.isPaired)")

                if activationState == .activated {
                    print("✅ [Watch] Session is activated and ready")
                    // Request initial sync when session activates
                    print("📲 [Watch] Requesting full sync from iPhone...")
                    requestFullSync()
                } else {
                    print("⚠️ [Watch] Session activated but state is NOT .activated (state: \(activationState.rawValue))")
                }
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("📡 [Watch] Reachability changed - isReachable: \(session.isReachable)")

            if session.isReachable {
                print("✅ [Watch] iPhone is now reachable")
                // Request sync when iPhone becomes reachable
                print("📲 [Watch] Requesting full sync from iPhone...")
                requestFullSync()
            } else {
                print("⚠️ [Watch] iPhone is NOT reachable")
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            print("📨 [Watch] Received message from iPhone")

            guard let type = message["type"] as? String else {
                print("⚠️ [Watch] Invalid message format from iPhone")
                return
            }

            print("📨 [Watch] Message type: \(type)")

            // Handle sync request from iPhone (shouldn't happen normally, but handle gracefully)
            if type == "syncRequest" {
                print("⚠️ [Watch] Received syncRequest from iPhone (unexpected)")
                return
            }

            guard let payloadData = message["payload"] as? Data else {
                print("⚠️ [Watch] No payload data in message")
                return
            }

            switch type {
            case "fullSync":
                print("📥 [Watch] Received full sync from iPhone")
                handleFullSync(payloadData)
            case "timerUpdate":
                print("📥 [Watch] Received timer update from iPhone")
                handleTimerUpdate(payloadData)
            default:
                print("⚠️ [Watch] Unknown message type: \(type)")
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
