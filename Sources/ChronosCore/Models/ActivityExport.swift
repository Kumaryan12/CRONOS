import Foundation

public struct ActivityExport: Codable, Sendable {
    public let formatVersion: Int
    public let generatedAt: Date
    public let events: [ActivityEvent]
    public let sessions: [ActivitySession]
    public let applicationRules: [ApplicationRule]

    public init(
        formatVersion: Int = 1,
        generatedAt: Date = Date(),
        events: [ActivityEvent],
        sessions: [ActivitySession],
        applicationRules: [ApplicationRule]
    ) {
        self.formatVersion = formatVersion
        self.generatedAt = generatedAt
        self.events = events
        self.sessions = sessions
        self.applicationRules = applicationRules
    }
}
