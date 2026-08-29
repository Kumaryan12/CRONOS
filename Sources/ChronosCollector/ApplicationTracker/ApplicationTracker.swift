import AppKit
import ChronosCore
import Foundation

@MainActor
public final class ApplicationTracker {
    public typealias Handler = (ActivityEvent) -> Void

    private let workspace: NSWorkspace
    private let handler: Handler
    private var observers: [NSObjectProtocol] = []

    public init(workspace: NSWorkspace = .shared, handler: @escaping Handler) {
        self.workspace = workspace
        self.handler = handler
    }

    public func start() {
        guard observers.isEmpty else { return }
        let center = workspace.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.emitApplication(from: notification, type: .appActivated)
            }
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.emitApplication(from: notification, type: .appDeactivated)
            }
        })

        emitCurrentApplication()
    }

    public func stop() {
        let center = workspace.notificationCenter
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    public func emitCurrentApplication(at timestamp: Date = Date()) {
        guard let application = workspace.frontmostApplication else { return }
        handler(ActivityEvent(
            timestamp: timestamp,
            type: .appActivated,
            applicationBundleID: application.bundleIdentifier ?? "unknown",
            applicationName: application.localizedName ?? "Unknown Application"
        ))
    }

    private func emitApplication(from notification: Notification, type: ActivityEventType) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else { return }
        handler(ActivityEvent(
            type: type,
            applicationBundleID: application.bundleIdentifier ?? "unknown",
            applicationName: application.localizedName ?? "Unknown Application"
        ))
    }
}
