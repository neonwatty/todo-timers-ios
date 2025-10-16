import SwiftUI
import SwiftData

struct TimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timer.createdAt, order: .reverse) private var timers: [Timer]

    @State private var showingCreateTimer = false

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
                }
            }
            .sheet(isPresented: $showingCreateTimer) {
                CreateTimerView()
            }
        }
    }

    private func syncTimers() {
        // Trigger Watch Connectivity sync
        WatchConnectivityService.shared.sendFullSync()
    }
}

#Preview {
    TimerListView()
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
