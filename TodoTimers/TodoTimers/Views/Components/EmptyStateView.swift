import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Timers Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to create your first timer")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    EmptyStateView()
}
