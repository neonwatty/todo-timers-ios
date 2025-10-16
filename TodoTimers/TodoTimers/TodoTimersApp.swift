//
//  TodoTimersApp.swift
//  TodoTimers
//
//  Created by Jeremy Watt on 10/15/25.
//

import SwiftUI
import SwiftData

@main
struct TodoTimersApp: App {
    @State private var modelContainer: ModelContainer

    init() {
        do {
            let container = try ModelContainer(for: Timer.self, TodoItem.self)
            _modelContainer = State(initialValue: container)

            // Configure WatchConnectivityService with modelContext
            Task { @MainActor in
                WatchConnectivityService.shared.configure(modelContext: container.mainContext)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TimerListView()
        }
        .modelContainer(modelContainer)
    }
}
