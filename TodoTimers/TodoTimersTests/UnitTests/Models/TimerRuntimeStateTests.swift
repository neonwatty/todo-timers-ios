import Testing
import Foundation
@testable import TodoTimers

@Suite("TimerRuntimeState Model Tests")
struct TimerRuntimeStateTests {

    // MARK: - Initialization Tests

    @Test("TimerRuntimeState initialization with default values")
    func initialization_DefaultValues() {
        let timerID = UUID()
        let state = TimerRuntimeState(timerID: timerID)

        #expect(state.timerID == timerID)
        #expect(state.isRunning == false)
        #expect(state.isPaused == false)
        #expect(state.remainingSeconds == 0)
        #expect(state.startTimestamp == nil)
        #expect(state.pauseTimestamp == nil)
        #expect(state.lastUpdateTimestamp <= Date())
    }

    @Test("TimerRuntimeState initialization with custom values")
    func initialization_CustomValues() {
        let timerID = UUID()
        let startTime = Date()
        let state = TimerRuntimeState(
            timerID: timerID,
            isRunning: true,
            isPaused: false,
            remainingSeconds: 300,
            startTimestamp: startTime,
            pauseTimestamp: nil,
            lastUpdateTimestamp: startTime
        )

        #expect(state.timerID == timerID)
        #expect(state.isRunning == true)
        #expect(state.isPaused == false)
        #expect(state.remainingSeconds == 300)
        #expect(state.startTimestamp == startTime)
        #expect(state.pauseTimestamp == nil)
    }

    // MARK: - Validation Tests

    @Test("Validation succeeds for valid running state")
    func validate_ValidRunningState_DoesNotThrow() throws {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            isPaused: false,
            remainingSeconds: 300,
            startTimestamp: Date()
        )

        try state.validate()
    }

    @Test("Validation succeeds for valid paused state")
    func validate_ValidPausedState_DoesNotThrow() throws {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: false,
            isPaused: true,
            remainingSeconds: 300,
            startTimestamp: nil,
            pauseTimestamp: Date()
        )

        try state.validate()
    }

    @Test("Validation fails for negative remainingSeconds")
    func validate_NegativeRemainingSeconds_ThrowsError() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            remainingSeconds: -10
        )

        #expect(throws: TimerRuntimeState.ValidationError.self) {
            try state.validate()
        }
    }

    @Test("Validation fails when both running and paused")
    func validate_RunningAndPaused_ThrowsError() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            isPaused: true,
            remainingSeconds: 300
        )

        #expect(throws: TimerRuntimeState.ValidationError.self) {
            try state.validate()
        }
    }

    @Test("Validation fails for running state without startTimestamp")
    func validate_RunningWithoutStartTimestamp_ThrowsError() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            isPaused: false,
            remainingSeconds: 300,
            startTimestamp: nil
        )

        #expect(throws: TimerRuntimeState.ValidationError.self) {
            try state.validate()
        }
    }

    @Test("Validation fails for paused state without pauseTimestamp")
    func validate_PausedWithoutPauseTimestamp_ThrowsError() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: false,
            isPaused: true,
            remainingSeconds: 300,
            pauseTimestamp: nil
        )

        #expect(throws: TimerRuntimeState.ValidationError.self) {
            try state.validate()
        }
    }

    // MARK: - Computed Properties Tests

    @Test("elapsedTimeSinceLastUpdate calculates time difference")
    func elapsedTimeSinceLastUpdate_AfterDelay_ReturnsPositiveValue() async {
        let pastTime = Date().addingTimeInterval(-2) // 2 seconds ago
        let state = TimerRuntimeState(
            timerID: UUID(),
            lastUpdateTimestamp: pastTime
        )

        let elapsed = state.elapsedTimeSinceLastUpdate
        #expect(elapsed >= 2.0)
        #expect(elapsed < 3.0) // Allow some tolerance
    }

    @Test("calculatedRemainingSeconds returns same value when not running")
    func calculatedRemainingSeconds_NotRunning_ReturnsSameValue() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: false,
            remainingSeconds: 300,
            lastUpdateTimestamp: Date().addingTimeInterval(-5)
        )

        #expect(state.calculatedRemainingSeconds == 300)
    }

    @Test("calculatedRemainingSeconds subtracts elapsed time when running")
    func calculatedRemainingSeconds_Running_SubtractsElapsedTime() {
        let pastTime = Date().addingTimeInterval(-5) // 5 seconds ago
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 300,
            startTimestamp: pastTime,
            lastUpdateTimestamp: pastTime
        )

        let calculated = state.calculatedRemainingSeconds
        #expect(calculated <= 295) // Should have decreased by ~5 seconds
        #expect(calculated >= 294) // Allow some tolerance
    }

    @Test("calculatedRemainingSeconds returns zero when time expired")
    func calculatedRemainingSeconds_Expired_ReturnsZero() {
        let pastTime = Date().addingTimeInterval(-100) // 100 seconds ago
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 50,
            startTimestamp: pastTime,
            lastUpdateTimestamp: pastTime
        )

        #expect(state.calculatedRemainingSeconds == 0)
    }

    @Test("shouldHaveCompleted returns true when timer expired")
    func shouldHaveCompleted_Expired_ReturnsTrue() {
        let pastTime = Date().addingTimeInterval(-100)
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 50,
            startTimestamp: pastTime,
            lastUpdateTimestamp: pastTime
        )

        #expect(state.shouldHaveCompleted == true)
    }

    @Test("shouldHaveCompleted returns false when timer not expired")
    func shouldHaveCompleted_NotExpired_ReturnsFalse() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 300,
            startTimestamp: Date(),
            lastUpdateTimestamp: Date()
        )

        #expect(state.shouldHaveCompleted == false)
    }

    @Test("shouldHaveCompleted returns false when not running")
    func shouldHaveCompleted_NotRunning_ReturnsFalse() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: false,
            remainingSeconds: 0
        )

        #expect(state.shouldHaveCompleted == false)
    }

    // MARK: - State Management Tests

    @Test("updateToCurrentProgress updates remainingSeconds when running")
    func updateToCurrentProgress_Running_UpdatesRemainingSeconds() {
        let pastTime = Date().addingTimeInterval(-5)
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 300,
            startTimestamp: pastTime,
            lastUpdateTimestamp: pastTime
        )

        let beforeUpdate = state.remainingSeconds
        state.updateToCurrentProgress()
        let afterUpdate = state.remainingSeconds

        #expect(afterUpdate < beforeUpdate)
        #expect(afterUpdate <= 295)
        #expect(afterUpdate >= 294)
    }

    @Test("updateToCurrentProgress updates lastUpdateTimestamp")
    func updateToCurrentProgress_Always_UpdatesTimestamp() {
        let pastTime = Date().addingTimeInterval(-5)
        let state = TimerRuntimeState(
            timerID: UUID(),
            remainingSeconds: 300,
            lastUpdateTimestamp: pastTime
        )

        let before = Date()
        state.updateToCurrentProgress()
        let after = Date()

        #expect(state.lastUpdateTimestamp >= before)
        #expect(state.lastUpdateTimestamp <= after)
    }

    @Test("updateToCurrentProgress does not change remainingSeconds when not running")
    func updateToCurrentProgress_NotRunning_DoesNotChangeRemainingSeconds() {
        let pastTime = Date().addingTimeInterval(-5)
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: false,
            remainingSeconds: 300,
            lastUpdateTimestamp: pastTime
        )

        state.updateToCurrentProgress()
        #expect(state.remainingSeconds == 300)
    }

    @Test("markCompleted resets all state")
    func markCompleted_Always_ResetsAllState() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            isPaused: false,
            remainingSeconds: 300,
            startTimestamp: Date(),
            pauseTimestamp: nil
        )

        state.markCompleted()

        #expect(state.isRunning == false)
        #expect(state.isPaused == false)
        #expect(state.remainingSeconds == 0)
        #expect(state.startTimestamp == nil)
        #expect(state.pauseTimestamp == nil)
    }

    @Test("markCompleted updates lastUpdateTimestamp")
    func markCompleted_Always_UpdatesTimestamp() {
        let pastTime = Date().addingTimeInterval(-10)
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 300,
            startTimestamp: pastTime,
            lastUpdateTimestamp: pastTime
        )

        let before = Date()
        state.markCompleted()
        let after = Date()

        #expect(state.lastUpdateTimestamp >= before)
        #expect(state.lastUpdateTimestamp <= after)
    }

    // MARK: - Edge Cases

    @Test("State with zero remainingSeconds is valid")
    func validate_ZeroRemainingSeconds_DoesNotThrow() throws {
        let state = TimerRuntimeState(
            timerID: UUID(),
            remainingSeconds: 0
        )

        try state.validate()
    }

    @Test("State can be created with very large remainingSeconds")
    func initialization_LargeRemainingSeconds_Succeeds() {
        let state = TimerRuntimeState(
            timerID: UUID(),
            remainingSeconds: 86400 // 24 hours
        )

        #expect(state.remainingSeconds == 86400)
    }

    @Test("calculatedRemainingSeconds handles very small elapsed time")
    func calculatedRemainingSeconds_SmallElapsed_HandlesCorrectly() {
        let recentTime = Date().addingTimeInterval(-0.1) // 100ms ago
        let state = TimerRuntimeState(
            timerID: UUID(),
            isRunning: true,
            remainingSeconds: 300,
            startTimestamp: recentTime,
            lastUpdateTimestamp: recentTime
        )

        #expect(state.calculatedRemainingSeconds >= 299)
        #expect(state.calculatedRemainingSeconds <= 300)
    }
}
