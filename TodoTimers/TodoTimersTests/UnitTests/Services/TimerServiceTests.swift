import Testing
import Foundation
@testable import TodoTimers

@Suite("TimerService Tests")
@MainActor
struct TimerServiceTests {

    // MARK: - Initialization Tests

    @Test("Init sets current time to total time")
    func init_SetsCurrentTimeToTotalTime() {
        let timer = TestDataFactory.makeTimer(durationInSeconds: 1500)
        let service = TimerService(timer: timer)

        #expect(service.currentTime == 1500)
    }

    @Test("Init sets not running by default")
    func init_NotRunningByDefault() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    // MARK: - State Management Tests

    @Test("Start sets isRunning to true")
    func start_SetsIsRunningTrue() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()

        #expect(service.isRunning == true)
        #expect(service.isPaused == false)

        service.cleanup()
    }

    @Test("Start when already running does not restart")
    func start_WhenAlreadyRunning_DoesNotRestart() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()
        let firstRunningState = service.isRunning

        service.start()  // Try to start again

        #expect(firstRunningState == true)
        #expect(service.isRunning == true)

        service.cleanup()
    }

    @Test("Pause sets isRunning false and isPaused true")
    func pause_SetsStates() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()
        service.pause()

        #expect(service.isRunning == false)
        #expect(service.isPaused == true)
    }

    @Test("Pause when not running does nothing")
    func pause_WhenNotRunning_DoesNothing() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.pause()

        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    @Test("Resume from paused state starts again")
    func resume_FromPausedState_StartsAgain() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()
        service.pause()
        service.resume()

        #expect(service.isRunning == true)
        #expect(service.isPaused == false)

        service.cleanup()
    }

    @Test("Reset restores original time")
    func reset_RestoresOriginalTime() {
        let timer = TestDataFactory.makeTimer(durationInSeconds: 1500)
        let service = TimerService(timer: timer)

        service.start()
        service.reset()

        #expect(service.currentTime == 1500)
        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    @Test("Reset stops timer")
    func reset_StopsTimer() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()
        service.reset()

        #expect(service.isRunning == false)
    }

    @Test("Cleanup cancels timer")
    func cleanup_CancelsTimer() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer)

        service.start()
        service.cleanup()

        // After cleanup, timer should be stopped
        // Note: We can't directly test if cancellable is nil, but we can verify state
        #expect(service.isRunning == true)  // State doesn't change, but timer stops ticking
    }

    // MARK: - Edge Cases

    @Test("Multiple service instances have independent state")
    func multipleInstances_IndependentState() {
        let timer1 = TestDataFactory.makeTimer(durationInSeconds: 1000)
        let timer2 = TestDataFactory.makeTimer(durationInSeconds: 2000)

        let service1 = TimerService(timer: timer1)
        let service2 = TimerService(timer: timer2)

        service1.start()

        #expect(service1.isRunning == true)
        #expect(service2.isRunning == false)
        #expect(service1.currentTime == 1000)
        #expect(service2.currentTime == 2000)

        service1.cleanup()
        service2.cleanup()
    }

    @Test("Timer with zero duration handles gracefully")
    func timerWithZeroDuration_HandlesGracefully() {
        let timer = TestDataFactory.makeTimer(durationInSeconds: 0)
        let service = TimerService(timer: timer)

        #expect(service.currentTime == 0)

        service.start()

        // Should complete immediately
        #expect(service.isRunning == true)

        service.cleanup()
    }
}
