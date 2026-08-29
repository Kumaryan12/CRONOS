import Foundation

public enum DatabaseMigrator {
    public static let currentVersion = 1

    public static func migrate(_ database: SQLiteDatabase) throws {
        try database.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at REAL NOT NULL
            )
            """)

        var applied = Set<Int>()
        try database.query("SELECT version FROM schema_migrations") { row in
            if let version = row.integer(at: 0) { applied.insert(Int(version)) }
        }

        if !applied.contains(1) {
            try database.transaction {
                try applyVersion1(database)
                try database.execute(
                    "INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
                    bindings: [.integer(1), .real(Date().timeIntervalSince1970)]
                )
            }
        }
    }

    private static func applyVersion1(_ database: SQLiteDatabase) throws {
        let statements = [
            """
            CREATE TABLE activity_events (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                event_type TEXT NOT NULL,
                application_bundle_id TEXT,
                application_name TEXT,
                source TEXT NOT NULL,
                metadata_json BLOB NOT NULL
            )
            """,
            """
            CREATE TABLE activity_sessions (
                id TEXT PRIMARY KEY,
                started_at REAL NOT NULL,
                ended_at REAL NOT NULL,
                application_bundle_id TEXT NOT NULL,
                application_name TEXT NOT NULL,
                category_id TEXT,
                end_reason TEXT NOT NULL,
                is_uncertain INTEGER NOT NULL DEFAULT 0,
                CHECK (ended_at >= started_at)
            )
            """,
            """
            CREATE TABLE collector_checkpoint (
                singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
                application_bundle_id TEXT NOT NULL,
                application_name TEXT NOT NULL,
                started_at REAL NOT NULL,
                last_observed_at REAL NOT NULL
            )
            """,
            """
            CREATE TABLE applications (
                bundle_id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                category_id TEXT,
                is_excluded INTEGER NOT NULL DEFAULT 0,
                updated_at REAL NOT NULL
            )
            """,
            """
            CREATE TABLE categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                classification TEXT NOT NULL,
                color_hex TEXT
            )
            """,
            """
            CREATE TABLE daily_summaries (
                local_date TEXT PRIMARY KEY,
                timezone_id TEXT NOT NULL,
                active_seconds REAL NOT NULL DEFAULT 0,
                productive_seconds REAL NOT NULL DEFAULT 0,
                distraction_seconds REAL NOT NULL DEFAULT 0,
                focus_seconds REAL NOT NULL DEFAULT 0,
                context_switches INTEGER NOT NULL DEFAULT 0,
                focus_score REAL,
                updated_at REAL NOT NULL
            )
            """,
            """
            CREATE TABLE hourly_summaries (
                local_date TEXT NOT NULL,
                hour INTEGER NOT NULL,
                category_id TEXT NOT NULL,
                duration_seconds REAL NOT NULL DEFAULT 0,
                PRIMARY KEY (local_date, hour, category_id)
            )
            """,
            """
            CREATE TABLE preferences (
                key TEXT PRIMARY KEY,
                value_json BLOB NOT NULL,
                updated_at REAL NOT NULL
            )
            """,
            "CREATE INDEX activity_events_timestamp_idx ON activity_events(timestamp)",
            "CREATE INDEX activity_events_application_idx ON activity_events(application_bundle_id, timestamp)",
            "CREATE INDEX activity_sessions_time_idx ON activity_sessions(started_at, ended_at)",
            "CREATE INDEX activity_sessions_application_idx ON activity_sessions(application_bundle_id, started_at)",
            "CREATE INDEX activity_sessions_category_idx ON activity_sessions(category_id, started_at)"
        ]
        for statement in statements { try database.execute(statement) }
    }
}
