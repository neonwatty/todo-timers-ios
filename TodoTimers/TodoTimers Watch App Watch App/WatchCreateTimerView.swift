import SwiftUI
import SwiftData

/// Watch-optimized timer creation view
/// Simplified UI for small screen with Digital Crown support
struct WatchCreateTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var selectedIcon = "timer"
    @State private var selectedColor = "#007AFF"
    @State private var showingError = false
    @State private var errorMessage = ""

    // Simplified icon set for Watch (6 most common)
    private let icons = [
        "timer", "figure.run", "book.fill",
        "cup.and.saucer.fill", "fork.knife", "briefcase.fill"
    ]

    // Simplified color palette for Watch (4 primary colors)
    private let colors = [
        "#FF3B30",  // Red
        "#34C759",  // Green
        "#007AFF",  // Blue
        "#FF9500"   // Orange
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Timer name", text: $name)
                            .textInputAutocapitalization(.words)
                            .accessibilityIdentifier("timerNameField")
                    }

                    Divider()

                    // Duration Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            // Minutes Picker
                            VStack(spacing: 2) {
                                Picker("Min", selection: $minutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)").tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 80)
                                .clipped()
                                .accessibilityIdentifier("minutesPicker")

                                Text("min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Seconds Picker
                            VStack(spacing: 2) {
                                Picker("Sec", selection: $seconds) {
                                    ForEach(0..<60) { second in
                                        Text("\(second)").tag(second)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 80)
                                .clipped()
                                .accessibilityIdentifier("secondsPicker")

                                Text("sec")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Divider()

                    // Icon Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                WatchIconButton(
                                    icon: icon,
                                    isSelected: selectedIcon == icon
                                ) {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }

                    Divider()

                    // Color Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { color in
                                WatchColorButton(
                                    color: color,
                                    isSelected: selectedColor == color
                                ) {
                                    selectedColor = color
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveTimer()
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("doneButton")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (minutes > 0 || seconds > 0)
    }

    private var durationInSeconds: Int {
        minutes * 60 + seconds
    }

    // MARK: - Save Logic

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

            // Sync to iPhone
            WatchConnectivityService.shared.sendTimerUpdate(timer, type: .created)

            dismiss()
        } catch {
            errorMessage = "Failed to create timer: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Supporting Views

/// Icon button optimized for Watch screen size
struct WatchIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("iconButton_\(icon)")
    }
}

/// Color button optimized for Watch screen size
struct WatchColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 35, height: 35)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("colorButton_\(color)")
    }
}

#Preview {
    WatchCreateTimerView()
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
}
