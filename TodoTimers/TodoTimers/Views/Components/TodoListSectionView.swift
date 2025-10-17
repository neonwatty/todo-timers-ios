import SwiftUI

struct TodoListSectionView: View {
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
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
