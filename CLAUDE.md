# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TodoTimers is a native iOS and watchOS timer app with real-time bidirectional synchronization between iPhone and Apple Watch using Watch Connectivity Framework (no iCloud).

**Stack:** Swift 6, SwiftUI, SwiftData (iOS 17+, watchOS 10+), MVVM architecture

## 🤖 Task Agent Usage Guidelines

**IMPORTANT**: Use specialized Task agents liberally for exploration, planning, and research tasks.

### When to Use Task Agents

**Explore Agent** (use `subagent_type=Explore`):
- Understanding codebase structure and architecture
- Finding where features are implemented across multiple files
- Exploring error handling patterns, API endpoints, or design patterns
- Questions like "How does X work?", "Where is Y handled?", "What's the structure of Z?"
- Set thoroughness: `quick` (basic), `medium` (moderate), or `very thorough` (comprehensive)

**Plan Agent** (use `subagent_type=Plan`):
- Breaking down complex feature implementations
- Designing multi-step refactoring approaches
- Planning architectural changes or migrations

**General-Purpose Agent** (use `subagent_type=general-purpose`):
- Multi-step tasks requiring multiple tool invocations
- Documentation lookups via WebSearch/WebFetch
- Complex searches across many files with multiple rounds

## Build and Test Commands

**Build:** `⌘B` in Xcode

**Run all tests:** `⌘U` in Xcode or `cd TodoTimers && ./run_all_tests.sh`

**Command line testing:**
```bash
# Unit tests only
xcodebuild test -project TodoTimers/TodoTimers.xcodeproj -scheme TodoTimers \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TodoTimersTests

# UI tests only (use -only-testing:TodoTimersUITests)
# Specific test class: -only-testing:TodoTimersUITests/TimerManagementUITests
# Single test: -only-testing:TodoTimersUITests/TimerManagementUITests/testCreateTimer_WithValidName_ShowsInList
```

**Note:** No automated linting. Use Xcode warnings/errors. Working directory is `TodoTimers/`.

## Architecture Overview

### Key Structure
- `Shared/Models/`: SwiftData models (`Timer`, `TodoItem`) with cascade delete
- `Shared/DTOs/`: Data Transfer Objects for Watch sync (`TimerDTO`, `TodoItemDTO`, `WatchPayloads.swift`)
- `TodoTimers/Services/`: `WatchConnectivityService` (sync), `TimerService` (countdown), `NotificationService`
- `TodoTimers/Views/`: SwiftUI views (list, detail, create, edit)
- `TodoTimers Watch App Watch App/`: Watch app with mirrored structure
- `TodoTimersTests/`: Unit/integration tests with `TestHelpers/` (in-memory SwiftData, mocks)
- `TodoTimersUITests/`: E2E tests with accessibility identifiers

### Data Sync Architecture

**iPhone = Primary (source of truth), Watch = Secondary (local cache)**

**Sync Strategy:**
- Bidirectional Watch Connectivity (no iCloud)
- DTOs for serialization (`TimerDTO`, `TodoItemDTO`)
- Sync messages: `TimerSyncPayload` (full), `TimerUpdateMessage` (single), `QuickActionMessage` (real-time)
- Conflict resolution: Last-write-wins using `updatedAt` timestamp

**WatchConnectivityService pattern:**
```swift
WatchConnectivityService.shared.configure(modelContext: modelContext)
WatchConnectivityService.shared.sendFullSync()  // Bulk transfer
WatchConnectivityService.shared.sendTimerUpdate(timer, type: .created)  // Single update
WatchConnectivityService.shared.sendQuickAction(action: .toggleTodo, timerID: id, todoID: todoID)  // Real-time
```

## Testing (109+ tests)

**Organization:** Unit (80), Integration (15), UI/E2E (30+)

**Test Helpers:**
- `TestModelContainer.create()`: In-memory SwiftData
- `TestDataFactory.createTimer()`: Test data generation
- `MockWCSession()`: Mock Watch Connectivity
- `XCUIElementExtensions`: `waitForExistence()`, `tapIfExists()`, `clearAndType()`

**UI Testing:**
- All elements have accessibility IDs: `addTimerButton`, `timerCard-{UUID}`, `todoCheckbox-{UUID}`, etc.
- Use `app.launchAndClearState()` in `setUp()` (triggers `--uitesting` flag → resets SwiftData)
- See `TodoTimers/UI_TEST_INFRASTRUCTURE.md` for full list of identifiers

**TDD Workflow:**
1. Unit tests (`TodoTimersTests/UnitTests/`)
2. Implementation (`Services/` or `Views/`)
3. UI tests (`TodoTimersUITests/E2ETests/`)
4. Run `⌘U` to verify

## Key Patterns

**MVVM:**
- Models: SwiftData `@Model` classes
- Views: SwiftUI with `@Query(sort: \Timer.createdAt)` for live updates
- Services: Singletons (e.g., `WatchConnectivityService.shared`)

**Service Pattern:**
```swift
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    private var modelContext: ModelContext?
    func configure(modelContext: ModelContext) { self.modelContext = modelContext }
}
```

**SwiftData:**
```swift
@Model final class Timer {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var todoItems: [TodoItem]
    func validate() throws { /* throw ValidationError */ }
}
```

**Watch Connectivity:**
```swift
// Check session state
guard session.activationState == .activated else { return }
// Use interactive messaging when reachable
if session.isReachable { session.sendMessage(...) }
else { try session.updateApplicationContext(...) }
```

## Development Status & Next Steps

**Completed:** SwiftData models, iOS/Watch UI, Watch Connectivity, 109+ tests, real-time sync

**Known Gaps:** No background timers, no notifications, no watchOS complications

**Roadmap:** See `TodoTimers/NEXT_STEPS.md`

## Code Conventions

**Swift 6 patterns:**
- Use `async/await`, `@MainActor` for UI services
- SwiftUI: `@Query`, `@State`, `@Published`
- Always add accessibility identifiers: `.accessibilityIdentifier("elementName")`

**Adding accessibility IDs for UI testing:**
```swift
Button("Add") { }.accessibilityIdentifier("addTimerButton")
Button { }.accessibilityIdentifier("timerCard-\(timer.id)")  // Dynamic IDs
```

## Documentation

**Plans:** `plans/00-overview.md`, `01-data-model.md`, `02-watch-connectivity.md`, `ios/views-structure.md`, `watchos/views-structure.md`

**Technical:** `TodoTimers/UI_TEST_INFRASTRUCTURE.md`, `NEXT_STEPS.md`

## Common Workflows

**New feature:**
1. Check `plans/` for context
2. Write unit tests → implement → add UI tests
3. If modifying models: update DTOs and sync logic
4. Test: `./run_all_tests.sh`

**Modifying SwiftData models:**
1. Update `Shared/Models/` and `Shared/DTOs/`
2. Update `WatchPayloads.swift` if needed
3. Test iPhone ↔ Watch sync

**Debugging Watch sync:**
- Check `WatchConnectivityService.swift` logs
- Use `MockWCSession` in unit tests
- Test reachable/unreachable scenarios
