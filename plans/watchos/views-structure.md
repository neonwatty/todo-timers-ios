# watchOS App - Views Structure

## Overview

This document details the SwiftUI view hierarchy, component structure, and implementation guidelines for the watchOS Timer app. The design prioritizes glanceability, simple interactions, and Digital Crown navigation.

---

## App Structure

### Entry Point

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

## View Hierarchy

```
TimerWatchApp
  └── TimerListView
        ├── TimerRowView (multiple)
        └── TimerDetailView (navigation)
              ├── TimerDisplaySection
              │     ├── TimerProgressRing
              │     └── TimerControlButton
              ├── TodoListSection
              │     └── TodoRowView (multiple)
              └── NotesSection
```

---

## 1. TimerListView

### Purpose
Main screen displaying all timers in a scrollable vertical list.

### Structure

```swift
import SwiftUI
import SwiftData

struct TimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timer.createdAt, order: .reverse) private var timers: [Timer]

    @State private var syncStatus: SyncStatus = .idle

    var body: some View {
        NavigationStack {
            ScrollView {
                if timers.isEmpty {
                    EmptyStateView()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(timers) { timer in
                            NavigationLink(value: timer) {
                                TimerRowView(timer: timer)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .navigationTitle("My Timers")
            .navigationDestination(for: Timer.self) { timer in
                TimerDetailView(timer: timer)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if syncStatus == .syncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .onAppear {
                setupWatchConnectivity()
            }
        }
    }

    private func setupWatchConnectivity() {
        let service = WatchConnectivityService.shared
        service.setModelContext(modelContext)

        // Request sync from iPhone
        requestInitialSync()
    }

    private func requestInitialSync() {
        // Request sync via Watch Connectivity
        syncStatus = .syncing
        // Update status when complete
    }
}

enum SyncStatus {
    case idle
    case syncing
    case error
}
```

### watchOS-Specific Notes
- No top-level toolbar buttons (limited space)
- Uses Digital Crown for scrolling
- Force Touch for context menu (sync, refresh)

---

## 2. TimerRowView

### Purpose
Individual timer row in the list.

### Structure

```swift
struct TimerRowView: View {
    let timer: Timer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Icon + Name
                Text(timer.icon)
                    .font(.title3)

                Text(timer.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()
            }

            // Duration
            Text(timer.formattedDuration)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: timer.colorHex))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

### Design Notes
- Simplified compared to iOS (no metadata pills)
- Full-width tappable area
- Icon + name on first line
- Duration prominent on second line

---

## 3. EmptyStateView

### Purpose
Display when no timers exist.

### Structure

```swift
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Timers")
                .font(.headline)

            Text("Create one\non iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

---

## 4. TimerDetailView

### Purpose
Main timer screen with display, controls, to-dos, and notes.

### Structure

```swift
struct TimerDetailView: View {
    @Bindable var timer: Timer
    @Environment(\.modelContext) private var modelContext

    @State private var timerService: TimerService
    @FocusState private var isTimerFocused: Bool

    init(timer: Timer) {
        self.timer = timer
        _timerService = State(initialValue: TimerService(timer: timer))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer Display Section
                TimerDisplaySection(
                    currentTime: timerService.currentTime,
                    totalTime: timer.durationInSeconds,
                    isRunning: timerService.isRunning,
                    isPaused: timerService.isPaused,
                    color: Color(hex: timer.colorHex),
                    onStart: { timerService.start() },
                    onPause: { timerService.pause() },
                    onResume: { timerService.resume() },
                    onReset: { timerService.reset() }
                )
                .padding(.bottom, 8)

                // To-Dos Section
                TodoListSection(timer: timer)

                // Notes Section
                NotesSection(timer: timer)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle(timer.name)
        .navigationBarTitleDisplayMode(.inline)
        .focusable(true)
        .focused($isTimerFocused)
        .digitalCrownRotation(
            $timerService.currentTime,
            from: 0,
            through: timer.durationInSeconds,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: isTimerFocused) { _, focused in
            if focused {
                // Digital Crown controls timer
            }
        }
        .onDisappear {
            timerService.cleanup()
        }
    }
}
```

### Navigation Flow
- Continuous vertical scroll (timer → to-dos → notes)
- Digital Crown navigation
- Swipe right to go back

---

## 5. TimerDisplaySection

### Purpose
Large timer display with progress ring and control button.

### Structure

```swift
struct TimerDisplaySection: View {
    let currentTime: Int
    let totalTime: Int
    let isRunning: Bool
    let isPaused: Bool
    let color: Color
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onReset: () -> Void

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(currentTime) / Double(totalTime)
    }

    private var formattedTime: String {
        let hours = currentTime / 3600
        let minutes = (currentTime % 3600) / 60
        let seconds = currentTime % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Progress Ring + Time
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 140, height: 140)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                // Time display
                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .minimumScaleFactor(0.8)

                    if isPaused {
                        Text("PAUSED")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)

            // Control Button
            TimerControlButton(
                isRunning: isRunning,
                isPaused: isPaused,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume
            )

            // Reset button (smaller, secondary)
            if isRunning || isPaused {
                Button(action: onReset) {
                    Text("RESET")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### Design Notes
- Progress ring scaled for Watch screen (140pt diameter)
- Time display prominent and readable
- Single large action button
- Reset button small and secondary

---

## 6. TimerControlButton

### Purpose
Primary action button (Start/Pause/Resume).

### Structure

```swift
struct TimerControlButton: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void

    var body: some View {
        Button(action: primaryAction) {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(buttonColor)
    }

    private var buttonTitle: String {
        if isRunning {
            return "PAUSE"
        } else if isPaused {
            return "RESUME"
        } else {
            return "START"
        }
    }

    private var buttonColor: Color {
        if isRunning {
            return .orange
        } else {
            return .green
        }
    }

    private func primaryAction() {
        if isRunning {
            onPause()
            WKInterfaceDevice.current().play(.stop)
        } else if isPaused {
            onResume()
            WKInterfaceDevice.current().play(.start)
        } else {
            onStart()
            WKInterfaceDevice.current().play(.start)
        }
    }
}
```

### Haptic Feedback
- `.start`: When starting/resuming
- `.stop`: When pausing
- Uses `WKInterfaceDevice` for Watch-specific haptics

---

## 7. TodoListSection

### Purpose
Display to-dos in a simple list.

### Structure

```swift
struct TodoListSection: View {
    @Bindable var timer: Timer

    private var sortedTodos: [TodoItem] {
        timer.todoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("To-Dos (\(timer.todoItems.count))")
                .font(.headline)
                .padding(.top, 8)

            if sortedTodos.isEmpty {
                Text("No to-dos yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                Text("Add them on iPhone")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                VStack(spacing: 4) {
                    ForEach(sortedTodos) { todo in
                        TodoRowView(todo: todo)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

---

## 8. TodoRowView

### Purpose
Individual to-do item with tap-to-toggle.

### Structure

```swift
struct TodoRowView: View {
    @Bindable var todo: TodoItem

    var body: some View {
        Button {
            toggleCompletion()
        } label: {
            HStack(spacing: 8) {
                // Checkbox
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)

                // Text
                Text(todo.text)
                    .font(.footnote)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(2)

                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            todo.isCompleted.toggle()
            todo.updatedAt = Date()
            todo.timer?.updatedAt = Date()
        }

        // Sync to iPhone
        WatchConnectivityService.shared.sendQuickAction(
            action: .todoToggled,
            timerID: todo.timer?.id ?? UUID(),
            todoID: todo.id,
            todoCompleted: todo.isCompleted
        )

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
}
```

### Interaction Notes
- Entire row is tappable (easier on Watch)
- Immediate visual feedback with animation
- Haptic click on toggle
- Syncs to iPhone immediately

---

## 9. NotesSection

### Purpose
Display timer notes (read-only).

### Structure

```swift
struct NotesSection: View {
    let timer: Timer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("Notes")
                .font(.headline)
                .padding(.top, 8)

            if let notes = timer.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                Text("No notes yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                Text("Add them on iPhone")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

### Design Decision
Notes are **read-only** on Watch due to:
- Limited screen space for text editing
- Better UX on iPhone for longer text
- Watch is for quick glances, not extensive input

---

## 10. TimerService (watchOS)

### Purpose
Manage timer state and countdown (same as iOS with Watch-specific features).

### Structure

```swift
import Foundation
import Combine
import WatchKit

@Observable
class TimerService {
    private(set) var currentTime: Int
    private(set) var isRunning = false
    private(set) var isPaused = false

    private let totalTime: Int
    private var timerCancellable: AnyCancellable?
    private var backgroundTask: WKRefreshBackgroundTask?

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

        // Schedule background refresh (watchOS-specific)
        scheduleBackgroundRefresh()

        // Haptic
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        guard isRunning else { return }

        isRunning = false
        isPaused = true
        timerCancellable?.cancel()

        // Haptic
        WKInterfaceDevice.current().play(.stop)
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

        // Haptic
        WKInterfaceDevice.current().play(.click)
    }

    private func tick() {
        guard currentTime > 0 else {
            complete()
            return
        }

        currentTime -= 1

        // Update complications
        CLKComplicationServer.sharedInstance().activeComplications?.forEach {
            CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
        }
    }

    private func complete() {
        isRunning = false
        isPaused = false
        timerCancellable?.cancel()

        // Haptic
        WKInterfaceDevice.current().play(.success)

        // Notification
        sendLocalNotification()

        // Update complications
        CLKComplicationServer.sharedInstance().activeComplications?.forEach {
            CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
        }
    }

    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "Your timer has finished"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleBackgroundRefresh() {
        // Schedule background task for timer completion
        let fireDate = Date().addingTimeInterval(TimeInterval(currentTime))
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: fireDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }

    func cleanup() {
        timerCancellable?.cancel()
    }
}
```

### watchOS-Specific Features
- Background refresh scheduling
- Complication updates
- Watch-specific haptics via `WKInterfaceDevice`
- Local notifications

---

## 11. Complications Support

### Complication Controller

```swift
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.app.timer.complication",
                displayName: "Timer",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .graphicCircular,
                    .graphicCorner
                ]
            )
        ]

        handler(descriptors)
    }

    // MARK: - Timeline

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        // Fetch active or next timer
        guard let timer = getActiveTimer() else {
            handler(nil)
            return
        }

        let entry = createTimelineEntry(for: timer, complication: complication)
        handler(entry)
    }

    private func createTimelineEntry(
        for timer: Timer,
        complication: CLKComplication
    ) -> CLKComplicationTimelineEntry? {
        let template: CLKComplicationTemplate?

        switch complication.family {
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            circularTemplate.textProvider = CLKSimpleTextProvider(
                text: "\(timer.durationInSeconds / 60)"
            )
            template = circularTemplate

        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallStackText()
            modularTemplate.line1TextProvider = CLKSimpleTextProvider(text: timer.icon)
            modularTemplate.line2TextProvider = CLKSimpleTextProvider(
                text: timer.formattedDuration
            )
            template = modularTemplate

        case .graphicCircular:
            let graphicTemplate = CLKComplicationTemplateGraphicCircularStackText()
            graphicTemplate.line1TextProvider = CLKSimpleTextProvider(text: timer.icon)
            graphicTemplate.line2TextProvider = CLKSimpleTextProvider(
                text: "\(timer.durationInSeconds / 60)m"
            )
            template = graphicTemplate

        default:
            template = nil
        }

        guard let template = template else { return nil }

        return CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
    }

    private func getActiveTimer() -> Timer? {
        // Fetch from SwiftData or shared state
        // Return currently running timer or next timer
        return nil // Placeholder
    }
}
```

---

## watchOS State Management

### @Environment
- `\.modelContext`: SwiftData context

### @Query
- Fetch timers (same as iOS)

### @State
- Local UI state
- TimerService instance

### @Bindable
- Two-way binding for SwiftData models

### @FocusState
- Track Digital Crown focus

---

## Digital Crown Integration

### Timer Adjustment Example

```swift
struct TimerDetailView: View {
    @State private var crownValue: Double = 0
    @FocusState private var isCrownActive: Bool

    var body: some View {
        VStack {
            Text("Adjust with Digital Crown")

            Text("\(Int(crownValue)) seconds")
                .font(.title)
                .focusable()
                .focused($isCrownActive)
                .digitalCrownRotation(
                    $crownValue,
                    from: 0,
                    through: 3600,
                    by: 15,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
        }
        .onAppear {
            isCrownActive = true
        }
    }
}
```

### Parameters
- `from`/`through`: Range of values
- `by`: Step increment (15 seconds)
- `sensitivity`: Rotation sensitivity
- `isContinuous`: Continuous vs discrete
- `isHapticFeedbackEnabled`: Haptic ticks

---

## Performance Optimizations

### Battery Efficiency

```swift
// Reduce updates when timer not visible
extension TimerService {
    func enterBackground() {
        // Reduce timer update frequency
        timerCancellable?.cancel()

        // Schedule background task
        scheduleBackgroundRefresh()
    }

    func enterForeground() {
        // Resume normal updates
        if isRunning {
            start()
        }
    }
}
```

### Memory Management

```swift
// Cleanup when views disappear
.onDisappear {
    timerService.cleanup()
}

// Cancel Combine subscriptions
func cleanup() {
    timerCancellable?.cancel()
}
```

---

## Always-On Display (AOD)

### Reduced Display

```swift
struct TimerDetailView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        if isLuminanceReduced {
            // Minimal display for AOD
            TimerAODView(currentTime: timerService.currentTime)
        } else {
            // Full display
            TimerDisplaySection(...)
        }
    }
}

struct TimerAODView: View {
    let currentTime: Int

    var body: some View {
        Text(formattedTime(currentTime))
            .font(.system(size: 40, weight: .bold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

---

## Testing on watchOS

### Simulator Testing
- Limited: No real haptics, no background tasks
- Good for: UI layout, navigation, basic logic

### Real Device Testing (Required)
- Watch Connectivity sync
- Background timer behavior
- Complications
- Haptic feedback
- Always-On Display
- Battery impact

### Debug Console

```swift
// Log to console
print("⌚️ Timer started: \(timer.name)")

// View hierarchy debugger works on Watch
// Device → View Debugging → Capture View Hierarchy
```

---

## Accessibility (watchOS)

### VoiceOver

```swift
Button {
    toggleCompletion()
} label: {
    HStack {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
        Text(todo.text)
    }
}
.accessibilityLabel("\(todo.text), \(todo.isCompleted ? "completed" : "not completed")")
.accessibilityHint("Tap to toggle completion")
```

### Larger Text

```swift
Text(timer.name)
    .font(.headline)
    .lineLimit(2)
    .minimumScaleFactor(0.8)
```

### Reduced Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Circle()
    .trim(from: 0, to: progress)
    .animation(reduceMotion ? nil : .linear(duration: 0.5), value: progress)
```

---

## Next Steps

### Implementation Checklist
- [ ] Create watchOS target in Xcode
- [ ] Share SwiftData models between iOS and watchOS
- [ ] Implement basic timer list and detail views
- [ ] Add Watch Connectivity integration
- [ ] Implement timer countdown logic
- [ ] Add complications support
- [ ] Test on real Apple Watch
- [ ] Optimize for battery life
- [ ] Add haptic feedback
- [ ] Implement AOD support

### Resources
- [watchOS Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/watchos)
- [Watch Connectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [ClockKit for Complications](https://developer.apple.com/documentation/clockkit)
- [WatchKit Framework](https://developer.apple.com/documentation/watchkit)
