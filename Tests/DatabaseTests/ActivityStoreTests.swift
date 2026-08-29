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

@Test func applicationRulesApplyAndExportIncludesRawEvents() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("chronos-export-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    let event = ActivityEvent(
        timestamp: base,
        type: .appActivated,
        applicationBundleID: "test.app",
        applicationName: "Test App",
        source: .simulated,
        metadata: ["test": "value"]
    )
    try store.record(event: event, completedSessions: [], activeApplication: nil)
    try store.saveApplicationRule(ApplicationRule(
        bundleID: "test.app",
        displayName: "Test App",
        categoryID: ActivityCategory.study.id,
        isExcluded: true
    ))

    let rules = try store.applicationRules()
    #expect(rules.count == 1)
    #expect(rules[0].isExcluded)
    #expect(rules[0].categoryID == ActivityCategory.study.id)

    let data = try store.exportData()
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let export = try decoder.decode(ActivityExport.self, from: data)
    #expect(export.events == [event])
    #expect(export.applicationRules == rules)
}

@Test func deleteRangeRemovesOnlyOverlappingHistory() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("chronos-delete-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = try ActivityStore(url: directory.appendingPathComponent("test.sqlite"))
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    let first = ActivitySession(
        startedAt: base,
        endedAt: base.addingTimeInterval(60),
        applicationBundleID: "test.first",
        applicationName: "First",
        endReason: .applicationChanged
    )
    let second = ActivitySession(
        startedAt: base.addingTimeInterval(3600),
        endedAt: base.addingTimeInterval(3660),
        applicationBundleID: "test.second",
        applicationName: "Second",
        endReason: .applicationChanged
    )
    try store.importSessions([first, second])
    try store.deleteSessions(from: base.addingTimeInterval(-1), to: base.addingTimeInterval(120))

    let remaining = try store.sessions(from: base, to: base.addingTimeInterval(4000))
    #expect(remaining == [second])
}
