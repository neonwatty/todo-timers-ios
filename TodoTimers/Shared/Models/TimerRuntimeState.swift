//
//  TimerRuntimeState.swift
//  TodoTimers
//
//  Created by Claude Code on 11/08/25.
//

import Foundation
import SwiftData

/// Runtime state for a timer to support background execution and state restoration
/// This model stores the ephemeral state of a running or paused timer, allowing the app
/// to restore timer state after backgrounding, suspension, or termination.
@Model
final class TimerRuntimeState {
    /// Unique identifier of the associated timer
    @Attribute(.unique) var timerID: UUID

    /// Whether the timer is currently running (countdown active)
    var isRunning: Bool

    /// Whether the timer is paused (not running but not reset)
    var isPaused: Bool

    /// Remaining time in seconds at the time of last save
    var remainingSeconds: Int

    /// Timestamp when the timer was started (nil if never started)
    var startTimestamp: Date?

    /// Timestamp when the timer was paused (nil if not paused)
    var pauseTimestamp: Date?

    /// Timestamp of the last state update (for calculating elapsed time)
    var lastUpdateTimestamp: Date

    /// Inverse relationship to Timer (optional - runtime state is created on-demand)
    @Relationship(deleteRule: .cascade, inverse: \Timer.runtimeState)
    var timer: Timer?

    /// Initializer for creating a new runtime state
    /// - Parameters:
    ///   - timerID: UUID of the associated timer
    ///   - isRunning: Whether timer is currently running
    ///   - isPaused: Whether timer is paused
    ///   - remainingSeconds: Remaining time in seconds
    ///   - startTimestamp: When the timer was started
    ///   - pauseTimestamp: When the timer was paused (if applicable)
    ///   - lastUpdateTimestamp: Timestamp of this state snapshot
    init(
        timerID: UUID,
        isRunning: Bool = false,
        isPaused: Bool = false,
        remainingSeconds: Int = 0,
        startTimestamp: Date? = nil,
        pauseTimestamp: Date? = nil,
        lastUpdateTimestamp: Date = Date()
    ) {
        self.timerID = timerID
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.remainingSeconds = remainingSeconds
        self.startTimestamp = startTimestamp
        self.pauseTimestamp = pauseTimestamp
        self.lastUpdateTimestamp = lastUpdateTimestamp
    }

    // MARK: - Computed Properties

    /// Calculates the elapsed time since the last update
    /// Used to determine how much time has passed while the app was backgrounded
    var elapsedTimeSinceLastUpdate: TimeInterval {
        Date().timeIntervalSince(lastUpdateTimestamp)
    }

    /// Calculates the current remaining seconds based on elapsed time
    /// Returns 0 if timer should have completed
    var calculatedRemainingSeconds: Int {
        guard isRunning else { return remainingSeconds }

        let elapsed = Int(elapsedTimeSinceLastUpdate)
        return max(0, remainingSeconds - elapsed)
    }

    /// Whether the timer should have completed based on elapsed time
    var shouldHaveCompleted: Bool {
        isRunning && calculatedRemainingSeconds == 0
    }

    // MARK: - State Management

    /// Updates the state to reflect current countdown progress
    /// Call this before saving to ensure accurate elapsed time calculation
    func updateToCurrentProgress() {
        if isRunning {
            remainingSeconds = calculatedRemainingSeconds
        }
        lastUpdateTimestamp = Date()
    }

    /// Marks the runtime state as completed
    /// Call this when timer finishes to clean up state
    func markCompleted() {
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        startTimestamp = nil
        pauseTimestamp = nil
        lastUpdateTimestamp = Date()
    }
}

// MARK: - Validation

extension TimerRuntimeState {
    /// Validates the runtime state for consistency
    /// - Throws: ValidationError if state is invalid
    func validate() throws {
        // Remaining seconds cannot be negative
        guard remainingSeconds >= 0 else {
            throw ValidationError.invalidDuration("Remaining seconds cannot be negative")
        }

        // Cannot be both running and paused
        guard !(isRunning && isPaused) else {
            throw ValidationError.invalidState("Timer cannot be both running and paused")
        }

        // If running, must have start timestamp
        if isRunning {
            guard startTimestamp != nil else {
                throw ValidationError.invalidState("Running timer must have start timestamp")
            }
        }

        // If paused, must have pause timestamp
        if isPaused {
            guard pauseTimestamp != nil else {
                throw ValidationError.invalidState("Paused timer must have pause timestamp")
            }
        }
    }

    enum ValidationError: Error, CustomStringConvertible {
        case invalidDuration(String)
        case invalidState(String)

        var description: String {
            switch self {
            case .invalidDuration(let message):
                return "Invalid duration: \(message)"
            case .invalidState(let message):
                return "Invalid state: \(message)"
            }
        }
    }
}
