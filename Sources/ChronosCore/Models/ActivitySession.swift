import Foundation

public enum SessionEndReason: String, Codable, Sendable {
    case applicationChanged
    case applicationTerminated
    case idle
    case screenSleep
    case sessionLocked
    case trackingPaused
    case collectorStopped
    case interrupted
}

public struct ActivitySession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date
    public let applicationBundleID: String
    public let applicationName: String
    public var categoryID: String?
    public let endReason: SessionEndReason
    public let isUncertain: Bool

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        applicationBundleID: String,
        applicationName: String,
        categoryID: String? = nil,
        endReason: SessionEndReason,
        isUncertain: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.applicationBundleID = applicationBundleID
        self.applicationName = applicationName
        self.categoryID = categoryID
        self.endReason = endReason
        self.isUncertain = isUncertain
    }
}
