import SwiftUI

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
            .accessibilityIdentifier(primaryButtonIdentifier)

            // Reset button
            Button(action: onReset) {
                Text("RESET")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("resetButton")
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

    private var primaryButtonIdentifier: String {
        if isRunning {
            return "pauseButton"
        } else if isPaused {
            return "resumeButton"
        } else {
            return "startButton"
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

#Preview {
    VStack(spacing: 20) {
        TimerControlsView(
            isRunning: false,
            isPaused: false,
            onStart: {},
            onPause: {},
            onResume: {},
            onReset: {}
        )

        TimerControlsView(
            isRunning: true,
            isPaused: false,
            onStart: {},
            onPause: {},
            onResume: {},
            onReset: {}
        )

        TimerControlsView(
            isRunning: false,
            isPaused: true,
            onStart: {},
            onPause: {},
            onResume: {},
            onReset: {}
        )
    }
    .padding()
}
