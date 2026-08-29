import Foundation

public struct DailyAnalyticsPoint: Identifiable, Equatable, Sendable {
    public let date: Date
    public let activeDuration: TimeInterval
    public let productiveDuration: TimeInterval
    public let distractionDuration: TimeInterval
    public let focusDuration: TimeInterval
    public let focusScore: Int?
    public let contextSwitches: Int

    public var id: Date { date }
}

public struct BaselineComparison: Equatable, Sendable {
    public let sampleSize: Int
    public let productiveDifference: TimeInterval
    public let distractionDifference: TimeInterval
    public let focusScoreDifference: Double?
}

public struct WeeklyAnalytics: Equatable, Sendable {
    public let interval: DateInterval
    public let days: [DailyAnalyticsPoint]
    public let totalActiveDuration: TimeInterval
    public let totalProductiveDuration: TimeInterval
    public let totalDistractionDuration: TimeInterval
    public let totalFocusDuration: TimeInterval
    public let averageFocusScore: Double?
    public let totalContextSwitches: Int
    public let mostProductiveDay: DailyAnalyticsPoint?
    public let baseline: BaselineComparison?

    public static func empty(interval: DateInterval) -> Self {
        Self(
            interval: interval,
            days: [],
            totalActiveDuration: 0,
            totalProductiveDuration: 0,
            totalDistractionDuration: 0,
            totalFocusDuration: 0,
            averageFocusScore: nil,
            totalContextSwitches: 0,
            mostProductiveDay: nil,
            baseline: nil
        )
    }
}
