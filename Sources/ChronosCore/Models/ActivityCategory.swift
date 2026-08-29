import Foundation

public enum CategoryClassification: String, Codable, CaseIterable, Sendable {
    case productive
    case neutral
    case distraction
    case other
}

public struct ActivityCategory: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let classification: CategoryClassification

    public init(id: String, name: String, classification: CategoryClassification) {
        self.id = id
        self.name = name
        self.classification = classification
    }

    public static let coding = Self(id: "coding", name: "Coding", classification: .productive)
    public static let study = Self(id: "study", name: "Study", classification: .productive)
    public static let research = Self(id: "research", name: "Research", classification: .productive)
    public static let writing = Self(id: "writing", name: "Writing", classification: .productive)
    public static let design = Self(id: "design", name: "Design", classification: .productive)
    public static let communication = Self(id: "communication", name: "Communication", classification: .neutral)
    public static let utilities = Self(id: "utilities", name: "Utilities", classification: .neutral)
    public static let entertainment = Self(id: "entertainment", name: "Entertainment", classification: .distraction)
    public static let gaming = Self(id: "gaming", name: "Gaming", classification: .distraction)
    public static let socialMedia = Self(id: "social_media", name: "Social Media", classification: .distraction)
    public static let uncategorized = Self(id: "uncategorized", name: "Uncategorized", classification: .other)

    public static let defaults: [Self] = [
        .coding, .study, .research, .writing, .design, .communication,
        .utilities, .entertainment, .gaming, .socialMedia, .uncategorized
    ]
}
