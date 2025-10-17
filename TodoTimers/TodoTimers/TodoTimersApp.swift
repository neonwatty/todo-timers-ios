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
    @StateObject private var notificationService = NotificationService.shared
    @State private var notificationHandler = NotificationHandler()

    init() {
        do {
            let container = try ModelContainer(for: Timer.self, TodoItem.self)
            _modelContainer = State(initialValue: container)

            // Reset app state if running UI tests
            Task { @MainActor in
                UITestsHelpers.resetAppState(modelContext: container.mainContext)
            }

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
            TimerListView(notificationHandler: notificationHandler)
                .environmentObject(notificationService)
                .task {
                    // Configure notification handler
                    notificationHandler.configure(modelContext: modelContainer.mainContext)

                    // Request notification permission on app launch
                    _ = await notificationService.requestPermission()
                }
        }
        .modelContainer(modelContainer)
    }
}
