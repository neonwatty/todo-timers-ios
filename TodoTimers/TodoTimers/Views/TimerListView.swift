import SwiftUI
import SwiftData

struct TimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timer.createdAt, order: .reverse) private var timers: [Timer]

    @State private var showingCreateTimer = false
    @Bindable var notificationHandler: NotificationHandler

    var body: some View {
        NavigationStack {
            ZStack {
                if timers.isEmpty {
                    EmptyStateView()
                        .accessibilityIdentifier("emptyStateView")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(timers) { timer in
                                NavigationLink(value: timer) {
                                    TimerCardView(timer: timer, disableInteractions: true)
                                }
                                .buttonStyle(.plain)
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
                            // Navigate to settings (placeholder)
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
