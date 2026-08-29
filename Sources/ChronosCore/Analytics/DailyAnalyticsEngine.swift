import Foundation

public struct DailyAnalyticsEngine: Sendable {
    private let categorizer: ApplicationCategorizer
    private let minimumFocusDuration: TimeInterval
    private let maximumFocusGap: TimeInterval

    public init(
        categorizer: ApplicationCategorizer = .init(),
        minimumFocusDuration: TimeInterval = 25 * 60,
        maximumFocusGap: TimeInterval = 5 * 60
    ) {
        self.categorizer = categorizer
        self.minimumFocusDuration = minimumFocusDuration
        self.maximumFocusGap = maximumFocusGap
    }

    public func analyze(sessions: [ActivitySession], interval: DateInterval) -> DailyAnalytics {
        let clipped = sessions.compactMap { clip($0, to: interval) }
            .sorted { $0.startedAt < $1.startedAt }
        guard !clipped.isEmpty else { return .empty(for: interval) }

        var categoryTotals: [ActivityCategory: TimeInterval] = [:]
        var applicationTotals: [String: (String, TimeInterval)] = [:]
        var productive: TimeInterval = 0
        var distraction: TimeInterval = 0

        let categorized = clipped.map { session -> (ActivitySession, ActivityCategory) in
            let category = ActivityCategory.category(id: session.categoryID) ?? categorizer.category(
                    bundleID: session.applicationBundleID,
                    applicationName: session.applicationName
                )
            categoryTotals[category, default: 0] += session.duration
            let current = applicationTotals[session.applicationBundleID] ?? (session.applicationName, 0)
            applicationTotals[session.applicationBundleID] = (current.0, current.1 + session.duration)
            if category.classification == .productive { productive += session.duration }
            if category.classification == .distraction { distraction += session.duration }
            return (session, category)
        }

        let active = clipped.reduce(0) { $0 + $1.duration }
        let switches = zip(clipped, clipped.dropFirst()).reduce(0) {
            $0 + ($1.0.applicationBundleID == $1.1.applicationBundleID ? 0 : 1)
        }
        let interruptions = zip(categorized, categorized.dropFirst()).reduce(0) { count, pair in
            count + (pair.0.1.classification == .productive && pair.1.1.classification == .distraction ? 1 : 0)
        }
        let focusSessions = detectFocusSessions(categorized)
        let focusDuration = focusSessions.reduce(0) { $0 + $1.productiveDuration }
        let score = focusScore(
            active: active,
            productive: productive,
            focused: focusDuration,
            focusSessions: focusSessions,
            switches: switches,
            interruptions: interruptions
        )

        return DailyAnalytics(
            interval: interval,
            activeDuration: active,
            productiveDuration: productive,
            distractionDuration: distraction,
            contextSwitches: switches,
            distractionInterruptions: interruptions,
            categories: categoryTotals.map(CategoryDuration.init).sorted { $0.duration > $1.duration },
            applications: applicationTotals.map {
                ApplicationDuration(bundleID: $0.key, name: $0.value.0, duration: $0.value.1)
            }.sorted { $0.duration > $1.duration },
            focusSessions: focusSessions,
            focusScore: score
        )
    }

    private func detectFocusSessions(
        _ items: [(ActivitySession, ActivityCategory)]
    ) -> [FocusSession] {
        var result: [FocusSession] = []
        var run: [(ActivitySession, ActivityCategory)] = []

        func finalized(_ run: [(ActivitySession, ActivityCategory)]) -> FocusSession? {
            guard let first = run.first, let last = run.last else { return nil }
            let productive = run.filter { $0.1.classification == .productive }
                .reduce(0) { $0 + $1.0.duration }
            let total = last.0.endedAt.timeIntervalSince(first.0.startedAt)
            let switches = max(0, run.count - 1)
            let switchesPerHour = total > 0 ? Double(switches) / (total / 3600) : .infinity
            guard total >= minimumFocusDuration,
                  productive / max(total, 1) >= 0.8,
                  switchesPerHour <= 12 else { return nil }
            return FocusSession(
                startedAt: first.0.startedAt,
                endedAt: last.0.endedAt,
                productiveDuration: productive,
                contextSwitches: switches
            )
        }

        for item in items {
            let gap = run.last.map { item.0.startedAt.timeIntervalSince($0.0.endedAt) } ?? 0
            if item.1.classification == .distraction || gap > maximumFocusGap {
                if let focus = finalized(run) { result.append(focus) }
                run.removeAll(keepingCapacity: true)
            }
            if item.1.classification != .distraction { run.append(item) }
        }
        if let focus = finalized(run) { result.append(focus) }
        return result
    }

    private func focusScore(
        active: TimeInterval,
        productive: TimeInterval,
        focused: TimeInterval,
        focusSessions: [FocusSession],
        switches: Int,
        interruptions: Int
    ) -> FocusScoreBreakdown? {
        guard active >= 5 * 60 else { return nil }
        let productiveFraction = clamp(productive / active)
        let focusFraction = clamp(focused / active)
        let averageFocus = focusSessions.isEmpty ? 0 : focused / Double(focusSessions.count)
        let focusLengthQuality = clamp(averageFocus / 3600)
        let switchesPerHour = Double(switches) / (active / 3600)
        let switchQuality = clamp(1 - switchesPerHour / 30)
        let interruptionQuality = clamp(1 - Double(interruptions) / 12)
        let value = 100 * (
            0.35 * productiveFraction +
            0.30 * focusFraction +
            0.15 * focusLengthQuality +
            0.10 * switchQuality +
            0.10 * interruptionQuality
        )
        return FocusScoreBreakdown(
            score: Int(value.rounded()),
            productiveFraction: productiveFraction,
            focusFraction: focusFraction,
            focusLengthQuality: focusLengthQuality,
            switchQuality: switchQuality,
            interruptionQuality: interruptionQuality
        )
    }

    private func clip(_ session: ActivitySession, to interval: DateInterval) -> ActivitySession? {
        let start = max(session.startedAt, interval.start)
        let end = min(session.endedAt, interval.end)
        guard end > start else { return nil }
        return ActivitySession(
            id: session.id,
            startedAt: start,
            endedAt: end,
            applicationBundleID: session.applicationBundleID,
            applicationName: session.applicationName,
            categoryID: session.categoryID,
            endReason: session.endReason,
            isUncertain: session.isUncertain
        )
    }

    private func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
}
