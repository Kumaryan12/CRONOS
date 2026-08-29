import ChronosCore
import Foundation
import Testing

private let base = Date(timeIntervalSince1970: 1_700_000_000)

@Test func applicationSwitchClosesPreviousSession() throws {
    var reconstructor = SessionReconstructor()
    #expect(reconstructor.process(app("A", at: 0)).isEmpty)

    let session = try #require(reconstructor.process(app("B", at: 15 * 60)).single)

    #expect(session.applicationName == "A")
    #expect(session.duration == 15 * 60)
    #expect(session.endReason == .applicationChanged)
}

@Test func idlePeriodIsNotCounted() throws {
    var reconstructor = SessionReconstructor()
    _ = reconstructor.process(app("A", at: 0))

    let closed = try #require(reconstructor.process(event(.idleStarted, at: 20 * 60)).single)
    _ = reconstructor.process(event(.idleEnded, at: 40 * 60))
    _ = reconstructor.process(app("A", at: 40 * 60))
    let afterReturn = try #require(reconstructor.process(app("B", at: 50 * 60)).single)

    #expect(closed.duration == 20 * 60)
    #expect(afterReturn.duration == 10 * 60)
}

@Test func screenSleepClosesSession() throws {
    var reconstructor = SessionReconstructor()
    _ = reconstructor.process(app("A", at: 0))
    let session = try #require(reconstructor.process(event(.screenSleep, at: 12 * 60)).single)
    #expect(session.endReason == .screenSleep)
    #expect(reconstructor.activeApplication == nil)
}

@Test func duplicateActivationDoesNotFragmentSession() throws {
    var reconstructor = SessionReconstructor()
    _ = reconstructor.process(app("A", at: 0))
    #expect(reconstructor.process(app("A", at: 5 * 60)).isEmpty)
    let session = try #require(reconstructor.process(app("B", at: 15 * 60)).single)
    #expect(session.duration == 15 * 60)
}

private func app(_ name: String, at offset: TimeInterval) -> ActivityEvent {
    ActivityEvent(
        timestamp: base.addingTimeInterval(offset),
        type: .appActivated,
        applicationBundleID: "test.\(name)",
        applicationName: name
    )
}

private func event(_ type: ActivityEventType, at offset: TimeInterval) -> ActivityEvent {
    ActivityEvent(timestamp: base.addingTimeInterval(offset), type: type)
}

private extension Array {
    var single: Element? { count == 1 ? first : nil }
}
