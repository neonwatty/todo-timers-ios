import SwiftUI

struct TimerDetailView: View {
    @Bindable var timer: Timer
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddTodo = false
    @State private var showingEditTimer = false
    private var timerService: TimerService

    init(timer: Timer) {
        self.timer = timer
        self.timerService = TimerManager.shared.getTimerService(for: timer)
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
                .accessibilityIdentifier("editTimerButton")
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView(timer: timer)
        }
        .sheet(isPresented: $showingEditTimer) {
            EditTimerView(timer: timer)
        }
        .onAppear {
            setupNotificationObserver()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .startTimerFromNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let timerID = notification.userInfo?["timerID"] as? UUID,
                  timerID == timer.id else { return }

            // Reset and start the timer
            timerService.reset()
            timerService.start()
        }
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
    timer.todoItems = [todo1, todo2]

    return NavigationStack {
        TimerDetailView(timer: timer)
    }
    .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
