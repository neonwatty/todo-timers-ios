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
            modelContainer = try ModelContainer(for: Timer.self, TodoItem.self)

            // Request notification permissions
            requestNotificationPermissions()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
