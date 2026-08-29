import AppKit

extension Notification.Name {
    static let chronosOpenDashboard = Notification.Name("app.chronos.openDashboard")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        NotificationCenter.default.post(name: .chronosOpenDashboard, object: nil)
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme == "chronos" }) else { return }
        NotificationCenter.default.post(name: .chronosOpenDashboard, object: nil)
    }
}
