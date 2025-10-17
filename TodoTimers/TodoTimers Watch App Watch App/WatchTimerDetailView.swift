import SwiftUI

struct WatchTimerDetailView: View {
    @Bindable var timer: Timer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connectivityService: WatchConnectivityService

    @State private var showingDeleteConfirmation = false

    // Get timer service from singleton manager to persist across navigation
    private var timerService: WatchTimerService {
        WatchTimerManager.shared.getTimerService(for: timer)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer Display
                WatchTimerDisplay(
                    currentTime: timerService.currentTime,
                    totalTime: timer.durationInSeconds,
                    isRunning: timerService.isRunning,
                    color: Color(hex: timer.colorHex)
                )

                // Controls
                WatchTimerControls(
                    isRunning: timerService.isRunning,
                    isPaused: timerService.isPaused,
                    onStart: { timerService.start() },
                    onPause: { timerService.pause() },
                    onResume: { timerService.resume() },
                    onReset: { timerService.reset() }
                )

                // Todo List
                if !timer.todoItems.isEmpty {
                    WatchTodoList(timer: timer, connectivityService: connectivityService)
                }

                // Notes
                if let notes = timer.notes, !notes.isEmpty {
                    WatchNotesSection(notes: notes)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(timer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityIdentifier("deleteTimerButton")
            }
        }
        .confirmationDialog("Delete Timer", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteTimer()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Delete Logic

    private func deleteTimer() {
        // Clean up timer service from manager if running
        WatchTimerManager.shared.removeTimerService(timerID: timer.id)

        // Delete from model context
        modelContext.delete(timer)

        do {
            try modelContext.save()

            // Sync deletion to iPhone
            connectivityService.sendTimerUpdate(timer, type: .deleted)

            // Dismiss detail view
            dismiss()
        } catch {
            print("Failed to delete timer: \(error.localizedDescription)")
        }
    }
}

struct WatchTimerDisplay: View {
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
                .stroke(color.opacity(0.2), lineWidth: 8)
                .frame(width: 120, height: 120)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Time text
            VStack(spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                if !isRunning && currentTime < totalTime {
                    Text("PAUSED")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct WatchTimerControls: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Primary action button
            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            // Reset button
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.footnote)
            }
            .buttonStyle(.bordered)
        }
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

struct WatchTodoList: View {
    @Bindable var timer: Timer
    let connectivityService: WatchConnectivityService

    private var sortedTodos: [TodoItem] {
        timer.todoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TO-DO")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(sortedTodos) { todo in
                    Button(action: {
                        toggleTodo(todo)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.footnote)
                                .foregroundStyle(todo.isCompleted ? .green : .secondary)

                            Text(todo.text)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                                .strikethrough(todo.isCompleted)

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color(.darkGray).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleTodo(_ todo: TodoItem) {
        todo.isCompleted.toggle()
        todo.updatedAt = Date()

        // Send update to iPhone
        connectivityService.sendQuickAction(
            action: .todoToggled,
            timerID: timer.id,
            todoID: todo.id,
            todoCompleted: todo.isCompleted
        )
    }
}

struct WatchNotesSection: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(notes)
                .font(.caption)
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.darkGray).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let timer = Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30",
        notes: "Remember to hydrate!"
    )

    let todo1 = TodoItem(text: "Warm up 5 minutes", sortOrder: 0)
    let todo2 = TodoItem(text: "20 push-ups", isCompleted: true, sortOrder: 1)
    let todo3 = TodoItem(text: "30 squats", sortOrder: 2)
    timer.todoItems = [todo1, todo2, todo3]

    return NavigationStack {
        WatchTimerDetailView(timer: timer)
    }
    .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
    .environmentObject(WatchConnectivityService.shared)
}
