import ChronosCore
import Foundation
import Testing

@Test func sessionDurationNeverBecomesNegative() {
    let now = Date()
    let session = ActivitySession(
        startedAt: now,
        endedAt: now.addingTimeInterval(-1),
        applicationBundleID: "test.app",
        applicationName: "Test",
        endReason: .interrupted
    )
    #expect(session.duration == 0)
}
