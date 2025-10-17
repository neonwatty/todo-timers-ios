import SwiftUI
import UIKit

struct TodoItemRow: View {
    @Bindable var todo: TodoItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    toggleCompletion()
                } label: {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(todo.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("todoCheckbox-\(todo.id)")

                // Text
                Text(todo.text)
                    .font(.body)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                    .accessibilityIdentifier("todoText-\(todo.id)")

                Spacer()

                // Disclosure
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("todoRow-\(todo.id)")
    }

    private func toggleCompletion() {
        todo.isCompleted.toggle()
        todo.updatedAt = Date()
        todo.timer?.updatedAt = Date()

        // Sync to Watch
        if let timerID = todo.timer?.id {
            WatchConnectivityService.shared.sendQuickAction(
                action: .todoToggled,
                timerID: timerID,
                todoID: todo.id,
                todoCompleted: todo.isCompleted
            )
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    VStack {
        TodoItemRow(
            todo: TodoItem(text: "Warm up 5 minutes", isCompleted: false, sortOrder: 0),
            onTap: {}
        )

        TodoItemRow(
            todo: TodoItem(text: "20 push-ups", isCompleted: true, sortOrder: 1),
            onTap: {}
        )
    }
    .padding()
}
