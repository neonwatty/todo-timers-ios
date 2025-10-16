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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Timer.self, TodoItem.self])
    }
}
