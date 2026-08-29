import CSQLite
import Foundation

public enum SQLiteValue: Sendable, Equatable {
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
    case null
}

public struct SQLiteFailure: Error, CustomStringConvertible, Sendable {
    public let operation: String
    public let code: Int32
    public let message: String

    public var description: String {
        "SQLite \(operation) failed (\(code)): \(message)"
    }
}

public struct SQLiteRow {
    fileprivate let statement: OpaquePointer

    public func string(at index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let text = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: text)
    }

    public func double(at index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }

    public func integer(at index: Int32) -> Int64? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_int64(statement, index)
    }

    public func data(at index: Int32) -> Data? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let bytes = sqlite3_column_blob(statement, index) else { return nil }
        let count = Int(sqlite3_column_bytes(statement, index))
        return Data(bytes: bytes, count: count)
    }
}

public final class SQLiteDatabase: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var connection: OpaquePointer?

    public init(url: URL) throws {
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )

        var database: OpaquePointer?
        let code = sqlite3_open_v2(
            url.path,
            &database,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard code == SQLITE_OK, let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) }
                ?? "Could not allocate database connection"
            if let database { sqlite3_close(database) }
            throw SQLiteFailure(operation: "open", code: code, message: message)
        }
        connection = database

        do {
            try execute("PRAGMA foreign_keys = ON")
            try execute("PRAGMA journal_mode = WAL")
            try execute("PRAGMA synchronous = NORMAL")
            try execute("PRAGMA busy_timeout = 3000")
        } catch {
            sqlite3_close(database)
            connection = nil
            throw error
        }
    }

    deinit {
        lock.lock()
        if let connection { sqlite3_close(connection) }
        connection = nil
        lock.unlock()
    }

    public func execute(_ sql: String, bindings: [SQLiteValue] = []) throws {
        try withLock {
            let statement = try prepare(sql)
            defer { sqlite3_finalize(statement) }
            try bind(bindings, to: statement)
            let code = sqlite3_step(statement)
            guard code == SQLITE_DONE || code == SQLITE_ROW else {
                throw failure(operation: "execute", code: code)
            }
        }
    }

    public func query(
        _ sql: String,
        bindings: [SQLiteValue] = [],
        row: (SQLiteRow) throws -> Void
    ) throws {
        try withLock {
            let statement = try prepare(sql)
            defer { sqlite3_finalize(statement) }
            try bind(bindings, to: statement)

            while true {
                let code = sqlite3_step(statement)
                if code == SQLITE_DONE { return }
                guard code == SQLITE_ROW else {
                    throw failure(operation: "query", code: code)
                }
                try row(SQLiteRow(statement: statement))
            }
        }
    }

    public func transaction<T>(_ body: () throws -> T) throws -> T {
        try withLock {
            try execute("BEGIN IMMEDIATE")
            do {
                let result = try body()
                try execute("COMMIT")
                return result
            } catch {
                try? execute("ROLLBACK")
                throw error
            }
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        guard let connection else {
            throw SQLiteFailure(operation: "prepare", code: SQLITE_MISUSE, message: "Database is closed")
        }
        var statement: OpaquePointer?
        let code = sqlite3_prepare_v2(connection, sql, -1, &statement, nil)
        guard code == SQLITE_OK, let statement else {
            throw failure(operation: "prepare", code: code)
        }
        return statement
    }

    private func bind(_ values: [SQLiteValue], to statement: OpaquePointer) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let code: Int32
            switch value {
            case .integer(let value):
                code = sqlite3_bind_int64(statement, index, value)
            case .real(let value):
                code = sqlite3_bind_double(statement, index, value)
            case .text(let value):
                code = value.withCString { pointer in
                    sqlite3_bind_text(statement, index, pointer, -1, sqliteTransient)
                }
            case .blob(let value):
                code = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(bytes.count), sqliteTransient)
                }
            case .null:
                code = sqlite3_bind_null(statement, index)
            }
            guard code == SQLITE_OK else {
                throw failure(operation: "bind", code: code)
            }
        }
    }

    private func failure(operation: String, code: Int32) -> SQLiteFailure {
        let message = connection.map { String(cString: sqlite3_errmsg($0)) } ?? "Database is closed"
        return SQLiteFailure(operation: operation, code: code, message: message)
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
