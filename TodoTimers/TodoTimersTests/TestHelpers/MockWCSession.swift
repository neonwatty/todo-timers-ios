import Foundation
import WatchConnectivity

/// Mock WCSession for testing Watch Connectivity without real devices
/// Note: This is a simplified mock for unit testing message handling logic
@MainActor
class MockWCSession {
    // MARK: - Tracked Messages

    /// Messages sent via sendMessage()
    var sentMessages: [[String: Any]] = []

    /// Contexts sent via updateApplicationContext()
    var sentContexts: [[String: Any]] = []

    /// User info transfers sent via transferUserInfo()
    var sentUserInfos: [[String: Any]] = []

    // MARK: - Session State

    var isReachable: Bool = true
    var activationState: WCSessionActivationState = .activated
    var isPaired: Bool = true
    var isWatchAppInstalled: Bool = true

    // MARK: - Delegate

    weak var delegate: (any WCSessionDelegate)?

    // MARK: - Mock Methods

    /// Simulates sending a message
    func sendMessage(_ message: [String: Any]) {
        sentMessages.append(message)
    }

    /// Simulates updating application context
    func updateApplicationContext(_ context: [String: Any]) throws {
        sentContexts.append(context)
    }

    /// Simulates transferring user info
    func transferUserInfo(_ userInfo: [String: Any]) {
        sentUserInfos.append(userInfo)
    }

    /// Simulates receiving a message (triggers delegate)
    func simulateReceiveMessage(_ message: [String: Any]) {
        delegate?.session?(WCSession.default, didReceiveMessage: message)
    }

    /// Simulates receiving application context (triggers delegate)
    func simulateReceiveApplicationContext(_ context: [String: Any]) {
        delegate?.session?(WCSession.default, didReceiveApplicationContext: context)
    }

    /// Simulates reachability change (triggers delegate)
    func simulateReachabilityChange(isReachable: Bool) {
        self.isReachable = isReachable
        delegate?.sessionReachabilityDidChange?(WCSession.default)
    }

    // MARK: - Test Helpers

    /// Resets all tracked messages
    func reset() {
        sentMessages.removeAll()
        sentContexts.removeAll()
        sentUserInfos.removeAll()
    }

    /// Returns the last sent message, if any
    var lastSentMessage: [String: Any]? {
        sentMessages.last
    }

    /// Returns the last sent context, if any
    var lastSentContext: [String: Any]? {
        sentContexts.last
    }

    /// Checks if a message with specific type was sent
    func didSendMessage(type: String) -> Bool {
        sentMessages.contains { message in
            message["type"] as? String == type
        }
    }

    /// Checks if a context with specific type was sent
    func didSendContext(type: String) -> Bool {
        sentContexts.contains { context in
            context["type"] as? String == type
        }
    }
}
