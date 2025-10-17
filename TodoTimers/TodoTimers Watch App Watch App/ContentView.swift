//
//  ContentView.swift
//  TodoTimers Watch App Watch App
//
//  Created by Jeremy Watt on 10/15/25.
//

import SwiftUI
import SwiftData

// ContentView is now replaced by WatchTimerListView
// This file is kept for compatibility but not used
struct ContentView: View {
    var body: some View {
        WatchTimerListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Timer.self, TodoItem.self], inMemory: true)
        .environmentObject(WatchConnectivityService.shared)
}
