import Foundation
import SwiftData

/// Helper utilities for UI tests
@MainActor
struct UITestsHelpers {
    /// Check if the app is running in UI test mode
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Reset all app state for clean UI test runs
    static func resetAppState(modelContext: ModelContext) {
        guard isUITesting else { return }

        print("🔄 [UITestsHelpers] Starting state reset...")

        // Reset SwiftData - delete all timers (cascades to todos)
        do {
            // Get counts before deletion
            let timerDescriptor = FetchDescriptor<Timer>()
            let timersBefore = (try? modelContext.fetchCount(timerDescriptor)) ?? 0
            print("📊 [UITestsHelpers] Timers before deletion: \(timersBefore)")

            try modelContext.delete(model: Timer.self)
            try modelContext.save()

            // Verify deletion
            let timersAfter = (try? modelContext.fetchCount(timerDescriptor)) ?? 0
            print("✅ [UITestsHelpers] SwiftData reset complete - Timers after deletion: \(timersAfter)")
        } catch {
            print("❌ [UITestsHelpers] Failed to reset SwiftData: \(error.localizedDescription)")
        }

        // Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            let keysBefore = UserDefaults.standard.dictionaryRepresentation().keys.count
            print("📊 [UITestsHelpers] UserDefaults keys before reset: \(keysBefore)")

            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()

            let keysAfter = UserDefaults.standard.dictionaryRepresentation().keys.count
            print("✅ [UITestsHelpers] UserDefaults reset complete - Keys after reset: \(keysAfter)")
        }

        // Clear timer services
        TimerManager.shared.cleanupAll()
        print("✅ [UITestsHelpers] Timer services cleared")

        print("🎯 [UITestsHelpers] State reset complete!")
    }
}
