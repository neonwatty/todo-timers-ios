# Watch Connectivity - Sync Strategy

## Overview

This document details the Watch Connectivity Framework implementation for syncing timer data between iPhone and Apple Watch. The strategy ensures real-time updates while handling offline scenarios gracefully.

---

## Watch Connectivity Framework Basics

### Key Concepts

**WCSession**
- Singleton session object managing all communication
- Must activate on both iPhone and Apple Watch
- Monitors reachability and activation state

**Communication Methods**
1. **Application Context** - Latest state transfer
2. **User Info Transfer** - Guaranteed delivery queue
3. **Interactive Messaging** - Real-time bidirectional
4. **File Transfer** - Large data (not needed for this app)

**Reachability**
- Devices must be paired and in Bluetooth range
- Some methods work when unreachable (queued delivery)
- Others require immediate reachability

---

## Architecture

### Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                           iPhone (Primary)                       │
│                                                                  │
│  ┌────────────┐      ┌──────────────────┐      ┌────────────┐  │
│  │  SwiftUI   │─────▶│   ViewModel      │─────▶│ SwiftData  │  │
│  │   Views    │◀─────│                  │◀─────│  (Source)  │  │
│  └────────────┘      └──────────────────┘      └────────────┘  │
│                               │                                  │
│                               │                                  │
│                      ┌────────▼────────┐                        │
│                      │ WatchConnectivity│                       │
│                      │    Service       │                       │
│                      └────────┬────────┘                        │
└───────────────────────────────┼─────────────────────────────────┘
                                │
                         WCSession (Bluetooth)
                                │
┌───────────────────────────────┼─────────────────────────────────┐
│                      ┌────────▼────────┐                        │
│                      │ WatchConnectivity│                       │
│                      │    Service       │                       │
│                      └────────┬────────┘                        │
│                               │                                  │
│  ┌────────────┐      ┌──────────────────┐      ┌────────────┐  │
│  │  SwiftUI   │─────▶│   ViewModel      │─────▶│ SwiftData  │  │
│  │   Views    │◀─────│                  │◀─────│  (Cache)   │  │
│  └────────────┘      └──────────────────┘      └────────────┘  │
│                                                                  │
│                        Apple Watch (Secondary)                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## WatchConnectivityService Implementation

### Service Structure

```swift
import WatchConnectivity
import SwiftData
import Combine

@Observable
class WatchConnectivityService: NSObject {
    // Singleton instance
    static let shared = WatchConnectivityService()

    // Session
    private var session: WCSession?

    // State
    var isReachable = false
    var isPaired = false
    var isWatchAppInstalled = false

    // Model context (injected)
    private var modelContext: ModelContext?

    // Private initializer
    private override init() {
        super.init()
        setupSession()
    }

    // Setup
    func setupSession() {
        guard WCSession.isSupported() else { return }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // Inject model context
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
}
```

---

## Communication Strategies

### 1. Application Context (Bulk Sync)

**Use Case**: Send complete timer list from iPhone to Watch

**Characteristics**:
- Replaces previous context (only latest data retained)
- Delivered when counterpart becomes reachable
- Not guaranteed to deliver every update
- Best for: Initial sync, periodic full refresh

**Implementation**:

```swift
// iPhone → Watch: Send all timers
extension WatchConnectivityService {
    func syncAllTimers(_ timers: [Timer]) {
        guard let session = session, session.activationState == .activated else {
            print("Session not ready")
            return
        }

        do {
            let payload = TimerSyncPayload(
                timers: timers.map { TimerDTO(from: $0) },
                syncTimestamp: Date()
            )
            let data = try JSONEncoder().encode(payload)
            let context = ["timersData": data]

            try session.updateApplicationContext(context)
            print("✅ Sent \(timers.count) timers via application context")
        } catch {
            print("❌ Failed to send application context: \(error)")
        }
    }
}

// Watch: Receive all timers
extension WatchConnectivityService: WCSessionDelegate {
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["timersData"] as? Data,
              let modelContext = modelContext else {
            return
        }

        do {
            let payload = try JSONDecoder().decode(TimerSyncPayload.self, from: data)

            // Update local database
            Task { @MainActor in
                await updateLocalTimers(payload.timers, context: modelContext)
            }
        } catch {
            print("❌ Failed to decode application context: \(error)")
        }
    }
}
```

---

### 2. Interactive Messaging (Real-time Updates)

**Use Case**: Immediate updates (to-do toggled, timer created/deleted)

**Characteristics**:
- Requires both devices reachable and active
- Bidirectional with reply handler
- Immediate delivery or error
- Best for: User actions requiring instant feedback

**Implementation**:

```swift
// Send interactive message
extension WatchConnectivityService {
    func sendTimerUpdate(
        _ timer: Timer,
        type: TimerUpdateMessage.UpdateType,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let session = session,
              session.isReachable else {
            completion?(.failure(WCError(.sessionNotActivated)))
            return
        }

        do {
            let message = TimerUpdateMessage(
                type: type,
                timer: type != .deleted ? TimerDTO(from: timer) : nil,
                timerID: timer.id
            )
            let data = try JSONEncoder().encode(message)
            let payload = ["timerUpdate": data]

            session.sendMessage(payload, replyHandler: { reply in
                if let success = reply["success"] as? Bool, success {
                    completion?(.success(()))
                } else {
                    completion?(.failure(WCError(.messageReplyFailed)))
                }
            }, errorHandler: { error in
                completion?(.failure(error))
            })
        } catch {
            completion?(.failure(error))
        }
    }

    func sendQuickAction(
        action: QuickActionMessage.Action,
        timerID: UUID,
        todoID: UUID? = nil,
        todoCompleted: Bool? = nil
    ) {
        guard let session = session,
              session.isReachable else {
            // Fallback to user info transfer for guaranteed delivery
            return sendQuickActionUserInfo(
                action: action,
                timerID: timerID,
                todoID: todoID,
                todoCompleted: todoCompleted
            )
        }

        do {
            let message = QuickActionMessage(
                action: action,
                timerID: timerID,
                todoID: todoID,
                todoCompleted: todoCompleted,
                noteText: nil
            )
            let data = try JSONEncoder().encode(message)
            let payload = ["quickAction": data]

            session.sendMessage(payload, replyHandler: nil, errorHandler: { error in
                print("❌ Quick action failed: \(error)")
            })
        } catch {
            print("❌ Failed to encode quick action: \(error)")
        }
    }
}

// Receive interactive message
extension WatchConnectivityService {
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Handle timer update
        if let data = message["timerUpdate"] as? Data {
            handleTimerUpdate(data, replyHandler: replyHandler)
        }
        // Handle quick action
        else if let data = message["quickAction"] as? Data {
            handleQuickAction(data)
            replyHandler(["success": true])
        }
    }

    private func handleTimerUpdate(
        _ data: Data,
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let modelContext = modelContext else {
            replyHandler(["success": false, "error": "No model context"])
            return
        }

        do {
            let update = try JSONDecoder().decode(TimerUpdateMessage.self, from: data)

            Task { @MainActor in
                switch update.type {
                case .created:
                    if let timerDTO = update.timer {
                        let timer = timerDTO.toModel()
                        modelContext.insert(timer)
                        try? modelContext.save()
                    }

                case .updated:
                    if let timerDTO = update.timer {
                        await updateTimer(timerDTO, context: modelContext)
                    }

                case .deleted:
                    await deleteTimer(id: update.timerID, context: modelContext)
                }

                replyHandler(["success": true])
            }
        } catch {
            replyHandler(["success": false, "error": error.localizedDescription])
        }
    }

    private func handleQuickAction(_ data: Data) {
        guard let modelContext = modelContext else { return }

        do {
            let action = try JSONDecoder().decode(QuickActionMessage.self, from: data)

            Task { @MainActor in
                switch action.action {
                case .todoToggled:
                    if let todoID = action.todoID,
                       let completed = action.todoCompleted {
                        await toggleTodo(
                            timerID: action.timerID,
                            todoID: todoID,
                            completed: completed,
                            context: modelContext
                        )
                    }

                case .noteUpdated:
                    if let noteText = action.noteText {
                        await updateNote(
                            timerID: action.timerID,
                            noteText: noteText,
                            context: modelContext
                        )
                    }
                }
            }
        } catch {
            print("❌ Failed to handle quick action: \(error)")
        }
    }
}
```

---

### 3. User Info Transfer (Guaranteed Delivery)

**Use Case**: Non-urgent updates when devices not immediately reachable

**Characteristics**:
- Queued delivery (guaranteed eventually)
- Works when devices not reachable
- Delivered when Watch becomes reachable
- Best for: Notes updates, non-critical edits

**Implementation**:

```swift
extension WatchConnectivityService {
    func sendQuickActionUserInfo(
        action: QuickActionMessage.Action,
        timerID: UUID,
        todoID: UUID? = nil,
        todoCompleted: Bool? = nil
    ) {
        guard let session = session else { return }

        do {
            let message = QuickActionMessage(
                action: action,
                timerID: timerID,
                todoID: todoID,
                todoCompleted: todoCompleted,
                noteText: nil
            )
            let data = try JSONEncoder().encode(message)
            let userInfo = ["quickAction": data]

            session.transferUserInfo(userInfo)
            print("✅ Queued quick action for delivery")
        } catch {
            print("❌ Failed to queue user info: \(error)")
        }
    }
}

extension WatchConnectivityService {
    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        if let data = userInfo["quickAction"] as? Data {
            handleQuickAction(data)
        }
    }
}
```

---

## Database Update Helpers

### iPhone & Watch (Shared Logic)

```swift
extension WatchConnectivityService {
    @MainActor
    func updateLocalTimers(_ timerDTOs: [TimerDTO], context: ModelContext) async {
        // Fetch existing timers
        let descriptor = FetchDescriptor<Timer>()
        let existingTimers = (try? context.fetch(descriptor)) ?? []

        // Create ID map
        var existingMap = Dictionary(
            uniqueKeysWithValues: existingTimers.map { ($0.id, $0) }
        )

        for dto in timerDTOs {
            if let existing = existingMap[dto.id] {
                // Update existing - only if incoming is newer
                if dto.updatedAt > existing.updatedAt {
                    updateTimerProperties(existing, from: dto)
                }
            } else {
                // Insert new
                let timer = dto.toModel()
                context.insert(timer)
            }
        }

        // Optionally delete timers not in sync (commented out - be careful!)
        // let syncedIDs = Set(timerDTOs.map { $0.id })
        // for existing in existingTimers where !syncedIDs.contains(existing.id) {
        //     context.delete(existing)
        // }

        try? context.save()
    }

    @MainActor
    func updateTimer(_ dto: TimerDTO, context: ModelContext) async {
        let predicate = #Predicate<Timer> { $0.id == dto.id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let existing = try? context.fetch(descriptor).first else {
            // Doesn't exist - insert
            let timer = dto.toModel()
            context.insert(timer)
            try? context.save()
            return
        }

        // Only update if incoming is newer
        guard dto.updatedAt > existing.updatedAt else { return }

        updateTimerProperties(existing, from: dto)
        try? context.save()
    }

    @MainActor
    func deleteTimer(id: UUID, context: ModelContext) async {
        let predicate = #Predicate<Timer> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let timer = try? context.fetch(descriptor).first else { return }

        context.delete(timer)
        try? context.save()
    }

    @MainActor
    func toggleTodo(
        timerID: UUID,
        todoID: UUID,
        completed: Bool,
        context: ModelContext
    ) async {
        let predicate = #Predicate<TodoItem> { $0.id == todoID }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let todo = try? context.fetch(descriptor).first else { return }

        todo.isCompleted = completed
        todo.updatedAt = Date()
        todo.timer?.updatedAt = Date()

        try? context.save()
    }

    @MainActor
    func updateNote(
        timerID: UUID,
        noteText: String,
        context: ModelContext
    ) async {
        let predicate = #Predicate<Timer> { $0.id == timerID }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let timer = try? context.fetch(descriptor).first else { return }

        timer.notes = noteText
        timer.updatedAt = Date()

        try? context.save()
    }

    private func updateTimerProperties(_ timer: Timer, from dto: TimerDTO) {
        timer.name = dto.name
        timer.durationInSeconds = dto.durationInSeconds
        timer.icon = dto.icon
        timer.colorHex = dto.colorHex
        timer.notes = dto.notes
        timer.updatedAt = dto.updatedAt

        // Update todos
        let existingTodoMap = Dictionary(
            uniqueKeysWithValues: timer.todoItems.map { ($0.id, $0) }
        )

        var updatedTodos: [TodoItem] = []

        for todoDTO in dto.todoItems {
            if let existing = existingTodoMap[todoDTO.id] {
                // Update existing todo
                existing.text = todoDTO.text
                existing.isCompleted = todoDTO.isCompleted
                existing.sortOrder = todoDTO.sortOrder
                existing.updatedAt = todoDTO.updatedAt
                updatedTodos.append(existing)
            } else {
                // Create new todo
                let newTodo = todoDTO.toModel()
                updatedTodos.append(newTodo)
            }
        }

        timer.todoItems = updatedTodos
    }
}
```

---

## WCSessionDelegate Implementation

### Full Delegate (iPhone)

```swift
extension WatchConnectivityService: WCSessionDelegate {
    // MARK: - Activation

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("❌ WCSession activation failed: \(error)")
            return
        }

        print("✅ WCSession activated: \(activationState.rawValue)")

        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    // iPhone-specific
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession deactivated - reactivating")
        session.activate()
    }

    // MARK: - Reachability

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📡 Reachability changed: \(session.isReachable)")
        }

        // Sync when becomes reachable
        if session.isReachable {
            // Trigger full sync from ViewModel
            NotificationCenter.default.post(name: .watchBecameReachable, object: nil)
        }
    }

    // MARK: - Data Receiving (implemented above)
    // - didReceiveApplicationContext
    // - didReceiveMessage
    // - didReceiveUserInfo
}

extension Notification.Name {
    static let watchBecameReachable = Notification.Name("watchBecameReachable")
}
```

### Full Delegate (watchOS)

```swift
extension WatchConnectivityService: WCSessionDelegate {
    // MARK: - Activation

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("❌ WCSession activation failed: \(error)")
            return
        }

        print("✅ WCSession activated: \(activationState.rawValue)")

        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // MARK: - Reachability

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📡 Reachability changed: \(session.isReachable)")
        }
    }

    // MARK: - Data Receiving (same as iPhone)
    // - didReceiveApplicationContext
    // - didReceiveMessage
    // - didReceiveUserInfo
}
```

---

## Integration with ViewModels

### iPhone ViewModel Example

```swift
@Observable
class TimerListViewModel {
    var timers: [Timer] = []

    private let modelContext: ModelContext
    private let connectivityService = WatchConnectivityService.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        connectivityService.setModelContext(modelContext)

        fetchTimers()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .watchBecameReachable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncToWatch()
        }
    }

    func syncToWatch() {
        connectivityService.syncAllTimers(timers)
    }

    func createTimer(_ timer: Timer) {
        modelContext.insert(timer)
        try? modelContext.save()

        timers.append(timer)

        // Notify Watch
        connectivityService.sendTimerUpdate(timer, type: .created)
    }

    func deleteTimer(_ timer: Timer) {
        modelContext.delete(timer)
        try? modelContext.save()

        timers.removeAll { $0.id == timer.id }

        // Notify Watch
        connectivityService.sendTimerUpdate(timer, type: .deleted)
    }
}
```

---

## Conflict Resolution Strategy

### Last-Write-Wins with Timestamp

- Every model has `updatedAt` timestamp
- When receiving update, compare timestamps
- Only apply if incoming `updatedAt > local updatedAt`
- iPhone breaks ties (if timestamps equal, iPhone wins)

### Example

```swift
@MainActor
func mergeTimer(_ incomingDTO: TimerDTO, existing: Timer) async {
    // Timestamp comparison
    if incomingDTO.updatedAt > existing.updatedAt {
        // Incoming is newer - apply update
        updateTimerProperties(existing, from: incomingDTO)
    } else if incomingDTO.updatedAt < existing.updatedAt {
        // Local is newer - send to counterpart
        // (Only on iPhone - it's the primary)
        #if os(iOS)
        WatchConnectivityService.shared.sendTimerUpdate(existing, type: .updated)
        #endif
    } else {
        // Equal timestamps - iPhone wins (already has correct data)
        #if os(watchOS)
        // Watch should accept iPhone's version
        updateTimerProperties(existing, from: incomingDTO)
        #endif
    }
}
```

---

## Error Handling

### Common Errors

```swift
enum ConnectivityError: LocalizedError {
    case sessionNotAvailable
    case deviceNotReachable
    case encodingFailed
    case decodingFailed
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .sessionNotAvailable:
            return "Watch Connectivity session not available"
        case .deviceNotReachable:
            return "Device not reachable. Update will sync when connection restored."
        case .encodingFailed:
            return "Failed to encode data for sync"
        case .decodingFailed:
            return "Failed to decode received data"
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}
```

### Graceful Degradation

```swift
extension WatchConnectivityService {
    func sendUpdateWithFallback(
        _ timer: Timer,
        type: TimerUpdateMessage.UpdateType
    ) {
        // Try interactive message first (fast)
        if session?.isReachable == true {
            sendTimerUpdate(timer, type: type) { result in
                if case .failure = result {
                    // Fallback to user info (guaranteed)
                    self.sendTimerUpdateUserInfo(timer, type: type)
                }
            }
        } else {
            // Not reachable - use guaranteed delivery
            sendTimerUpdateUserInfo(timer, type: type)
        }
    }

    private func sendTimerUpdateUserInfo(
        _ timer: Timer,
        type: TimerUpdateMessage.UpdateType
    ) {
        // Similar to sendTimerUpdate but uses transferUserInfo
        // Implementation omitted for brevity
    }
}
```

---

## Testing Strategy

### Simulator Testing

**Paired Watch Simulator**
- Xcode allows pairing iPhone and Watch simulators
- Basic WCSession communication works
- Limited: No background transfers in simulator

**Steps**:
1. Open Xcode → Window → Devices and Simulators
2. Select Watch simulator
3. Pair with iPhone simulator
4. Run both apps

### Real Device Testing (Required)

**Scenarios to Test**:
- [x] Devices in range, both apps active
- [x] Devices in range, one app backgrounded
- [x] Devices out of range (walk away with iPhone)
- [x] Airplane mode on one device
- [x] Create timer on iPhone → appears on Watch
- [x] Toggle to-do on Watch → updates iPhone
- [x] Delete timer on iPhone → removes from Watch
- [x] Edit timer on iPhone → updates Watch
- [x] Rapid updates (stress test)
- [x] Connection interrupted mid-transfer

### Debug Logging

```swift
extension WatchConnectivityService {
    func logSessionState() {
        guard let session = session else {
            print("📱 No session")
            return
        }

        print("""
        📱 WCSession State:
           - Activation: \(session.activationState.rawValue)
           - Reachable: \(session.isReachable)
           - Paired: \(session.isPaired)
           - Watch App Installed: \(session.isWatchAppInstalled)
           - Remaining ComplicationUserInfo Transfers: \(session.remainingComplicationUserInfoTransfers)
        """)
    }
}
```

---

## Best Practices

### Performance

1. **Minimize payloads**: Only send necessary data
2. **Batch updates**: Group related changes into single message
3. **Throttle syncs**: Don't sync on every keystroke (use debounce)
4. **Background transfers**: Use for non-urgent updates

### Reliability

1. **Always have fallback**: Interactive message → User info transfer
2. **Handle offline**: Queue operations, sync when reachable
3. **Idempotent operations**: Same update applied twice = same result
4. **Validate data**: Check received data before applying

### UX Considerations

1. **Show sync status**: Indicator when syncing
2. **Optimistic updates**: Update UI immediately, sync in background
3. **Handle failures gracefully**: Don't block user on sync errors
4. **Offline mode**: App fully functional when disconnected

---

## Next Steps

See iOS and watchOS mockups and view structure documentation for UI implementation details.
