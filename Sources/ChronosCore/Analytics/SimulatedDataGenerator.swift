import Foundation

public struct SimulatedDataGenerator: Sendable {
    public let seed: UInt64
    public var calendar: Calendar

    public init(seed: UInt64 = 42, calendar: Calendar = .current) {
        self.seed = seed
        self.calendar = calendar
    }

    public func generate(days: Int, endingAt endDate: Date = Date()) -> [ActivitySession] {
        guard days > 0, let endDay = calendar.dateInterval(of: .day, for: endDate) else { return [] }
        var random = SeededGenerator(seed: seed)
        var sessions: [ActivitySession] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: endDay.start) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            let weekend = weekday == 1 || weekday == 7
            let startHour = weekend ? 10 : 8
            let startMinute = Int.random(in: 5...50, using: &random)
            guard var cursor = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: day) else {
                continue
            }

            func jitter(_ minutes: Int) -> TimeInterval {
                TimeInterval(max(5, minutes + Int.random(in: -12...12, using: &random)) * 60)
            }

            func append(
                _ bundle: String,
                _ name: String,
                _ category: ActivityCategory,
                minutes: Int,
                gap: Int = 3
            ) {
                let duration = jitter(minutes)
                sessions.append(ActivitySession(
                    id: random.nextUUID(),
                    startedAt: cursor,
                    endedAt: cursor.addingTimeInterval(duration),
                    applicationBundleID: bundle,
                    applicationName: name,
                    categoryID: category.id,
                    endReason: .applicationChanged
                ))
                cursor = cursor.addingTimeInterval(duration + TimeInterval(gap * 60))
            }

            append("com.microsoft.VSCode", "Visual Studio Code", .coding, minutes: weekend ? 55 : 88)
            if Int.random(in: 0...2, using: &random) != 0 {
                append("net.whatsapp.WhatsApp", "WhatsApp", .communication, minutes: 8, gap: 1)
            }
            append("com.apple.Terminal", "Terminal", .coding, minutes: weekend ? 35 : 58)
            cursor = cursor.addingTimeInterval(TimeInterval((weekend ? 45 : 60) * 60))
            append("net.ankiweb.dtop", "Anki", .study, minutes: weekend ? 45 : 68)

            let distractionCount = Int.random(in: 1...(weekend ? 3 : 2), using: &random)
            for _ in 0..<distractionCount {
                append("com.spotify.client", "Spotify", .entertainment, minutes: weekend ? 28 : 16, gap: 2)
            }

            if !weekend || Bool.random(using: &random) {
                append("com.microsoft.VSCode", "Visual Studio Code", .coding, minutes: weekend ? 50 : 82)
                append("com.apple.Safari", "Safari", .research, minutes: 32)
            }
        }
        return sessions.sorted { $0.startedAt < $1.startedAt }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func nextUUID() -> UUID {
        let first = next()
        let second = next()
        let bytes: uuid_t = (
            UInt8(truncatingIfNeeded: first >> 56), UInt8(truncatingIfNeeded: first >> 48),
            UInt8(truncatingIfNeeded: first >> 40), UInt8(truncatingIfNeeded: first >> 32),
            UInt8(truncatingIfNeeded: first >> 24), UInt8(truncatingIfNeeded: first >> 16),
            UInt8(truncatingIfNeeded: first >> 8), UInt8(truncatingIfNeeded: first),
            UInt8(truncatingIfNeeded: second >> 56), UInt8(truncatingIfNeeded: second >> 48),
            UInt8(truncatingIfNeeded: second >> 40), UInt8(truncatingIfNeeded: second >> 32),
            UInt8(truncatingIfNeeded: second >> 24), UInt8(truncatingIfNeeded: second >> 16),
            UInt8(truncatingIfNeeded: second >> 8), UInt8(truncatingIfNeeded: second)
        )
        return UUID(uuid: bytes)
    }
}
