# iOS App - Views Structure

## Overview

This document details the SwiftUI view hierarchy, component structure, and implementation guidelines for the iOS Timer app.

---

## App Structure

### Entry Point

```swift
import SwiftUI
import SwiftData

@main
struct TimerApp: App {
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
TimerApp
  └── TimerListView
        ├── TimerCardView (multiple)
        ├── CreateTimerView (sheet)
        └── TimerDetailView (navigation)
              ├── TimerDisplayView
              ├── TimerControlsView
              ├── TodoListSectionView
              │     ├── TodoItemRow (multiple)
              │     └── AddTodoSheet (sheet)
              ├── NotesSectionView
              │     └── EditNotesView (navigation)
              └── EditTimerView (navigation)
```

---

## 1. TimerListView

### Purpose
Main screen displaying all user timers in a scrollable list.

### Structure

```swift
import SwiftUI
import SwiftData

struct TimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timer.createdAt, order: .reverse) private var timers: [Timer]

    @State private var showingCreateTimer = false
    @State private var syncStatus: SyncStatus = .synced

    var body: some View {
        NavigationStack {
            ZStack {
                if timers.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(timers) { timer in
                                NavigationLink(value: timer) {
                                    TimerCardView(timer: timer)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Timers")
            .navigationDestination(for: Timer.self) { timer in
                TimerDetailView(timer: timer)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Settings", systemImage: "gear") {
                            // Navigate to settings
                        }
                        Button("Sync Now", systemImage: "arrow.triangle.2.circlepath") {
                            syncTimers()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTimer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTimer) {
                CreateTimerView()
            }
        }
    }

    private func syncTimers() {
        // Trigger Watch Connectivity sync
        WatchConnectivityService.shared.syncAllTimers(timers)
        syncStatus = .syncing
        // Update sync status after completion
    }
}

enum SyncStatus {
    case synced
    case syncing
    case error
}
```

### Components Used
- `NavigationStack`: Container for navigation
- `ScrollView` + `LazyVStack`: Efficient list rendering
- `NavigationLink`: Navigation to detail view
- `Toolbar`: Top bar buttons
- `Menu`: Dropdown menu for settings
- `Sheet`: Modal presentation

---

## 2. TimerCardView

### Purpose
Display individual timer information in a card format.

### Structure

```swift
struct TimerCardView: View {
    let timer: Timer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon
                Text(timer.icon)
                    .font(.title)

                // Name
                Text(timer.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Duration
            Text(timer.formattedDuration)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: timer.colorHex))

            Divider()

            // Metadata
            HStack(spacing: 16) {
                Label("\(timer.todoItems.count) to-do\(timer.todoItems.count == 1 ? "" : "s")",
                      systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(timer.notes != nil ? "Notes added" : "No notes",
                      systemImage: timer.notes != nil ? "note.text" : "note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}
```

### Design Notes
- Card has rounded corners (12pt)
- Subtle shadow for depth
- Icon and name prominently displayed
- Duration in timer's custom color
- Metadata shows to-do count and notes status

---

## 3. EmptyStateView

### Purpose
Display when no timers exist.

### Structure

```swift
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Timers Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to create your first timer")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

---

## 4. CreateTimerView

### Purpose
Form for creating a new timer.

### Structure

```swift
struct CreateTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 25
    @State private var seconds = 0
    @State private var selectedIcon = "timer"
    @State private var selectedColor = "#007AFF"
    @State private var showingError = false
    @State private var errorMessage = ""

    private let icons = [
        "timer", "figure.run", "book.fill", "cup.and.saucer.fill",
        "fork.knife", "pencil", "gamecontroller.fill", "music.note",
        "briefcase.fill", "figure.yoga", "bicycle", "wrench.and.screwdriver.fill"
    ]

    private let colors = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#007AFF", "#5856D6", "#AF52DE", "#8E8E93"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section("Timer Name") {
                    TextField("Enter timer name", text: $name)
                }

                // Duration Section
                Section("Duration") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }

                // Icon Section
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                }

                // Color Section
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            ColorButton(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveTimer()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (hours > 0 || minutes > 0 || seconds > 0)
    }

    private var durationInSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    private func saveTimer() {
        guard isValid else {
            errorMessage = "Please enter a timer name and duration"
            showingError = true
            return
        }

        let timer = Timer(
            name: name,
            durationInSeconds: durationInSeconds,
            icon: selectedIcon,
            colorHex: selectedColor
        )

        modelContext.insert(timer)

        do {
            try modelContext.save()

            // Sync to Watch
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .created)

            dismiss()
        } catch {
            errorMessage = "Failed to create timer: \(error.localizedDescription)"
            showingError = true
        }
    }
}
```

### Supporting Components

```swift
struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }
}
```

---

## 5. TimerDetailView

### Purpose
Display timer with controls, to-dos, and notes.

### Structure

```swift
struct TimerDetailView: View {
    @Bindable var timer: Timer
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditTimer = false
    @State private var showingAddTodo = false
    @State private var timerService: TimerService

    init(timer: Timer) {
        self.timer = timer
        _timerService = State(initialValue: TimerService(timer: timer))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timer Display
                TimerDisplayView(
                    currentTime: timerService.currentTime,
                    totalTime: timer.durationInSeconds,
                    isRunning: timerService.isRunning,
                    color: Color(hex: timer.colorHex)
                )

                // Controls
                TimerControlsView(
                    isRunning: timerService.isRunning,
                    isPaused: timerService.isPaused,
                    onStart: { timerService.start() },
                    onPause: { timerService.pause() },
                    onResume: { timerService.resume() },
                    onReset: { timerService.reset() }
                )

                // To-Dos
                TodoListSectionView(
                    timer: timer,
                    onAddTodo: { showingAddTodo = true }
                )

                // Notes
                NotesSectionView(timer: timer)
            }
            .padding()
        }
        .navigationTitle(timer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditTimer = true
                }
            }
        }
        .sheet(isPresented: $showingEditTimer) {
            EditTimerView(timer: timer)
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView(timer: timer)
        }
        .onDisappear {
            timerService.cleanup()
        }
    }
}
```

---

## 6. TimerDisplayView

### Purpose
Large circular timer display with progress ring.

### Structure

```swift
struct TimerDisplayView: View {
    let currentTime: Int
    let totalTime: Int
    let isRunning: Bool
    let color: Color

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
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 20)
                .frame(width: 250, height: 250)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Time text
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                if !isRunning && currentTime < totalTime {
                    Text("PAUSED")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
```

---

## 7. TimerControlsView

### Purpose
Start/Pause/Resume/Reset buttons.

### Structure

```swift
struct TimerControlsView: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Primary action button
            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)

            // Reset button
            Button(action: onReset) {
                Text("RESET")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    private var primaryButtonTitle: String {
        if isRunning {
            return "PAUSE"
        } else if isPaused {
            return "RESUME"
        } else {
            return "START"
        }
    }

    private func primaryAction() {
        if isRunning {
            onPause()
        } else if isPaused {
            onResume()
        } else {
            onStart()
        }
    }
}
```

---

## 8. TodoListSectionView

### Purpose
Display to-do list with add button.

### Structure

```swift
struct TodoListSectionView: View {
    @Bindable var timer: Timer
    let onAddTodo: () -> Void

    @State private var editingTodo: TodoItem?

    private var sortedTodos: [TodoItem] {
        timer.todoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("To-Do Items")
                    .font(.headline)

                Spacer()

                Button(action: onAddTodo) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            Divider()

            // To-Do List
            if sortedTodos.isEmpty {
                Text("No to-dos yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sortedTodos) { todo in
                    TodoItemRow(todo: todo) {
                        editingTodo = todo
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(item: $editingTodo) { todo in
            EditTodoView(todo: todo, timer: timer)
        }
    }
}
```

---

## 9. TodoItemRow

### Purpose
Individual to-do item with checkbox.

### Structure

```swift
struct TodoItemRow: View {
    @Bindable var todo: TodoItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    toggleCompletion()
                } label: {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(todo.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // Text
                Text(todo.text)
                    .font(.body)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)

                Spacer()

                // Disclosure
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        todo.isCompleted.toggle()
        todo.updatedAt = Date()
        todo.timer?.updatedAt = Date()

        // Sync to Watch
        WatchConnectivityService.shared.sendQuickAction(
            action: .todoToggled,
            timerID: todo.timer?.id ?? UUID(),
            todoID: todo.id,
            todoCompleted: todo.isCompleted
        )

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
```

---

## 10. TimerService

### Purpose
Manage timer state and countdown logic.

### Structure

```swift
import Foundation
import Combine

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

        // Send notification
        NotificationService.shared.sendTimerCompleteNotification()
    }

    func cleanup() {
        timerCancellable?.cancel()
    }
}
```

---

## View Modifiers & Utilities

### Custom View Modifiers

```swift
// Card style
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage
SomeView()
    .cardStyle()
```

---

## State Management Summary

### @Environment
- `\.modelContext`: SwiftData context for CRUD operations
- `\.dismiss`: Dismiss sheets/modals

### @Query
- Fetch timers from SwiftData with automatic updates

### @State
- Local UI state (sheet presentation, text fields)

### @Bindable
- Two-way binding for SwiftData models

### @Observable
- Observable classes (TimerService, ViewModels)

---

## Next Steps

See `watchos/mockups.md` and `watchos/views-structure.md` for Apple Watch UI implementation.
