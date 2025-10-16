import SwiftUI

struct CreateTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 25
    @State private var seconds = 0
    @State private var selectedIcon = "timer"
    @State private var selectedColor = "#007AFF"
    @State private var showingError = false
    @State private var errorMessage = ""

    private let icons = [
        "timer", "figure.run", "book.fill", "cup.and.saucer.fill",
        "fork.knife", "pencil", "gamecontroller.fill", "music.note",
        "briefcase.fill", "figure.yoga", "bicycle", "wrench.and.screwdriver.fill"
    ]

    private let colors = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#007AFF", "#5856D6", "#AF52DE", "#8E8E93"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section("Timer Name") {
                    TextField("Enter timer name", text: $name)
                }

                // Duration Section
                Section("Duration") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }

                // Icon Section
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                }

                // Color Section
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            ColorButton(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveTimer()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (hours > 0 || minutes > 0 || seconds > 0)
    }

    private var durationInSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    private func saveTimer() {
        guard isValid else {
            errorMessage = "Please enter a timer name and duration"
            showingError = true
            return
        }

        let timer = Timer(
            name: name,
            durationInSeconds: durationInSeconds,
            icon: selectedIcon,
            colorHex: selectedColor
        )

        modelContext.insert(timer)

        do {
            try modelContext.save()

            // Sync to Watch
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .created)

            dismiss()
        } catch {
            errorMessage = "Failed to create timer: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    CreateTimerView()
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
