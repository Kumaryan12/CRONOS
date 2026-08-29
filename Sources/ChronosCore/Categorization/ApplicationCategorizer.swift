import Foundation

public struct ApplicationCategorizer: Sendable {
    private let overrides: [String: ActivityCategory]

    public init(overrides: [String: ActivityCategory] = [:]) {
        self.overrides = overrides
    }

    public func category(bundleID: String, applicationName: String) -> ActivityCategory {
        if let override = overrides[bundleID] { return override }
        let bundle = bundleID.lowercased()
        let name = applicationName.lowercased()

        if matches(bundle, name, ["xcode", "vscode", "visual studio code", "zed", "cursor", "terminal", "iterm", "warp", "github desktop"]) {
            return .coding
        }
        if matches(bundle, name, ["figma", "sketch", "pixelmator", "affinity designer"]) {
            return .design
        }
        if matches(bundle, name, ["notion", "obsidian", "bear", "ulysses", "pages", "microsoft word"]) {
            return .writing
        }
        if matches(bundle, name, ["anki", "kindle", "books", "coursera"]) {
            return .study
        }
        if matches(bundle, name, ["slack", "discord", "whatsapp", "messages", "mail", "outlook", "teams", "zoom"]) {
            return .communication
        }
        if matches(bundle, name, ["spotify", "music", "netflix", "vlc", "quicktime", "youtube"]) {
            return .entertainment
        }
        if matches(bundle, name, ["steam", "epic games", "battle.net"]) {
            return .gaming
        }
        if matches(bundle, name, ["twitter", "instagram", "reddit", "facebook", "tiktok"]) {
            return .socialMedia
        }
        if matches(bundle, name, ["finder", "system settings", "activity monitor", "preview", "calculator"]) {
            return .utilities
        }
        return .uncategorized
    }

    private func matches(_ bundle: String, _ name: String, _ needles: [String]) -> Bool {
        needles.contains { bundle.contains($0) || name.contains($0) }
    }
}
