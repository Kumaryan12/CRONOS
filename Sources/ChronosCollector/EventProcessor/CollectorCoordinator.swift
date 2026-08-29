import ChronosCore
import Foundation
import OSLog

@MainActor
public final class CollectorCoordinator {
    private static let defaultSensitiveExclusions: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass"
    ]
    public struct Snapshot: Equatable, Sendable {
        public var currentApplication: String?
        public var currentSessionStartedAt: Date?
        public var isIdle = false
        public var isScreenAwake = true
        public var isTracking = false

        public init() {}
    }

    private let logger = Logger(subsystem: "app.chronos", category: "collector")
    private var reconstructor = SessionReconstructor()
    private let onSnapshot: (Snapshot) -> Void
    private let onEvent: (ActivityEvent) -> Void
    private let onSession: (ActivitySession) -> Void
    private let onProcessed: (
        ActivityEvent,
        [ActivitySession],
        SessionReconstructor.ActiveApplication?
    ) -> Void
    private let idleThreshold: TimeInterval
    private var excludedBundleIDs: Set<String>

    private lazy var applicationTracker = ApplicationTracker(handler: handle)
    private lazy var idleTracker = IdleTracker(threshold: idleThreshold, handler: handle)
    private lazy var screenTracker = ScreenTracker(handler: handle)
    private lazy var sessionTracker = SessionTracker(handler: handle)
    private var snapshot = Snapshot()

    public init(
        idleThreshold: TimeInterval = 5 * 60,
        excludedBundleIDs: Set<String> = [],
        onSnapshot: @escaping (Snapshot) -> Void = { _ in },
        onEvent: @escaping (ActivityEvent) -> Void = { _ in },
        onSession: @escaping (ActivitySession) -> Void = { _ in },
        onProcessed: @escaping (
            ActivityEvent,
            [ActivitySession],
            SessionReconstructor.ActiveApplication?
        ) -> Void = { _, _, _ in }
    ) {
        self.idleThreshold = idleThreshold
        self.excludedBundleIDs = excludedBundleIDs.union(Self.defaultSensitiveExclusions)
        self.onSnapshot = onSnapshot
        self.onEvent = onEvent
        self.onSession = onSession
        self.onProcessed = onProcessed
    }

    public func start() {
        guard !snapshot.isTracking else { return }
        handle(ActivityEvent(
            type: .trackingResumed,
            metadata: ["reason": "collector_started"]
        ))
        applicationTracker.start()
        screenTracker.start()
        sessionTracker.start()
        idleTracker.start()
        publish()
        logger.info("Collector started")
    }

    public func stop() {
        guard snapshot.isTracking else { return }
        handle(ActivityEvent(
            type: .trackingPaused,
            metadata: ["reason": "collector_stopped"]
        ))
        applicationTracker.stop()
        screenTracker.stop()
        sessionTracker.stop()
        idleTracker.stop()
        snapshot = Snapshot()
        publish()
        logger.info("Collector stopped")
    }

    public func pause() {
        handle(ActivityEvent(type: .trackingPaused))
    }

    public func resume() {
        handle(ActivityEvent(type: .trackingResumed))
        applicationTracker.emitCurrentApplication()
    }

    public func setIdleThreshold(_ threshold: TimeInterval) {
        idleTracker.threshold = max(60, threshold)
    }

    public func setExcludedBundleIDs(_ bundleIDs: Set<String>) {
        excludedBundleIDs = bundleIDs.union(Self.defaultSensitiveExclusions)
        if let active = reconstructor.activeApplication,
           bundleIDs.contains(active.bundleID) {
            handle(ActivityEvent(
                type: .appDeactivated,
                metadata: ["reason": "excluded_application"]
            ))
        }
    }

    private func handle(_ incomingEvent: ActivityEvent) {
        // Pause is a privacy boundary: do not retain even coarse events until the
        // user explicitly resumes tracking.
        guard snapshot.isTracking || incomingEvent.type == .trackingResumed else { return }
        let event: ActivityEvent
        if incomingEvent.type == .appActivated,
           let bundleID = incomingEvent.applicationBundleID,
           excludedBundleIDs.contains(bundleID) {
            event = ActivityEvent(
                timestamp: incomingEvent.timestamp,
                type: .appDeactivated,
                source: incomingEvent.source,
                metadata: ["reason": "excluded_application"]
            )
        } else {
            event = incomingEvent
        }
        onEvent(event)
        let sessions = reconstructor.process(event)
        sessions.forEach(onSession)
        onProcessed(event, sessions, reconstructor.activeApplication)

        switch event.type {
        case .appActivated:
            snapshot.currentApplication = event.applicationName
            snapshot.currentSessionStartedAt = event.timestamp
        case .idleStarted:
            snapshot.isIdle = true
            snapshot.currentSessionStartedAt = nil
        case .idleEnded:
            snapshot.isIdle = false
            applicationTracker.emitCurrentApplication(at: event.timestamp)
        case .screenSleep:
            snapshot.isScreenAwake = false
            snapshot.currentSessionStartedAt = nil
            idleTracker.stop()
        case .screenWake, .sessionUnlocked:
            snapshot.isScreenAwake = true
            idleTracker.start()
            applicationTracker.emitCurrentApplication(at: event.timestamp)
        case .trackingPaused:
            snapshot.isTracking = false
            snapshot.currentSessionStartedAt = nil
        case .trackingResumed:
            snapshot.isTracking = true
        case .appDeactivated:
            if event.metadata["reason"] == "excluded_application" {
                snapshot.currentApplication = "Excluded application"
            }
            snapshot.currentSessionStartedAt = nil
        case .sessionLocked:
            snapshot.currentSessionStartedAt = nil
            idleTracker.stop()
        }
        publish()

        logger.debug("Event: \(event.type.rawValue, privacy: .public)")
    }

    private func publish() {
        onSnapshot(snapshot)
    }
}
