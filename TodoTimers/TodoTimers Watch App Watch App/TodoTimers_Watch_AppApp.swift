//
//  TodoTimers_Watch_AppApp.swift
//  TodoTimers Watch App Watch App
//
//  Created by Jeremy Watt on 10/15/25.
//

import SwiftUI
import SwiftData

@main
struct TodoTimers_Watch_App_Watch_AppApp: App {
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
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
