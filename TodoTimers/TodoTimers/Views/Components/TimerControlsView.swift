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

            // Reset button
            Button(action: onReset) {
                Text("RESET")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
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
