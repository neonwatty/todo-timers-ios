import Testing
import Foundation
@testable import TodoTimers

@Suite("Timer Model Tests")
struct TimerTests {

    // MARK: - Initialization Tests

    @Test("Timer initialization with default values")
    func timerInitialization_DefaultValues() {
        let timer = Timer(
            name: "Test Timer",
            durationInSeconds: 1500
        )

        #expect(timer.name == "Test Timer")
        #expect(timer.durationInSeconds == 1500)
        #expect(timer.icon == "timer")
        #expect(timer.colorHex == "#007AFF")
        #expect(timer.notes == nil)
        #expect(timer.todoItems.isEmpty)
    }

    @Test("Timer initialization with custom values")
    func timerInitialization_CustomValues() {
        let timer = Timer(
            name: "Workout",
            durationInSeconds: 1800,
            icon: "figure.run",
            colorHex: "#FF3B30",
            notes: "Don't forget to hydrate"
        )

        #expect(timer.name == "Workout")
        #expect(timer.durationInSeconds == 1800)
        #expect(timer.icon == "figure.run")
        #expect(timer.colorHex == "#FF3B30")
        #expect(timer.notes == "Don't forget to hydrate")
    }

    @Test("Timer initialization sets createdAt and updatedAt")
    func timerInitialization_SetsTimestamps() {
        let before = Date()
        let timer = Timer(name: "Test", durationInSeconds: 60)
        let after = Date()

        #expect(timer.createdAt >= before && timer.createdAt <= after)
        #expect(timer.updatedAt >= before && timer.updatedAt <= after)
    }

    // MARK: - Validation Tests

    @Test("Validation succeeds for valid timer")
    func validate_ValidTimer_DoesNotThrow() throws {
        let timer = Timer(
            name: "Valid Timer",
            durationInSeconds: 1500
        )

        try timer.validate()
        #expect(timer.isValid == true)
    }

    @Test("Validation fails for empty name")
    func validate_EmptyName_ThrowsError() {
        let timer = Timer(
            name: "",
            durationInSeconds: 1500
        )

        #expect(timer.isValid == false)
        #expect(throws: ValidationError.self) {
            try timer.validate()
        }
    }

    @Test("Validation fails for whitespace-only name")
    func validate_WhitespaceName_ThrowsError() {
        let timer = Timer(
            name: "   ",
            durationInSeconds: 1500
        )

        #expect(timer.isValid == false)
        #expect(throws: ValidationError.self) {
            try timer.validate()
        }
    }

    @Test("Validation fails for zero duration")
    func validate_ZeroDuration_ThrowsError() {
        let timer = Timer(
            name: "Test Timer",
            durationInSeconds: 0
        )

        #expect(timer.isValid == false)
        #expect(throws: ValidationError.self) {
            try timer.validate()
        }
    }

    @Test("Validation fails for negative duration")
    func validate_NegativeDuration_ThrowsError() {
        let timer = Timer(
            name: "Test Timer",
            durationInSeconds: -100
        )

        #expect(timer.isValid == false)
        #expect(throws: ValidationError.self) {
            try timer.validate()
        }
    }

    @Test("Validation fails for excessive duration (>24 hours)")
    func validate_ExcessiveDuration_ThrowsError() {
        let timer = Timer(
            name: "Test Timer",
            durationInSeconds: 86401  // 24 hours + 1 second
        )

        #expect(timer.isValid == false)
        #expect(throws: ValidationError.self) {
            try timer.validate()
        }
    }

    // MARK: - Computed Properties Tests

    @Test("Hours calculation for 25 minutes returns 0")
    func hours_25Minutes_Returns0() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 1500  // 25 minutes
        )

        #expect(timer.hours == 0)
    }

    @Test("Hours calculation for 90 minutes returns 1")
    func hours_90Minutes_Returns1() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 5400  // 90 minutes = 1.5 hours
        )

        #expect(timer.hours == 1)
    }

    @Test("Minutes calculation extracts correct value")
    func minutes_3665Seconds_Returns1() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 3665  // 1h 1m 5s
        )

        #expect(timer.minutes == 1)
    }

    @Test("Seconds calculation extracts correct value")
    func seconds_125Seconds_Returns5() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 125  // 2m 5s
        )

        #expect(timer.seconds == 5)
    }

    @Test("Formatted duration for less than hour shows MM:SS")
    func formattedDuration_LessThanHour_ShowsMMSS() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 1505  // 25m 5s
        )

        #expect(timer.formattedDuration == "25:05")
    }

    @Test("Formatted duration for more than hour shows HH:MM:SS")
    func formattedDuration_MoreThanHour_ShowsHHMMSS() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 3665  // 1h 1m 5s
        )

        #expect(timer.formattedDuration == "01:01:05")
    }

    @Test("Formatted duration for zero shows 00:00")
    func formattedDuration_Zero_Shows0000() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 0
        )

        #expect(timer.formattedDuration == "00:00")
    }

    @Test("Formatted duration for max duration shows correctly")
    func formattedDuration_MaxDuration_ShowsCorrectly() {
        let timer = Timer(
            name: "Test",
            durationInSeconds: 86400  // 24 hours
        )

        #expect(timer.formattedDuration == "24:00:00")
    }
}
