import SwiftUI

struct TimerCardView: View {
    let timer: Timer

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
            }

            // Duration
            Text(timer.formattedDuration)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: timer.colorHex))

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
        notes: "Remember to hydrate!"
    ))
    .padding()
}
