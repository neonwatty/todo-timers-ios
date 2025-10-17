import SwiftUI

struct AddTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var timer: Timer

    @State private var todoText = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("To-Do Item") {
                    TextField("Enter to-do text", text: $todoText, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("todoTextField")
                }
            }
            .navigationTitle("Add To-Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelTodoButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTodo()
                    }
                    .disabled(todoText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("addTodoConfirmButton")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func addTodo() {
        let trimmedText = todoText.trimmingCharacters(in: .whitespaces)

        guard !trimmedText.isEmpty else {
            errorMessage = "To-do text cannot be empty"
            showingError = true
            return
        }

        let todo = TodoItem(
            text: trimmedText,
            sortOrder: timer.todoItems.count
        )

        timer.todoItems.append(todo)
        timer.updatedAt = Date()

        do {
            try modelContext.save()

            // Sync to Watch
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .updated)

            dismiss()
        } catch {
            errorMessage = "Failed to add to-do: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    AddTodoView(timer: Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30"
    ))
    .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
