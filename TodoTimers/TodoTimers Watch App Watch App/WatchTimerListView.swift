import SwiftUI
import SwiftData

struct WatchTimerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timer.createdAt, order: .reverse) private var timers: [Timer]
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
            }

            Text(timer.formattedDuration)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: timer.colorHex))

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
