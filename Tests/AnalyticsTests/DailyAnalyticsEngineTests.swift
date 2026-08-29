import ChronosCore
import Foundation
import Testing

@Test func dailyAnalyticsCalculatesCategoriesFocusAndSwitches() throws {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let interval = DateInterval(start: start, duration: 24 * 3600)
    let sessions = [
        session("com.microsoft.VSCode", "Visual Studio Code", start, 30 * 60),
        session("com.apple.Terminal", "Terminal", start.addingTimeInterval(30 * 60), 30 * 60),
        session("com.spotify.client", "Spotify", start.addingTimeInterval(60 * 60), 10 * 60)
    ]

    let analytics = DailyAnalyticsEngine().analyze(sessions: sessions, interval: interval)

    #expect(analytics.activeDuration == 70 * 60)
    #expect(analytics.productiveDuration == 60 * 60)
    #expect(analytics.distractionDuration == 10 * 60)
    #expect(analytics.contextSwitches == 2)
    #expect(analytics.distractionInterruptions == 1)
    #expect(analytics.focusSessions.count == 1)
    #expect(analytics.focusScore != nil)
}

@Test func sessionCrossingBoundaryIsClippedToRequestedDay() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let interval = DateInterval(start: start, duration: 24 * 3600)
    let crossing = session(
        "com.apple.dt.Xcode",
        "Xcode",
        start.addingTimeInterval(-30 * 60),
        60 * 60
    )

    let analytics = DailyAnalyticsEngine().analyze(sessions: [crossing], interval: interval)

    #expect(analytics.activeDuration == 30 * 60)
    #expect(analytics.productiveDuration == 30 * 60)
}

@Test func obviousClassificationIsDeterministic() {
    let categorizer = ApplicationCategorizer()
    #expect(categorizer.category(bundleID: "com.microsoft.VSCode", applicationName: "Code") == .coding)
    #expect(categorizer.category(bundleID: "com.tinyspeck.slackmacgap", applicationName: "Slack") == .communication)
    #expect(categorizer.category(bundleID: "com.valvesoftware.steam", applicationName: "Steam") == .gaming)
}

@Test func simulatedHistoryIsDeterministicForSeed() {
    let end = Date(timeIntervalSince1970: 1_700_000_000)
    let first = SimulatedDataGenerator(seed: 123).generate(days: 30, endingAt: end)
    let second = SimulatedDataGenerator(seed: 123).generate(days: 30, endingAt: end)
    let different = SimulatedDataGenerator(seed: 124).generate(days: 30, endingAt: end)

    #expect(first == second)
    #expect(first != different)
    #expect(!first.isEmpty)
}

private func session(
    _ bundleID: String,
    _ name: String,
    _ start: Date,
    _ duration: TimeInterval
) -> ActivitySession {
    ActivitySession(
        startedAt: start,
        endedAt: start.addingTimeInterval(duration),
        applicationBundleID: bundleID,
        applicationName: name,
        endReason: .applicationChanged
    )
}
