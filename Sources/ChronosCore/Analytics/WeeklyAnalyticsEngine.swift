import Foundation

public struct WeeklyAnalyticsEngine: Sendable {
    private let dailyEngine: DailyAnalyticsEngine
    private var calendar: Calendar

    public init(
        categorizer: ApplicationCategorizer = .init(),
        calendar: Calendar = .current
    ) {
        dailyEngine = DailyAnalyticsEngine(categorizer: categorizer)
        self.calendar = calendar
    }

    public func analyze(
        sessions: [ActivitySession],
        weekContaining date: Date,
        baselineSessions: [ActivitySession] = []
    ) -> WeeklyAnalytics {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return .empty(interval: DateInterval(start: date, duration: 7 * 86_400))
        }
        let points = dailyPoints(sessions: sessions, interval: week)
        let scores = points.compactMap(\.focusScore)
        let baseline = baselineComparison(current: points, sessions: baselineSessions, before: week.start)

        return WeeklyAnalytics(
            interval: week,
            days: points,
            totalActiveDuration: points.reduce(0) { $0 + $1.activeDuration },
            totalProductiveDuration: points.reduce(0) { $0 + $1.productiveDuration },
            totalDistractionDuration: points.reduce(0) { $0 + $1.distractionDuration },
            totalFocusDuration: points.reduce(0) { $0 + $1.focusDuration },
            averageFocusScore: scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count),
            totalContextSwitches: points.reduce(0) { $0 + $1.contextSwitches },
            mostProductiveDay: points.max { $0.productiveDuration < $1.productiveDuration },
            baseline: baseline
        )
    }

    private func dailyPoints(sessions: [ActivitySession], interval: DateInterval) -> [DailyAnalyticsPoint] {
        (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: interval.start),
                  let dayInterval = calendar.dateInterval(of: .day, for: day) else { return nil }
            let analytics = dailyEngine.analyze(sessions: sessions, interval: dayInterval)
            return DailyAnalyticsPoint(
                date: dayInterval.start,
                activeDuration: analytics.activeDuration,
                productiveDuration: analytics.productiveDuration,
                distractionDuration: analytics.distractionDuration,
                focusDuration: analytics.focusSessions.reduce(0) { $0 + $1.productiveDuration },
                focusScore: analytics.focusScore?.score,
                contextSwitches: analytics.contextSwitches
            )
        }
    }

    private func baselineComparison(
        current: [DailyAnalyticsPoint],
        sessions: [ActivitySession],
        before currentStart: Date
    ) -> BaselineComparison? {
        guard let baselineStart = calendar.date(byAdding: .day, value: -14, to: currentStart) else { return nil }
        let interval = DateInterval(start: baselineStart, end: currentStart)
        let allPoints = (0..<14).compactMap { offset -> DailyAnalyticsPoint? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: baselineStart),
                  let dayInterval = calendar.dateInterval(of: .day, for: day) else { return nil }
            let analytics = dailyEngine.analyze(sessions: sessions, interval: dayInterval)
            guard analytics.activeDuration > 0 else { return nil }
            return DailyAnalyticsPoint(
                date: dayInterval.start,
                activeDuration: analytics.activeDuration,
                productiveDuration: analytics.productiveDuration,
                distractionDuration: analytics.distractionDuration,
                focusDuration: analytics.focusSessions.reduce(0) { $0 + $1.productiveDuration },
                focusScore: analytics.focusScore?.score,
                contextSwitches: analytics.contextSwitches
            )
        }.filter { interval.contains($0.date) }
        guard !allPoints.isEmpty else { return nil }

        let currentObserved = current.filter { $0.activeDuration > 0 }
        guard !currentObserved.isEmpty else { return nil }
        let currentProductive = average(currentObserved.map(\.productiveDuration))
        let currentDistraction = average(currentObserved.map(\.distractionDuration))
        let priorScores = allPoints.compactMap(\.focusScore).map(Double.init)
        let currentScores = currentObserved.compactMap(\.focusScore).map(Double.init)
        return BaselineComparison(
            sampleSize: allPoints.count,
            productiveDifference: currentProductive - average(allPoints.map(\.productiveDuration)),
            distractionDifference: currentDistraction - average(allPoints.map(\.distractionDuration)),
            focusScoreDifference: priorScores.isEmpty || currentScores.isEmpty
                ? nil
                : average(currentScores) - average(priorScores)
        )
    }

    private func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}
