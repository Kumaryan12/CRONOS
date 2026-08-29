import AppKit
import ChronosCore
import Foundation

@MainActor
public final class SessionTracker {
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
        observe(NSWorkspace.sessionDidResignActiveNotification, event: .sessionLocked)
        observe(NSWorkspace.sessionDidBecomeActiveNotification, event: .sessionUnlocked)
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
