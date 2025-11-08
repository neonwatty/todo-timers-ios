import SwiftUI
import SwiftData

struct TimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Timer.sortOrder), SortDescriptor(\Timer.createdAt)]) private var timers: [Timer]

    @State private var showingCreateTimer = false
    @State private var editMode: EditMode = .inactive
    @Bindable var notificationHandler: NotificationHandler

    var body: some View {
        NavigationStack {
            ZStack {
                if timers.isEmpty {
                    EmptyStateView()
                        .accessibilityIdentifier("emptyStateView")
                } else {
                    List {
                        ForEach(timers) { timer in
                            NavigationLink(value: timer) {
                                TimerCardView(timer: timer)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier("timerCard-\(timer.id)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTimer(timer)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("Delete")
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteTimer(timer)
                                } label: {
                                    Label("Delete Timer", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: moveTimers)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
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
                            // Navigate to settings (placeholder)
                        }
                        Button("Sync Now", systemImage: "arrow.triangle.2.circlepath") {
                            syncTimers()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItem(placement: .principal) {
                    if editMode == .active {
                        Button("Done") {
                            withAnimation {
                                editMode = .inactive
                            }
                        }
                        .accessibilityIdentifier("doneEditingButton")
                    } else {
                        Button("Edit") {
                            withAnimation {
                                editMode = .active
                            }
                        }
                        .accessibilityIdentifier("editTimersButton")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTimer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addTimerButton")
                }
            }
            .sheet(isPresented: $showingCreateTimer) {
                CreateTimerView()
            }
            .onChange(of: notificationHandler.selectedTimerID) { oldValue, newValue in
                if let timerID = newValue,
                   let timer = timers.first(where: { $0.id == timerID }) {
                    // Navigate to timer detail
                    navigateToTimer(timer)
                    notificationHandler.selectedTimerID = nil
                }
            }
        }
    }

    private func syncTimers() {
        // Trigger Watch Connectivity sync
        WatchConnectivityService.shared.sendFullSync()
    }

    private func navigateToTimer(_ timer: Timer) {
        // Programmatic navigation is handled by NavigationLink(value:)
        // The onChange above will trigger when notification is tapped
    }

    private func moveTimers(from source: IndexSet, to destination: Int) {
        // Create a mutable copy of timers array
        var mutableTimers = timers
        mutableTimers.move(fromOffsets: source, toOffset: destination)

        // Update sortOrder for all timers based on new positions
        for (index, timer) in mutableTimers.enumerated() {
            timer.sortOrder = index
            timer.updatedAt = Date()
        }

        // Save changes
        do {
            try modelContext.save()

            // Sync the reordered timers to Watch
            WatchConnectivityService.shared.sendFullSync()
        } catch {
            print("Failed to reorder timers: \(error.localizedDescription)")
        }
    }

    private func deleteTimer(_ timer: Timer) {
        // Clean up active timer service if running
        TimerManager.shared.removeTimerService(timerID: timer.id)

        // Cancel any pending notifications
        NotificationService.shared.cancelTimerNotification(timerID: timer.id)

        // Delete from SwiftData
        modelContext.delete(timer)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete timer: \(error.localizedDescription)")
        }
    }
}

#Preview {
    TimerListView(notificationHandler: NotificationHandler())
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
