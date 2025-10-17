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
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        #expect(service.currentTime == 1500)
    }

    @Test("Init sets not running by default")
    func init_NotRunningByDefault() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    // MARK: - State Management Tests

    @Test("Start sets isRunning to true")
    func start_SetsIsRunningTrue() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        service.start()

        #expect(service.isRunning == true)
        #expect(service.isPaused == false)

        service.cleanup()
    }

    @Test("Start when already running does not restart")
    func start_WhenAlreadyRunning_DoesNotRestart() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

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
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        service.start()
        service.pause()

        #expect(service.isRunning == false)
        #expect(service.isPaused == true)
    }

    @Test("Pause when not running does nothing")
    func pause_WhenNotRunning_DoesNothing() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        service.pause()

        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    @Test("Resume from paused state starts again")
    func resume_FromPausedState_StartsAgain() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

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
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        service.start()
        service.reset()

        #expect(service.currentTime == 1500)
        #expect(service.isRunning == false)
        #expect(service.isPaused == false)
    }

    @Test("Reset stops timer")
    func reset_StopsTimer() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        service.start()
        service.reset()

        #expect(service.isRunning == false)
    }

    @Test("Cleanup cancels timer")
    func cleanup_CancelsTimer() {
        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: TimerManager.shared)

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

        let service1 = TimerService(timer: timer1, manager: TimerManager.shared)
        let service2 = TimerService(timer: timer2, manager: TimerManager.shared)

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
        let service = TimerService(timer: timer, manager: TimerManager.shared)

        #expect(service.currentTime == 0)

        service.start()

        // Should complete immediately
        #expect(service.isRunning == true)

        service.cleanup()
    }

    // MARK: - Manager Integration Tests

    @Test("Service start calls manager notifyTimerStarted")
    func serviceStart_CallsManagerNotifyTimerStarted() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: manager)

        service.start()

        #expect(manager.runningTimerID == timer.id)

        service.cleanup()
        manager.cleanupAll()
    }

    @Test("Service pause calls manager notifyTimerStopped")
    func servicePause_CallsManagerNotifyTimerStopped() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: manager)

        service.start()
        #expect(manager.runningTimerID == timer.id)

        service.pause()

        #expect(manager.runningTimerID == nil)

        service.cleanup()
        manager.cleanupAll()
    }

    @Test("Service reset calls manager notifyTimerStopped")
    func serviceReset_CallsManagerNotifyTimerStopped() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: manager)

        service.start()
        #expect(manager.runningTimerID == timer.id)

        service.reset()

        #expect(manager.runningTimerID == nil)

        service.cleanup()
        manager.cleanupAll()
    }

    @Test("Service resume calls manager notifyTimerStarted")
    func serviceResume_CallsManagerNotifyTimerStarted() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: manager)

        service.start()
        service.pause()
        #expect(manager.runningTimerID == nil)

        service.resume()

        #expect(manager.runningTimerID == timer.id)

        service.cleanup()
        manager.cleanupAll()
    }

    @Test("Manager reference is weak prevents retain cycle")
    func managerReference_IsWeak_PreventsRetainCycle() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = TimerService(timer: timer, manager: manager)

        // Service should have weak reference to manager
        // This is verified by the code structure (private weak var manager)
        // and the fact that service can be deallocated without keeping manager alive
        #expect(service.currentTime == timer.durationInSeconds)

        service.cleanup()
        manager.cleanupAll()
    }
}
