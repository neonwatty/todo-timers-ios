import SwiftUI

struct TodoListSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var timer: Timer
    let onAddTodo: () -> Void

    @State private var editingTodo: TodoItem?

    private var sortedTodos: [TodoItem] {
        timer.todoItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("To-Do Items")
                    .font(.headline)

                Spacer()

                Button(action: onAddTodo) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityIdentifier("addTodoButton")
            }

            Divider()

            // To-Do List
            if sortedTodos.isEmpty {
                Text("No to-dos yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sortedTodos) { todo in
                    TodoItemRow(todo: todo) {
                        editingTodo = todo
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTodo(todo)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityIdentifier("Delete")
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func deleteTodo(_ todo: TodoItem) {
        timer.todoItems.removeAll { $0.id == todo.id }
        timer.updatedAt = Date()

        modelContext.delete(todo)

        do {
            try modelContext.save()

            // Sync to Watch
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .updated)
        } catch {
            print("Failed to delete todo: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let timer = Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30"
    )

    let todo1 = TodoItem(text: "Warm up 5 minutes", sortOrder: 0)
    let todo2 = TodoItem(text: "20 push-ups", isCompleted: true, sortOrder: 1)
    timer.todoItems = [todo1, todo2]

    return TodoListSectionView(timer: timer, onAddTodo: {})
        .padding()
}
