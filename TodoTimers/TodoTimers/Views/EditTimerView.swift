import SwiftUI

struct EditTimerView: View {
    @Bindable var timer: Timer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var notes: String
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

    init(timer: Timer) {
        self.timer = timer

        // Initialize state with timer values
        _name = State(initialValue: timer.name)
        _selectedIcon = State(initialValue: timer.icon)
        _selectedColor = State(initialValue: timer.colorHex)
        _notes = State(initialValue: timer.notes ?? "")

        // Calculate hours, minutes, seconds from duration
        let totalSeconds = timer.durationInSeconds
        _hours = State(initialValue: totalSeconds / 3600)
        _minutes = State(initialValue: (totalSeconds % 3600) / 60)
        _seconds = State(initialValue: totalSeconds % 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section("Timer Name") {
                    TextField("Enter timer name", text: $name)
                        .accessibilityIdentifier("timerNameField")
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
                        .accessibilityIdentifier("hoursPicker")

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("minutesPicker")

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("secondsPicker")
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

                // Notes Section
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .accessibilityIdentifier("notesField")
                }
            }
            .navigationTitle("Edit Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("saveButton")
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

    private func saveChanges() {
        guard isValid else {
            errorMessage = "Please enter a timer name and duration"
            showingError = true
            return
        }

        // Update timer properties
        timer.name = name
        timer.durationInSeconds = durationInSeconds
        timer.icon = selectedIcon
        timer.colorHex = selectedColor
        timer.notes = notes.isEmpty ? nil : notes
        timer.updatedAt = Date()

        do {
            try modelContext.save()

            // Sync to Watch
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .updated)

            // If timer is currently running, reset it with new duration
            let timerService = TimerManager.shared.getTimerService(for: timer)
            if timerService.isRunning || timerService.isPaused {
                timerService.reset()
            }

            dismiss()
        } catch {
            errorMessage = "Failed to update timer: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let timer = Timer(
        name: "Workout",
        durationInSeconds: 1500,
        icon: "figure.run",
        colorHex: "#FF3B30",
        notes: "Remember to hydrate!"
    )

    return EditTimerView(timer: timer)
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
