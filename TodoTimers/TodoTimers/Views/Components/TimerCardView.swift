import SwiftUI

struct TimerCardView: View {
    let timer: Timer

    // Get timer service from manager to access live countdown
    private var timerService: TimerService {
        TimerManager.shared.getTimerService(for: timer)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon
                Image(systemName: timer.icon)
                    .font(.title)

                // Name
                Text(timer.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Running indicator
                if timerService.isRunning {
                    Circle()
                        .fill(Color(hex: timer.colorHex))
                        .frame(width: 8, height: 8)
                }
            }

            // Live countdown
            Text(formattedTime)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: timer.colorHex))

            // Control buttons
            HStack(spacing: 12) {
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
                    HStack {
                        Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        Text(timerService.isRunning ? "Pause" : (timerService.isPaused ? "Resume" : "Start"))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: timer.colorHex))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(BorderlessButtonStyle())
                .accessibilityIdentifier(
                    timerService.isRunning ? "listPauseButton-\(timer.id)" :
                    (timerService.isPaused ? "listResumeButton-\(timer.id)" : "listStartButton-\(timer.id)")
                )

                // Reset button
                Button(action: {
                    timerService.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: timer.colorHex))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: timer.colorHex).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(BorderlessButtonStyle())
                .accessibilityIdentifier("listResetButton-\(timer.id)")
            }

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

#Preview {
    TimerCardView(timer: Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30",
        sortOrder: 0,
        notes: "Remember to hydrate!"
    ))
    .padding()
}
