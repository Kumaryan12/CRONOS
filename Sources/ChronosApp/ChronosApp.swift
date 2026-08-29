import ChronosCollector
import ChronosCore
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

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
    @Published private(set) var dailyAnalytics = DailyAnalytics.empty(
        for: Calendar.current.dateInterval(of: .day, for: Date())!
    )
    @Published private(set) var weeklyAnalytics = WeeklyAnalytics.empty(
        interval: Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
    )
    @Published private(set) var todaySessions: [ActivitySession] = []
    @Published private(set) var applicationRules: [ApplicationRule] = []
    @Published private(set) var privacyMessage: String?
    @Published var dashboardSection: DashboardSection = .today

    private let store: ActivityStore?
    private var terminationObserver: NSObjectProtocol?
    private var dashboardWindow: NSWindow?
    private var idleThresholdMinutes: Double

    private lazy var collector = CollectorCoordinator(
        idleThreshold: idleThresholdMinutes * 60,
        excludedBundleIDs: Set(applicationRules.filter(\.isExcluded).map(\.bundleID)),
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
                if !sessions.isEmpty { self?.refreshAnalytics() }
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
        refreshAnalytics()
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

    func saveApplicationRule(_ rule: ApplicationRule) {
        guard let store else { return }
        do {
            try store.saveApplicationRule(rule)
            if let index = applicationRules.firstIndex(where: { $0.bundleID == rule.bundleID }) {
                applicationRules[index] = rule
            } else {
                applicationRules.append(rule)
            }
            applicationRules.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            collector.setExcludedBundleIDs(Set(applicationRules.filter(\.isExcluded).map(\.bundleID)))
            refreshAnalytics()
        } catch {
            persistenceError = String(describing: error)
        }
    }

    func deleteToday() {
        guard let interval = Calendar.current.dateInterval(of: .day, for: Date()) else { return }
        deleteData(from: interval.start, to: interval.end, label: "Deleted today's activity")
    }

    func deleteData(from start: Date, to end: Date, label: String = "Deleted selected activity") {
        guard let store, end > start else { return }
        if snapshot.isTracking { collector.pause() }
        do {
            try store.deleteSessions(from: start, to: end)
            privacyMessage = label + ". Tracking remains paused."
            refreshAnalytics()
        } catch {
            persistenceError = String(describing: error)
        }
    }

    func deleteAllData() {
        guard let store else { return }
        if snapshot.isTracking { collector.pause() }
        do {
            try store.deleteAll()
            applicationRules = []
            collector.setExcludedBundleIDs([])
            privacyMessage = "Deleted all Chronos activity. Tracking remains paused."
            refreshAnalytics()
        } catch {
            persistenceError = String(describing: error)
        }
    }

    func exportAllData() {
        guard let store else { return }
        let wasTracking = snapshot.isTracking
        if wasTracking { collector.pause() }
        defer { if wasTracking { collector.resume() } }
        do {
            let data = try store.exportData()
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = "chronos-export-\(Date().formatted(.iso8601.year().month().day())).json"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            privacyMessage = "Exported Chronos data to \(url.lastPathComponent)."
        } catch {
            persistenceError = String(describing: error)
        }
    }

    func refreshAnalytics(now: Date = Date()) {
        guard let interval = Calendar.current.dateInterval(of: .day, for: now),
              let store else { return }
        do {
            applicationRules = try store.applicationRules()
            let overrides = Dictionary(uniqueKeysWithValues: applicationRules.compactMap { rule in
                ActivityCategory.category(id: rule.categoryID).map { (rule.bundleID, $0) }
            })
            let categorizer = ApplicationCategorizer(overrides: overrides)
            todaySessions = try store.sessions(from: interval.start, to: interval.end)
            dailyAnalytics = DailyAnalyticsEngine(categorizer: categorizer).analyze(
                sessions: todaySessions,
                interval: interval
            )
            recentSessions = Array(todaySessions.suffix(20).reversed())

            if let week = Calendar.current.dateInterval(of: .weekOfYear, for: now),
               let baselineStart = Calendar.current.date(byAdding: .day, value: -14, to: week.start) {
                let history = try store.sessions(from: baselineStart, to: week.end)
                weeklyAnalytics = WeeklyAnalyticsEngine(categorizer: categorizer).analyze(
                    sessions: history.filter { $0.endedAt > week.start },
                    weekContaining: now,
                    baselineSessions: history.filter { $0.startedAt < week.start }
                )
            }
        } catch {
            persistenceError = String(describing: error)
        }
    }
}
