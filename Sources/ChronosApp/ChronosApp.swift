import ChronosCollector
import ChronosCore
import ServiceManagement
import SwiftUI

@main
struct ChronosApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("Chronos", systemImage: "clock.badge.checkmark") {
            MenuBarView(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot = CollectorCoordinator.Snapshot()
    @Published private(set) var recentSessions: [ActivitySession] = []
    @Published private(set) var persistenceError: String?
    @Published private(set) var launchAtLogin = false
    @Published private(set) var lifecycleError: String?

    private let store: ActivityStore?
    private var terminationObserver: NSObjectProtocol?
    private var dashboardWindow: NSWindow?
    private var idleThresholdMinutes: Double

    private lazy var collector = CollectorCoordinator(
        idleThreshold: idleThresholdMinutes * 60,
        onSnapshot: { [weak self] in self?.snapshot = $0 },
        onSession: { [weak self] session in
            self?.recentSessions.insert(session, at: 0)
            if self?.recentSessions.count ?? 0 > 20 { self?.recentSessions.removeLast() }
            print("[Chronos] \(session.applicationName): \(Int(session.duration))s")
        },
        onProcessed: { [weak self] event, sessions, activeApplication in
            do {
                try self?.store?.record(
                    event: event,
                    completedSessions: sessions,
                    activeApplication: activeApplication
                )
            } catch {
                self?.persistenceError = String(describing: error)
            }
        }
    )

    init() {
        let storedThreshold = UserDefaults.standard.double(forKey: "idleThresholdMinutes")
        idleThresholdMinutes = storedThreshold > 0 ? storedThreshold : 5
        launchAtLogin = LoginItemManager.isEnabled
        var initializedStore: ActivityStore?
        var recoveredSession: ActivitySession?
        var initializationError: String?
        do {
            initializedStore = try ActivityStore(url: ActivityStore.defaultDatabaseURL())
            recoveredSession = try initializedStore?.recoverInterruptedSession()
        } catch {
            initializedStore = nil
            initializationError = String(describing: error)
        }
        store = initializedStore
        persistenceError = initializationError
        if let recoveredSession { recentSessions = [recoveredSession] }
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.shutdown() }
        }
        DispatchQueue.main.async { [weak self] in self?.collector.start() }
    }

    func toggleTracking() {
        snapshot.isTracking ? collector.pause() : collector.resume()
    }

    func shutdown() {
        collector.stop()
    }

    func openDashboard() {
        if dashboardWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Chronos"
            window.minSize = NSSize(width: 760, height: 520)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: DashboardView(model: self))
            window.center()
            dashboardWindow = window
        }
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateIdleThreshold(minutes: Double) {
        idleThresholdMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: "idleThresholdMinutes")
        collector.setIdleThreshold(minutes * 60)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemManager.setEnabled(enabled)
            launchAtLogin = LoginItemManager.isEnabled
            lifecycleError = nil
        } catch {
            launchAtLogin = LoginItemManager.isEnabled
            lifecycleError = String(describing: error)
        }
    }
}
