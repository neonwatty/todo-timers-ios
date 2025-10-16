import SwiftUI

struct NotesSectionView: View {
    @Bindable var timer: Timer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Notes")
                .font(.headline)

            Divider()

            // Notes content
            if let notes = timer.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                Text("No notes yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 20) {
        NotesSectionView(timer: Timer(
            name: "Workout",
            durationInSeconds: 1500,
            icon: "figure.run",
            colorHex: "#FF3B30",
            notes: "Remember to hydrate and stretch before starting!"
        ))

        NotesSectionView(timer: Timer(
            name: "Study",
            durationInSeconds: 2700,
            icon: "book.fill",
            colorHex: "#007AFF"
        ))
    }
    .padding()
}
