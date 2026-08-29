import Foundation

public final class ActivityStore: @unchecked Sendable {
    public let databaseURL: URL
    private let database: SQLiteDatabase
    private let encoder = JSONEncoder()

    public init(url: URL) throws {
        databaseURL = url
        database = try SQLiteDatabase(url: url)
        try DatabaseMigrator.migrate(database)
    }

    public static func defaultDatabaseURL() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Chronos", isDirectory: true)
            .appendingPathComponent("chronos.sqlite", isDirectory: false)
    }

    public func record(
        event: ActivityEvent,
        completedSessions: [ActivitySession],
        activeApplication: SessionReconstructor.ActiveApplication?
    ) throws {
        let metadata = try encoder.encode(event.metadata)
        try database.transaction {
            try database.execute(
                """
                INSERT INTO activity_events(
                    id, timestamp, event_type, application_bundle_id,
                    application_name, source, metadata_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                bindings: [
                    .text(event.id.uuidString),
                    .real(event.timestamp.timeIntervalSince1970),
                    .text(event.type.rawValue),
                    event.applicationBundleID.map(SQLiteValue.text) ?? .null,
                    event.applicationName.map(SQLiteValue.text) ?? .null,
                    .text(event.source.rawValue),
                    .blob(metadata)
                ]
            )

            for session in completedSessions {
                try insert(session)
            }

            try database.execute("DELETE FROM collector_checkpoint")
            if let activeApplication {
                try database.execute(
                    """
                    INSERT INTO collector_checkpoint(
                        singleton_id, application_bundle_id, application_name,
                        started_at, last_observed_at
                    ) VALUES (1, ?, ?, ?, ?)
                    """,
                    bindings: [
                        .text(activeApplication.bundleID),
                        .text(activeApplication.name),
                        .real(activeApplication.startedAt.timeIntervalSince1970),
                        .real(max(event.timestamp, activeApplication.startedAt).timeIntervalSince1970)
                    ]
                )
            }
        }
    }

    @discardableResult
    public func recoverInterruptedSession() throws -> ActivitySession? {
        var checkpoint: (String, String, Date, Date)?
        try database.query(
            """
            SELECT application_bundle_id, application_name, started_at, last_observed_at
            FROM collector_checkpoint WHERE singleton_id = 1
            """
        ) { row in
            guard let bundleID = row.string(at: 0),
                  let name = row.string(at: 1),
                  let started = row.double(at: 2),
                  let observed = row.double(at: 3) else { return }
            checkpoint = (
                bundleID,
                name,
                Date(timeIntervalSince1970: started),
                Date(timeIntervalSince1970: observed)
            )
        }

        return try database.transaction {
            try database.execute("DELETE FROM collector_checkpoint")
            guard let checkpoint, checkpoint.3 > checkpoint.2 else { return nil }
            let session = ActivitySession(
                startedAt: checkpoint.2,
                endedAt: checkpoint.3,
                applicationBundleID: checkpoint.0,
                applicationName: checkpoint.1,
                endReason: .interrupted,
                isUncertain: true
            )
            try insert(session)
            return session
        }
    }

    public func sessions(from start: Date, to end: Date) throws -> [ActivitySession] {
        var sessions: [ActivitySession] = []
        try database.query(
            """
            SELECT id, started_at, ended_at, application_bundle_id, application_name,
                   category_id, end_reason, is_uncertain
            FROM activity_sessions
            WHERE ended_at > ? AND started_at < ?
            ORDER BY started_at ASC
            """,
            bindings: [.real(start.timeIntervalSince1970), .real(end.timeIntervalSince1970)]
        ) { row in
            guard let idString = row.string(at: 0),
                  let id = UUID(uuidString: idString),
                  let started = row.double(at: 1),
                  let ended = row.double(at: 2),
                  let bundleID = row.string(at: 3),
                  let name = row.string(at: 4),
                  let reasonString = row.string(at: 6),
                  let reason = SessionEndReason(rawValue: reasonString) else { return }
            sessions.append(ActivitySession(
                id: id,
                startedAt: Date(timeIntervalSince1970: started),
                endedAt: Date(timeIntervalSince1970: ended),
                applicationBundleID: bundleID,
                applicationName: name,
                categoryID: row.string(at: 5),
                endReason: reason,
                isUncertain: row.integer(at: 7) == 1
            ))
        }
        return sessions
    }

    public func deleteSessions(from start: Date, to end: Date) throws {
        try database.transaction {
            try database.execute(
                "DELETE FROM activity_sessions WHERE ended_at > ? AND started_at < ?",
                bindings: [.real(start.timeIntervalSince1970), .real(end.timeIntervalSince1970)]
            )
            try database.execute(
                "DELETE FROM activity_events WHERE timestamp >= ? AND timestamp < ?",
                bindings: [.real(start.timeIntervalSince1970), .real(end.timeIntervalSince1970)]
            )
        }
    }

    public func deleteAll() throws {
        try database.transaction {
            try database.execute("DELETE FROM activity_sessions")
            try database.execute("DELETE FROM activity_events")
            try database.execute("DELETE FROM collector_checkpoint")
            try database.execute("DELETE FROM daily_summaries")
            try database.execute("DELETE FROM hourly_summaries")
        }
    }

    public func importSessions(_ sessions: [ActivitySession]) throws {
        try database.transaction {
            for session in sessions { try insert(session) }
        }
    }

    private func insert(_ session: ActivitySession) throws {
        try database.execute(
            """
            INSERT OR IGNORE INTO activity_sessions(
                id, started_at, ended_at, application_bundle_id, application_name,
                category_id, end_reason, is_uncertain
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            bindings: [
                .text(session.id.uuidString),
                .real(session.startedAt.timeIntervalSince1970),
                .real(session.endedAt.timeIntervalSince1970),
                .text(session.applicationBundleID),
                .text(session.applicationName),
                session.categoryID.map(SQLiteValue.text) ?? .null,
                .text(session.endReason.rawValue),
                .integer(session.isUncertain ? 1 : 0)
            ]
        )
    }
}
