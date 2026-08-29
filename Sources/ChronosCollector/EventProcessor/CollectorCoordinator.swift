import ChronosCore
import Foundation
import OSLog

@MainActor
public final class CollectorCoordinator {
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

    private lazy var applicationTracker = ApplicationTracker(handler: handle)
    private lazy var idleTracker = IdleTracker(handler: handle)
    private lazy var screenTracker = ScreenTracker(handler: handle)
    private lazy var sessionTracker = SessionTracker(handler: handle)
    private var snapshot = Snapshot()

    public init(
        onSnapshot: @escaping (Snapshot) -> Void = { _ in },
        onEvent: @escaping (ActivityEvent) -> Void = { _ in },
        onSession: @escaping (ActivitySession) -> Void = { _ in },
        onProcessed: @escaping (
            ActivityEvent,
            [ActivitySession],
            SessionReconstructor.ActiveApplication?
        ) -> Void = { _, _, _ in }
    ) {
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

    private func handle(_ event: ActivityEvent) {
        // Pause is a privacy boundary: do not retain even coarse events until the
        // user explicitly resumes tracking.
        guard snapshot.isTracking || event.type == .trackingResumed else { return }
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
        case .screenWake, .sessionUnlocked:
            snapshot.isScreenAwake = true
            applicationTracker.emitCurrentApplication(at: event.timestamp)
        case .trackingPaused:
            snapshot.isTracking = false
            snapshot.currentSessionStartedAt = nil
        case .trackingResumed:
            snapshot.isTracking = true
        case .appDeactivated, .sessionLocked:
            snapshot.currentSessionStartedAt = nil
        }
        publish()

        logger.debug("Event: \(event.type.rawValue, privacy: .public)")
    }

    private func publish() {
        onSnapshot(snapshot)
    }
}
