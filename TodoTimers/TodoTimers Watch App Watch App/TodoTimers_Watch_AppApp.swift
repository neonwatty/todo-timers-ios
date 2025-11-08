//
//  TodoTimers_Watch_AppApp.swift
//  TodoTimers Watch App Watch App
//
//  Created by Jeremy Watt on 10/15/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TodoTimers_Watch_App_Watch_AppApp: App {
    @StateObject private var connectivityService = WatchConnectivityService.shared

    private let modelContainer: ModelContainer

    init() {
        do {
            // Configure model container with migration support
            let schema = Schema([Timer.self, TodoItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // If migration fails, delete the old database and create a fresh one
                print("⚠️ Watch: Migration failed, resetting database: \(error.localizedDescription)")
                try Self.deleteOldDatabase()
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Watch: Created fresh database")
            }

            // Request notification permissions
            requestNotificationPermissions()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private static func deleteOldDatabase() throws {
        // Get the App Group container URL (used for iPhone/Watch sync)
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.neonatty.TodoTimers") else {
            print("⚠️ Watch: Could not find App Group container")
            return
        }

        let appSupport = containerURL.appendingPathComponent("Library/Application Support")
        let storeURL = appSupport.appendingPathComponent("default.store")

        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
            print("🗑️ Watch: Deleted old database at: \(storeURL.path)")
        }

        // Also try to delete any related files (wal, shm)
        let walURL = appSupport.appendingPathComponent("default.store-wal")
        let shmURL = appSupport.appendingPathComponent("default.store-shm")

        try? FileManager.default.removeItem(at: walURL)
        try? FileManager.default.removeItem(at: shmURL)
    }

    var body: some Scene {
        WindowGroup {
            WatchTimerListView()
                .environmentObject(connectivityService)
                .task {
                    // Configure connectivity service with model context
                    connectivityService.configure(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Failed to request Watch notification permission: \(error.localizedDescription)")
            }
        }
    }
}
