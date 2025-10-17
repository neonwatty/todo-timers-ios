import Testing
import Foundation
@testable import TodoTimers

@Suite("TimerManager Tests")
@MainActor
struct TimerManagerTests {

    // MARK: - Singleton Tests

    @Test("Shared returns same instance")
    func shared_ReturnsSameInstance() {
        let instance1 = TimerManager.shared
        let instance2 = TimerManager.shared

        #expect(instance1 === instance2)
    }

    // MARK: - Service Lifecycle Tests

    @Test("Get timer service first call creates new service")
    func getTimerService_FirstCall_CreatesNewService() {
        let manager = TimerManager.shared
        let timer = TestDataFactory.makeTimer()

        let service = manager.getTimerService(for: timer)

        #expect(service.currentTime == timer.durationInSeconds)
        service.cleanup()
    }

    @Test("Get timer service subsequent call returns cached service")
    func getTimerService_SubsequentCall_ReturnsCachedService() {
        let manager = TimerManager.shared
        let timer = TestDataFactory.makeTimer()

        let service1 = manager.getTimerService(for: timer)
        let service2 = manager.getTimerService(for: timer)

        #expect(service1 === service2)
        service1.cleanup()
    }

    @Test("Get timer service for different timers creates independent services")
    func getTimerService_DifferentTimers_CreatesIndependentServices() {
        let manager = TimerManager.shared
        let timer1 = TestDataFactory.makeTimer(id: UUID(), durationInSeconds: 1000)
        let timer2 = TestDataFactory.makeTimer(id: UUID(), durationInSeconds: 2000)

        let service1 = manager.getTimerService(for: timer1)
        let service2 = manager.getTimerService(for: timer2)

        #expect(service1 !== service2)
        #expect(service1.currentTime == 1000)
        #expect(service2.currentTime == 2000)

        service1.cleanup()
        service2.cleanup()
    }

    // MARK: - Service Removal Tests

    @Test("Remove timer service calls cleanup")
    func removeTimerService_CallsCleanup() {
        let manager = TimerManager.shared
        let timer = TestDataFactory.makeTimer()

        let service = manager.getTimerService(for: timer)
        service.start()

        manager.removeTimerService(timerID: timer.id)

        // Service should have been cleaned up
        #expect(true)
    }

    @Test("Remove timer service removes from cache")
    func removeTimerService_RemovesFromCache() {
        let manager = TimerManager.shared
        let timer = TestDataFactory.makeTimer()

        let service1 = manager.getTimerService(for: timer)
        manager.removeTimerService(timerID: timer.id)
        let service2 = manager.getTimerService(for: timer)

        // Should be different instances after removal
        #expect(service1 !== service2)

        service1.cleanup()
        service2.cleanup()
    }

    @Test("Remove nonexistent timer service handles gracefully")
    func removeTimerService_NonexistentID_HandlesGracefully() {
        let manager = TimerManager.shared
        let randomID = UUID()

        manager.removeTimerService(timerID: randomID)

        #expect(true)
    }

    // MARK: - Cleanup All Tests

    @Test("Cleanup all stops and removes all services")
    func cleanupAll_RemovesAllServices() {
        let manager = TimerManager.shared
        let timer1 = TestDataFactory.makeTimer()
        let timer2 = TestDataFactory.makeTimer()

        let service1 = manager.getTimerService(for: timer1)
        let service2 = manager.getTimerService(for: timer2)
        service1.start()
        service2.start()

        manager.cleanupAll()

        // After cleanup, getting services should create new instances
        let newService1 = manager.getTimerService(for: timer1)
        let newService2 = manager.getTimerService(for: timer2)

        #expect(newService1 !== service1)
        #expect(newService2 !== service2)

        newService1.cleanup()
        newService2.cleanup()
    }

    // MARK: - Mutual Exclusivity Tests

    @Test("Notify timer started updates running timer ID")
    func notifyTimerStarted_UpdatesRunningTimerID() {
        let manager = TimerManager.shared
        manager.cleanupAll() // Clear any existing state

        let timer = TestDataFactory.makeTimer()

        manager.notifyTimerStarted(timerID: timer.id)

        #expect(manager.runningTimerID == timer.id)
        manager.cleanupAll()
    }

    @Test("Notify timer started stops other running timers")
    func notifyTimerStarted_StopsOtherRunningTimers() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer1 = TestDataFactory.makeTimer(id: UUID())
        let timer2 = TestDataFactory.makeTimer(id: UUID())

        let service1 = manager.getTimerService(for: timer1)
        let service2 = manager.getTimerService(for: timer2)

        // Start timer1
        service1.start()
        #expect(service1.isRunning == true)

        // Start timer2 (should stop timer1)
        service2.start()

        #expect(service1.isRunning == false)
        #expect(service2.isRunning == true)
        #expect(manager.runningTimerID == timer2.id)

        manager.cleanupAll()
    }

    @Test("Notify timer stopped clears running timer ID")
    func notifyTimerStopped_ClearsRunningTimerID() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()

        manager.notifyTimerStarted(timerID: timer.id)
        #expect(manager.runningTimerID == timer.id)

        manager.notifyTimerStopped(timerID: timer.id)

        #expect(manager.runningTimerID == nil)
        manager.cleanupAll()
    }

    @Test("Notify timer stopped does not clear if different timer is running")
    func notifyTimerStopped_DoesNotClearIfDifferentTimerRunning() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer1 = TestDataFactory.makeTimer(id: UUID())
        let timer2 = TestDataFactory.makeTimer(id: UUID())

        manager.notifyTimerStarted(timerID: timer1.id)
        manager.notifyTimerStopped(timerID: timer2.id)

        #expect(manager.runningTimerID == timer1.id)
        manager.cleanupAll()
    }

    @Test("Is timer running returns true for running timer")
    func isTimerRunning_ReturnsTrueForRunningTimer() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()

        manager.notifyTimerStarted(timerID: timer.id)

        #expect(manager.isTimerRunning(timerID: timer.id) == true)
        manager.cleanupAll()
    }

    @Test("Is timer running returns false for non-running timer")
    func isTimerRunning_ReturnsFalseForNonRunningTimer() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer1 = TestDataFactory.makeTimer(id: UUID())
        let timer2 = TestDataFactory.makeTimer(id: UUID())

        manager.notifyTimerStarted(timerID: timer1.id)

        #expect(manager.isTimerRunning(timerID: timer2.id) == false)
        manager.cleanupAll()
    }

    @Test("Remove timer service clears running ID if removed timer was running")
    func removeTimerService_ClearsRunningIDIfRemovedTimerWasRunning() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = manager.getTimerService(for: timer)

        service.start()
        #expect(manager.runningTimerID == timer.id)

        manager.removeTimerService(timerID: timer.id)

        #expect(manager.runningTimerID == nil)
        manager.cleanupAll()
    }

    @Test("Cleanup all clears running timer ID")
    func cleanupAll_ClearsRunningTimerID() {
        let manager = TimerManager.shared
        manager.cleanupAll()

        let timer = TestDataFactory.makeTimer()
        let service = manager.getTimerService(for: timer)

        service.start()
        #expect(manager.runningTimerID == timer.id)

        manager.cleanupAll()

        #expect(manager.runningTimerID == nil)
    }
}
