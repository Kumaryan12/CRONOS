import Foundation

public struct ApplicationRule: Identifiable, Codable, Equatable, Sendable {
    public let bundleID: String
    public var displayName: String
    public var categoryID: String?
    public var isExcluded: Bool

    public var id: String { bundleID }

    public init(
        bundleID: String,
        displayName: String,
        categoryID: String? = nil,
        isExcluded: Bool = false
    ) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.categoryID = categoryID
        self.isExcluded = isExcluded
    }
}
