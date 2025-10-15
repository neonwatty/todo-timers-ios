# Data Model - SwiftData Schema

## Overview

This document defines the SwiftData models for the Timer app, including relationships, properties, and serialization strategies for Watch Connectivity sync.

---

## Core Models

### Timer Model

```swift
import SwiftData
import Foundation

@Model
final class Timer {
    // Identifiers
    @Attribute(.unique) var id: UUID

    // Timer Properties
    var name: String
    var durationInSeconds: Int  // Total duration
    var icon: String            // SF Symbol name
    var colorHex: String        // Hex color code for UI

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.timer)
    var todoItems: [TodoItem] = []

    var notes: String?

    // Computed Properties (not persisted)
    var hours: Int {
        durationInSeconds / 3600
    }

    var minutes: Int {
        (durationInSeconds % 3600) / 60
    }

    var seconds: Int {
        durationInSeconds % 60
    }

    var formattedDuration: String {
        let h = hours
        let m = minutes
        let s = seconds

        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    // Initializer
    init(
        id: UUID = UUID(),
        name: String,
        durationInSeconds: Int,
        icon: String = "timer",
        colorHex: String = "#007AFF",
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.icon = icon
        self.colorHex = colorHex
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

### TodoItem Model

```swift
import SwiftData
import Foundation

@Model
final class TodoItem {
    // Identifiers
    @Attribute(.unique) var id: UUID

    // Properties
    var text: String
    var isCompleted: Bool
    var sortOrder: Int  // For custom ordering

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var timer: Timer?

    // Initializer
    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

---

## Model Relationships

### Entity Relationship Diagram

```
┌─────────────────────────────────────┐
│            Timer                    │
│  ───────────────────────────────── │
│  id: UUID (unique)                  │
│  name: String                       │
│  durationInSeconds: Int             │
│  icon: String                       │
│  colorHex: String                   │
│  notes: String?                     │
│  createdAt: Date                    │
│  updatedAt: Date                    │
└─────────────────────────────────────┘
                  │
                  │ 1:N (cascade delete)
                  │
                  ▼
┌─────────────────────────────────────┐
│          TodoItem                   │
│  ───────────────────────────────── │
│  id: UUID (unique)                  │
│  text: String                       │
│  isCompleted: Bool                  │
│  sortOrder: Int                     │
│  createdAt: Date                    │
│  updatedAt: Date                    │
│  timer: Timer? (relationship)       │
└─────────────────────────────────────┘
```

**Relationship Details:**
- **One-to-Many**: One Timer has many TodoItems
- **Delete Rule**: Cascade (deleting Timer deletes all its TodoItems)
- **Inverse**: TodoItem.timer points back to parent Timer
- **Optional**: TodoItem.timer is optional (though always set in practice)

---

## SwiftData Configuration

### Model Container Setup (iOS)

```swift
import SwiftUI
import SwiftData

@main
struct TimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Timer.self, TodoItem.self])
    }
}
```

### Model Container Setup (watchOS)

```swift
import SwiftUI
import SwiftData

@main
struct TimerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TimerListView()
        }
        .modelContainer(for: [Timer.self, TodoItem.self])
    }
}
```

---

## Data Access Patterns

### Queries

**Fetch All Timers (Sorted by Creation Date)**
```swift
@Query(sort: \Timer.createdAt, order: .reverse)
var timers: [Timer]
```

**Fetch All Timers (Sorted by Name)**
```swift
@Query(sort: \Timer.name)
var timers: [Timer]
```

**Fetch Timers with Predicate**
```swift
// Timers with incomplete to-dos
@Query(filter: #Predicate<Timer> { timer in
    timer.todoItems.contains { !$0.isCompleted }
})
var timersWithIncompleteTodos: [Timer]
```

**Fetch TodoItems for Specific Timer**
```swift
// Using relationship
timer.todoItems.sorted(by: { $0.sortOrder < $1.sortOrder })
```

### CRUD Operations

**Create Timer**
```swift
let newTimer = Timer(
    name: "Workout",
    durationInSeconds: 1500,  // 25 minutes
    icon: "figure.run",
    colorHex: "#FF3B30"
)
modelContext.insert(newTimer)
try? modelContext.save()
```

**Update Timer**
```swift
timer.name = "Updated Name"
timer.updatedAt = Date()
try? modelContext.save()
```

**Delete Timer**
```swift
modelContext.delete(timer)  // Cascade deletes all TodoItems
try? modelContext.save()
```

**Add TodoItem to Timer**
```swift
let todo = TodoItem(
    text: "Warm up",
    sortOrder: timer.todoItems.count
)
timer.todoItems.append(todo)
timer.updatedAt = Date()
try? modelContext.save()
```

**Toggle TodoItem Completion**
```swift
todoItem.isCompleted.toggle()
todoItem.updatedAt = Date()
todoItem.timer?.updatedAt = Date()  // Update parent
try? modelContext.save()
```

---

## Serialization for Watch Connectivity

### Codable Transfer Objects

To send data via Watch Connectivity, we need `Codable` transfer objects (SwiftData models aren't directly `Codable`).

**TimerDTO (Data Transfer Object)**
```swift
struct TimerDTO: Codable {
    let id: UUID
    let name: String
    let durationInSeconds: Int
    let icon: String
    let colorHex: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let todoItems: [TodoItemDTO]

    // Convert from SwiftData model
    init(from timer: Timer) {
        self.id = timer.id
        self.name = timer.name
        self.durationInSeconds = timer.durationInSeconds
        self.icon = timer.icon
        self.colorHex = timer.colorHex
        self.notes = timer.notes
        self.createdAt = timer.createdAt
        self.updatedAt = timer.updatedAt
        self.todoItems = timer.todoItems.map { TodoItemDTO(from: $0) }
    }

    // Convert to SwiftData model
    func toModel() -> Timer {
        let timer = Timer(
            id: id,
            name: name,
            durationInSeconds: durationInSeconds,
            icon: icon,
            colorHex: colorHex,
            notes: notes
        )
        timer.createdAt = createdAt
        timer.updatedAt = updatedAt
        return timer
    }
}
```

**TodoItemDTO**
```swift
struct TodoItemDTO: Codable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date

    // Convert from SwiftData model
    init(from todoItem: TodoItem) {
        self.id = todoItem.id
        self.text = todoItem.text
        self.isCompleted = todoItem.isCompleted
        self.sortOrder = todoItem.sortOrder
        self.createdAt = todoItem.createdAt
        self.updatedAt = todoItem.updatedAt
    }

    // Convert to SwiftData model
    func toModel() -> TodoItem {
        let todo = TodoItem(
            id: id,
            text: text,
            isCompleted: isCompleted,
            sortOrder: sortOrder
        )
        todo.createdAt = createdAt
        todo.updatedAt = updatedAt
        return todo
    }
}
```

### Watch Connectivity Payload

**Send All Timers**
```swift
struct TimerSyncPayload: Codable {
    let timers: [TimerDTO]
    let syncTimestamp: Date
}

// Usage
let payload = TimerSyncPayload(
    timers: timers.map { TimerDTO(from: $0) },
    syncTimestamp: Date()
)
let data = try JSONEncoder().encode(payload)
```

**Send Single Update**
```swift
struct TimerUpdateMessage: Codable {
    enum UpdateType: String, Codable {
        case created
        case updated
        case deleted
    }

    let type: UpdateType
    let timer: TimerDTO?
    let timerID: UUID  // For deletions
}

// Usage - Timer updated
let message = TimerUpdateMessage(
    type: .updated,
    timer: TimerDTO(from: timer),
    timerID: timer.id
)
```

**Send Quick Action**
```swift
struct QuickActionMessage: Codable {
    enum Action: String, Codable {
        case todoToggled
        case noteUpdated
    }

    let action: Action
    let timerID: UUID
    let todoID: UUID?
    let todoCompleted: Bool?
    let noteText: String?
}

// Usage - Todo toggled
let message = QuickActionMessage(
    action: .todoToggled,
    timerID: timer.id,
    todoID: todoItem.id,
    todoCompleted: todoItem.isCompleted,
    noteText: nil
)
```

---

## Data Validation

### Timer Validation Rules

```swift
extension Timer {
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        durationInSeconds > 0 &&
        durationInSeconds <= 86400  // Max 24 hours
    }

    func validate() throws {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ValidationError.emptyName
        }
        if durationInSeconds <= 0 {
            throw ValidationError.invalidDuration
        }
        if durationInSeconds > 86400 {
            throw ValidationError.durationTooLong
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyName
    case invalidDuration
    case durationTooLong

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Timer name cannot be empty"
        case .invalidDuration:
            return "Duration must be greater than 0"
        case .durationTooLong:
            return "Duration cannot exceed 24 hours"
        }
    }
}
```

### TodoItem Validation Rules

```swift
extension TodoItem {
    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func validate() throws {
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            throw TodoValidationError.emptyText
        }
    }
}

enum TodoValidationError: LocalizedError {
    case emptyText

    var errorDescription: String? {
        "To-do text cannot be empty"
    }
}
```

---

## Migration Strategy

### Future Schema Changes

SwiftData handles lightweight migrations automatically for:
- Adding new properties (with default values)
- Renaming properties (with `@Attribute(.originalName)`)
- Deleting properties

**Example: Adding Category Property**
```swift
@Model
final class Timer {
    // ... existing properties

    var category: String = "General"  // New property with default
}
```

**Example: Renaming Property**
```swift
@Model
final class Timer {
    @Attribute(.originalName("colorHex"))
    var color: String
}
```

### Complex Migrations

For complex migrations (relationship changes, data transformations), use migration plans:

```swift
import SwiftData

enum TimerAppSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Timer.self, TodoItem.self]
    }
}

// Future version
enum TimerAppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerV2.self, TodoItemV2.self, Category.self]
    }
}
```

---

## Sample Data

### For Development/Testing

```swift
extension Timer {
    static var sampleData: [Timer] {
        [
            Timer(
                name: "Workout",
                durationInSeconds: 1500,  // 25 min
                icon: "figure.run",
                colorHex: "#FF3B30",
                notes: "Remember to hydrate!"
            ),
            Timer(
                name: "Study Session",
                durationInSeconds: 2700,  // 45 min
                icon: "book.fill",
                colorHex: "#007AFF"
            ),
            Timer(
                name: "Coffee Break",
                durationInSeconds: 600,  // 10 min
                icon: "cup.and.saucer.fill",
                colorHex: "#8E8E93"
            ),
            Timer(
                name: "Meditation",
                durationInSeconds: 1200,  // 20 min
                icon: "sparkles",
                colorHex: "#5856D6",
                notes: "Focus on breathing"
            )
        ]
    }
}

extension TodoItem {
    static func sampleData(for timer: Timer) -> [TodoItem] {
        switch timer.name {
        case "Workout":
            return [
                TodoItem(text: "Warm up 5 minutes", sortOrder: 0),
                TodoItem(text: "20 push-ups", sortOrder: 1),
                TodoItem(text: "30 squats", sortOrder: 2),
                TodoItem(text: "Plank 1 minute", sortOrder: 3),
                TodoItem(text: "Cool down stretch", sortOrder: 4)
            ]
        case "Study Session":
            return [
                TodoItem(text: "Review chapter 3", sortOrder: 0),
                TodoItem(text: "Complete practice problems", sortOrder: 1)
            ]
        default:
            return []
        }
    }
}
```

---

## Best Practices

### Performance

1. **Use @Query efficiently**: Limit results, use predicates
2. **Batch updates**: Group multiple changes in single save
3. **Lazy loading**: Don't fetch relationships unless needed
4. **Index frequently queried properties**: Use `@Attribute(.indexed)`

### Data Integrity

1. **Always update timestamps**: Set `updatedAt` on changes
2. **Validate before save**: Use `validate()` methods
3. **Handle cascade deletes**: Be aware of relationship delete rules
4. **Sync conflicts**: Use `updatedAt` for conflict resolution

### Watch Connectivity

1. **Minimize payload size**: Only send changed data
2. **Use appropriate transfer method**:
   - Application Context: Bulk data
   - Interactive Message: Real-time updates
   - User Info: Guaranteed delivery
3. **Handle deserialization errors**: Gracefully handle missing/invalid data
4. **Version payloads**: Include schema version in DTOs for future compatibility

---

## Next Steps

See `02-watch-connectivity.md` for details on syncing these models between iPhone and Apple Watch.
