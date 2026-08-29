import ChronosCore
import Foundation
import Testing

@Test func migrationsAndSessionRoundTrip() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("chronos-db-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    let event = ActivityEvent(timestamp: base, type: .trackingPaused, source: .simulated)
    let session = ActivitySession(
        startedAt: base.addingTimeInterval(-60),
        endedAt: base,
        applicationBundleID: "test.editor",
        applicationName: "Editor",
        endReason: .trackingPaused
    )

    try store.record(event: event, completedSessions: [session], activeApplication: nil)
    let sessions = try store.sessions(
        from: base.addingTimeInterval(-120),
        to: base.addingTimeInterval(1)
    )

    #expect(sessions == [session])
}

@Test func recoveryNeverInventsTimeAfterLastObservation() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("chronos-recovery-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    let active = SessionReconstructor.ActiveApplication(
        bundleID: "test.editor",
        name: "Editor",
        startedAt: base
    )
    try store.record(
        event: ActivityEvent(timestamp: base.addingTimeInterval(30), type: .screenWake),
        completedSessions: [],
        activeApplication: active
    )

    let possibleRecovery = try store.recoverInterruptedSession()
    let recovered = try #require(possibleRecovery)
    #expect(recovered.startedAt == base)
    #expect(recovered.endedAt == base.addingTimeInterval(30))
    #expect(recovered.isUncertain)
    #expect(recovered.endReason == .interrupted)
}
