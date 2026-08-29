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

        Window("Chronos", id: "dashboard") {
            DashboardView(model: model)
                .frame(minWidth: 760, minHeight: 520)
        }
        .defaultSize(width: 980, height: 680)
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot = CollectorCoordinator.Snapshot()
    @Published private(set) var recentSessions: [ActivitySession] = []
    @Published private(set) var persistenceError: String?

    private let store: ActivityStore?
    private var terminationObserver: NSObjectProtocol?

    private lazy var collector = CollectorCoordinator(
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
}
