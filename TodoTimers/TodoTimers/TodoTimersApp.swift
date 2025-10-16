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
    var body: some Scene {
        WindowGroup {
            TimerListView()
        }
        .modelContainer(for: [Timer.self, TodoItem.self])
    }
}
