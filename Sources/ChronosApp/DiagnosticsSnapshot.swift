import Foundation

struct DiagnosticsSnapshot: Equatable {
    var collectorCPUPercent: Double = 0
    var memoryBytes: UInt64 = 0
    var eventsProcessed: Int = 0
    var sessionsCompleted: Int = 0
    var databaseWrites: Int = 0
    var analyticsExecutions: Int = 0
    var databaseBytes: Int64 = 0
    var eventsPerHour: Double = 0
    var writesPerHour: Double = 0
    var collectorUptime: TimeInterval = 0
    var lastAggregation: Date?
}
