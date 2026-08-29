import ChronosCore
import CoreGraphics
import Foundation

@MainActor
public final class IdleTracker {
    public typealias Handler = (ActivityEvent) -> Void

    public var threshold: TimeInterval
    private let checkInterval: TimeInterval
    private let handler: Handler
    private var timer: DispatchSourceTimer?
    private var isIdle = false

    public init(
        threshold: TimeInterval = 5 * 60,
        checkInterval: TimeInterval = 30,
        handler: @escaping Handler
    ) {
        self.threshold = threshold
        self.checkInterval = checkInterval
        self.handler = handler
    }

    public func start() {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + checkInterval,
            repeating: checkInterval,
            leeway: .seconds(10)
        )
        timer.setEventHandler { [weak self] in self?.sample() }
        self.timer = timer
        timer.activate()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
        isIdle = false
    }

    public func sample(now: Date = Date()) {
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .null
        )
        let currentlyIdle = idleSeconds >= threshold
        guard currentlyIdle != isIdle else { return }
        isIdle = currentlyIdle

        if currentlyIdle {
            // Attribute no activity after the last observed human input.
            handler(ActivityEvent(
                timestamp: now.addingTimeInterval(-idleSeconds),
                type: .idleStarted
            ))
        } else {
            handler(ActivityEvent(timestamp: now, type: .idleEnded))
        }
    }
}
