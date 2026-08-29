import Foundation

public struct CategoryDuration: Identifiable, Equatable, Sendable {
    public let category: ActivityCategory
    public let duration: TimeInterval
    public var id: String { category.id }

    public init(category: ActivityCategory, duration: TimeInterval) {
        self.category = category
        self.duration = duration
    }
}

public struct ApplicationDuration: Identifiable, Equatable, Sendable {
    public let bundleID: String
    public let name: String
    public let duration: TimeInterval
    public var id: String { bundleID }

    public init(bundleID: String, name: String, duration: TimeInterval) {
        self.bundleID = bundleID
        self.name = name
        self.duration = duration
    }
}

public struct FocusSession: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date
    public let productiveDuration: TimeInterval
    public let contextSwitches: Int

    public var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        productiveDuration: TimeInterval,
        contextSwitches: Int
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.productiveDuration = productiveDuration
        self.contextSwitches = contextSwitches
    }
}

public struct FocusScoreBreakdown: Equatable, Sendable {
    public let score: Int
    public let productiveFraction: Double
    public let focusFraction: Double
    public let focusLengthQuality: Double
    public let switchQuality: Double
    public let interruptionQuality: Double
}

public struct DailyAnalytics: Equatable, Sendable {
    public let interval: DateInterval
    public let activeDuration: TimeInterval
    public let productiveDuration: TimeInterval
    public let distractionDuration: TimeInterval
    public let contextSwitches: Int
    public let distractionInterruptions: Int
    public let categories: [CategoryDuration]
    public let applications: [ApplicationDuration]
    public let focusSessions: [FocusSession]
    public let focusScore: FocusScoreBreakdown?

    public static func empty(for interval: DateInterval) -> Self {
        Self(
            interval: interval,
            activeDuration: 0,
            productiveDuration: 0,
            distractionDuration: 0,
            contextSwitches: 0,
            distractionInterruptions: 0,
            categories: [],
            applications: [],
            focusSessions: [],
            focusScore: nil
        )
    }
}
