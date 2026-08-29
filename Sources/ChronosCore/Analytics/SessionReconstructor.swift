import Foundation

public struct SessionReconstructor: Sendable {
    public struct ActiveApplication: Equatable, Sendable {
        public let bundleID: String
        public let name: String
        public let startedAt: Date

        public init(bundleID: String, name: String, startedAt: Date) {
            self.bundleID = bundleID
            self.name = name
            self.startedAt = startedAt
        }
    }

    public private(set) var activeApplication: ActiveApplication?
    public private(set) var isCollecting = true

    public init() {}

    public mutating func process(_ event: ActivityEvent) -> [ActivitySession] {
        switch event.type {
        case .appActivated:
            guard isCollecting,
                  let bundleID = event.applicationBundleID,
                  let name = event.applicationName else { return [] }

            if activeApplication?.bundleID == bundleID {
                return []
            }

            let closed = close(at: event.timestamp, reason: .applicationChanged)
            activeApplication = ActiveApplication(
                bundleID: bundleID,
                name: name,
                startedAt: event.timestamp
            )
            return closed.map { [$0] } ?? []

        case .appDeactivated:
            guard event.applicationBundleID == nil ||
                    event.applicationBundleID == activeApplication?.bundleID else { return [] }
            return close(at: event.timestamp, reason: .applicationTerminated).map { [$0] } ?? []

        case .idleStarted:
            isCollecting = false
            return close(at: event.timestamp, reason: .idle).map { [$0] } ?? []

        case .screenSleep:
            isCollecting = false
            return close(at: event.timestamp, reason: .screenSleep).map { [$0] } ?? []

        case .sessionLocked:
            isCollecting = false
            return close(at: event.timestamp, reason: .sessionLocked).map { [$0] } ?? []

        case .trackingPaused:
            isCollecting = false
            return close(at: event.timestamp, reason: .trackingPaused).map { [$0] } ?? []

        case .idleEnded, .screenWake, .sessionUnlocked, .trackingResumed:
            isCollecting = true
            return []
        }
    }

    public mutating func stop(at timestamp: Date = Date()) -> ActivitySession? {
        isCollecting = false
        return close(at: timestamp, reason: .collectorStopped)
    }

    private mutating func close(at timestamp: Date, reason: SessionEndReason) -> ActivitySession? {
        guard let activeApplication else { return nil }
        self.activeApplication = nil
        guard timestamp > activeApplication.startedAt else { return nil }
        return ActivitySession(
            startedAt: activeApplication.startedAt,
            endedAt: timestamp,
            applicationBundleID: activeApplication.bundleID,
            applicationName: activeApplication.name,
            endReason: reason
        )
    }
}
