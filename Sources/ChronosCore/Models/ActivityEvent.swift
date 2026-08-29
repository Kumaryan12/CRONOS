import Foundation

public enum ActivityEventType: String, Codable, CaseIterable, Sendable {
    case appActivated = "app_activated"
    case appDeactivated = "app_deactivated"
    case idleStarted = "idle_started"
    case idleEnded = "idle_ended"
    case screenSleep = "screen_sleep"
    case screenWake = "screen_wake"
    case sessionLocked = "session_locked"
    case sessionUnlocked = "session_unlocked"
    case trackingPaused = "tracking_paused"
    case trackingResumed = "tracking_resumed"
}

public enum ActivitySource: String, Codable, Sendable {
    case macOS
    case browser
    case imported
    case simulated
}

public struct ActivityEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let type: ActivityEventType
    public let applicationBundleID: String?
    public let applicationName: String?
    public let source: ActivitySource
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: ActivityEventType,
        applicationBundleID: String? = nil,
        applicationName: String? = nil,
        source: ActivitySource = .macOS,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.applicationBundleID = applicationBundleID
        self.applicationName = applicationName
        self.source = source
        self.metadata = metadata
    }
}
