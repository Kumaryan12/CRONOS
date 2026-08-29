import AppKit
import ChronosCore
import Foundation

@MainActor
public final class ScreenTracker {
    private let center: NotificationCenter
    private let handler: (ActivityEvent) -> Void
    private var observers: [NSObjectProtocol] = []

    public init(
        center: NotificationCenter = NSWorkspace.shared.notificationCenter,
        handler: @escaping (ActivityEvent) -> Void
    ) {
        self.center = center
        self.handler = handler
    }

    public func start() {
        guard observers.isEmpty else { return }
        observe(NSWorkspace.screensDidSleepNotification, event: .screenSleep)
        observe(NSWorkspace.screensDidWakeNotification, event: .screenWake)
        observe(NSWorkspace.didWakeNotification, event: .screenWake)
    }

    public func stop() {
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    private func observe(_ name: NSNotification.Name, event: ActivityEventType) {
        observers.append(center.addObserver(forName: name, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.handler(ActivityEvent(type: event))
            }
        })
    }
}
