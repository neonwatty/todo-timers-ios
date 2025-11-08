import SwiftUI
import SwiftData

struct WatchTimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Timer.sortOrder), SortDescriptor(\Timer.createdAt)]) private var timers: [Timer]
    @EnvironmentObject private var connectivityService: WatchConnectivityService

    @State private var showingCreateTimer = false

    var body: some View {
        NavigationStack {
            Group {
                if timers.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(timers) { timer in
                                NavigationLink(value: timer) {
                                    WatchTimerCard(timer: timer)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .navigationTitle("Timers")
            .navigationDestination(for: Timer.self) { timer in
                WatchTimerDetailView(timer: timer)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTimer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("createTimerButton")
                }
            }
            .sheet(isPresented: $showingCreateTimer) {
                WatchCreateTimerView()
            }
            .onAppear {
                connectivityService.requestFullSync()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Timers")
                .font(.headline)

            Text("Tap + to create a timer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !connectivityService.isReachable {
                Label("iPhone not reachable", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}

struct WatchTimerCard: View {
    let timer: Timer

    // Get timer service from manager to access live countdown
    private var timerService: WatchTimerService {
        WatchTimerManager.shared.getTimerService(for: timer)
    }

    private var isRunning: Bool {
        timerService.isRunning
    }

    // Format currentTime for display
    private var formattedTime: String {
        let time = timerService.currentTime
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: timer.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: timer.colorHex))

                Text(timer.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Running indicator
                if isRunning {
                    Circle()
                        .fill(Color(hex: timer.colorHex))
                        .frame(width: 6, height: 6)
                        .opacity(0.8)
                }
            }

            // Live countdown
            Text(formattedTime)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: timer.colorHex))

            // Control buttons
            HStack(spacing: 6) {
                // Play/Pause button
                Button(action: {
                    if timerService.isRunning {
                        timerService.pause()
                    } else if timerService.isPaused {
                        timerService.resume()
                    } else {
                        timerService.start()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        Text(timerService.isRunning ? "Pause" : (timerService.isPaused ? "Resume" : "Start"))
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(hex: timer.colorHex))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Reset button
                Button(action: {
                    timerService.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: timer.colorHex))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: timer.colorHex).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            if !timer.todoItems.isEmpty {
                Label("\(timer.todoItems.count) todo\(timer.todoItems.count == 1 ? "" : "s")",
                      systemImage: "checkmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let container = try! ModelContainer(for: Timer.self, TodoItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    let timer1 = Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30"
    )

    let timer2 = Timer(
        name: "Study",
        durationInSeconds: 2700,
        icon: "book.fill",
        colorHex: "#007AFF"
    )

    container.mainContext.insert(timer1)
    container.mainContext.insert(timer2)

    return WatchTimerListView()
        .modelContainer(container)
        .environmentObject(WatchConnectivityService.shared)
}
