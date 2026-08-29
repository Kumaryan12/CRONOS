import ChronosCore
import Foundation

enum SelfTestFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self { case .assertion(let message): return message }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw SelfTestFailure.assertion(message) }
}

func runSelfTests() throws {
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    var reconstructor = SessionReconstructor()
    let first = ActivityEvent(
        timestamp: base,
        type: .appActivated,
        applicationBundleID: "dev.editor",
        applicationName: "Editor",
        source: .simulated
    )
    let second = ActivityEvent(
        timestamp: base.addingTimeInterval(900),
        type: .appActivated,
        applicationBundleID: "dev.browser",
        applicationName: "Browser",
        source: .simulated
    )

    _ = reconstructor.process(first)
    let sessions = reconstructor.process(second)
    try require(sessions.count == 1, "application switch should close one session")
    try require(sessions[0].duration == 900, "closed session should last 15 minutes")

    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("chronos-self-test-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    let store = try ActivityStore(url: temporaryDirectory.appendingPathComponent("test.sqlite"))
    try store.record(event: first, completedSessions: [], activeApplication: nil)
    try store.record(
        event: second,
        completedSessions: sessions,
        activeApplication: reconstructor.activeApplication
    )

    let persisted = try store.sessions(
        from: base.addingTimeInterval(-1),
        to: base.addingTimeInterval(901)
    )
    try require(persisted.count == 1, "SQLite should return the completed session")
    try require(persisted[0].applicationName == "Editor", "SQLite should preserve application identity")
    try require(DatabaseMigrator.currentVersion == 1, "database schema should be at version 1")

    let analytics = DailyAnalyticsEngine().analyze(
        sessions: persisted,
        interval: DateInterval(start: base, duration: 24 * 3600)
    )
    try require(analytics.activeDuration == 900, "daily analytics should sum active time")
}

do {
    switch CommandLine.arguments.dropFirst().first {
    case "self-test":
        try runSelfTests()
        print("Chronos self-test passed: reconstruction, persistence, categorization, and analytics")
    case "generate":
        print("Fake-data generation is scheduled for the analytics milestone.")
    default:
        print("Usage: chronos-dev self-test | generate --days <count> --seed <seed>")
    }
} catch {
    FileHandle.standardError.write(Data("Chronos self-test failed: \(error)\n".utf8))
    exit(1)
}
