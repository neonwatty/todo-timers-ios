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
            // Configure model container with migration support
            let schema = Schema([Timer.self, TodoItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            let container: ModelContainer
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // If migration fails, delete the old database and create a fresh one
                print("⚠️ Migration failed, resetting database: \(error.localizedDescription)")
                try Self.deleteOldDatabase()
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Created fresh database")
            }

            _modelContainer = State(initialValue: container)

            // Migrate existing timers to have sortOrder if needed
            Task { @MainActor in
                await Self.migrateExistingTimers(context: container.mainContext)
            }

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

    private static func deleteOldDatabase() throws {
        // Get the App Group container URL (used for iPhone/Watch sync)
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.neonatty.TodoTimers") else {
            print("⚠️ Could not find App Group container")
            return
        }

        let appSupport = containerURL.appendingPathComponent("Library/Application Support")
        let storeURL = appSupport.appendingPathComponent("default.store")

        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
            print("🗑️ Deleted old database at: \(storeURL.path)")
        }

        // Also try to delete any related files (wal, shm)
        let walURL = appSupport.appendingPathComponent("default.store-wal")
        let shmURL = appSupport.appendingPathComponent("default.store-shm")

        try? FileManager.default.removeItem(at: walURL)
        try? FileManager.default.removeItem(at: shmURL)
    }

    @MainActor
    private static func migrateExistingTimers(context: ModelContext) async {
        do {
            // Fetch all timers
            let descriptor = FetchDescriptor<Timer>(sortBy: [SortDescriptor(\.createdAt)])
            let timers = try context.fetch(descriptor)

            // Set sortOrder for any timers that have default value (0)
            // We'll set them based on creation order
            var needsMigration = false
            for (index, timer) in timers.enumerated() {
                if timer.sortOrder == 0 && index > 0 {
                    timer.sortOrder = index
                    needsMigration = true
                }
            }

            if needsMigration {
                try context.save()
                print("✅ Migrated \(timers.count) timers with sortOrder")
            }
        } catch {
            print("⚠️ Migration warning: \(error.localizedDescription)")
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
