import SwiftUI

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

#Preview {
    VStack(spacing: 40) {
        TimerDisplayView(
            currentTime: 1500,
            totalTime: 1500,
            isRunning: false,
            color: Color(hex: "#007AFF")
        )

        TimerDisplayView(
            currentTime: 750,
            totalTime: 1500,
            isRunning: true,
            color: Color(hex: "#FF3B30")
        )
    }
}
