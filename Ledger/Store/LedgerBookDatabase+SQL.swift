//
//  LedgerBookDatabase+SQL.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation
import SQLite3

extension LedgerBookDatabase {
    func exec(_ sql: String) {
        sqlite3_exec(handle, sql, nil, nil, nil)
    }

    func count(_ table: String) -> Int {
        var total = 0
        step("SELECT COUNT(*) FROM \(table)", read: { stmt in
            total = Int(sqlite3_column_int(stmt, 0))
        })
        return total
    }

    func meta(_ key: String) -> String? {
        var value: String?
        step("SELECT value FROM meta WHERE key = ?", bind: { stmt in
            bindText(stmt, 1, key)
        }, read: { stmt in
            value = columnText(stmt, 0)
        })
        return value
    }

    func setMeta(_ key: String, _ value: String) {
        step("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)", bind: { stmt in
            bindText(stmt, 1, key)
            bindText(stmt, 2, value)
        }, read: { _ in })
    }

    func markRemoved(_ name: String, _ time: TimeInterval) {
        step("INSERT OR REPLACE INTO tombstone (recordName, removedAt) VALUES (?, ?)", bind: { stmt in
            bindText(stmt, 1, name)
            sqlite3_bind_double(stmt, 2, time)
        }, read: { _ in })
    }

    func clearRemoved(_ name: String) {
        step("DELETE FROM tombstone WHERE recordName = ?", bind: { stmt in
            bindText(stmt, 1, name)
        }, read: { _ in })
    }

    func tombstoneTime(_ name: String) -> TimeInterval? {
        var time: TimeInterval?
        step("SELECT removedAt FROM tombstone WHERE recordName = ?", bind: { stmt in
            bindText(stmt, 1, name)
        }, read: { stmt in
            time = sqlite3_column_double(stmt, 0)
        })
        return time
    }

    func loadTombstones() -> [String: TimeInterval] {
        var rows: [String: TimeInterval] = [:]
        step("SELECT recordName, removedAt FROM tombstone", read: { stmt in
            if let name = columnText(stmt, 0) {
                rows[name] = sqlite3_column_double(stmt, 1)
            }
        })
        return rows
    }

    @discardableResult
    func removeRow(named name: String) -> Bool {
        let parts = name.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return false }
        switch parts[0] {
        case "account":
            return deleteRow("DELETE FROM account WHERE id = ?", parts[1])
        case "category":
            return deleteRow("DELETE FROM category WHERE id = ?", parts[1])
        case "entry":
            return deleteRow("DELETE FROM entry WHERE id = ?", parts[1])
        case "budget":
            return deleteRow("DELETE FROM budget WHERE yearMonth = ?", parts[1])
        case "goal":
            setMeta("savingsGoal", "0")
            setMeta("savingsGoalUpdatedAt", String(Date().timeIntervalSince1970))
            return true
        default:
            return false
        }
    }

    func step(_ sql: String, bind: (OpaquePointer) -> Void = { _ in }, read: (OpaquePointer) -> Void = { _ in }) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return }
        defer { sqlite3_finalize(stmt) }
        bind(stmt)
        while sqlite3_step(stmt) == SQLITE_ROW {
            read(stmt)
        }
    }

    func bindText(_ stmt: OpaquePointer, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, transient)
    }

    func columnText(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL, let raw = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: raw)
    }

    func encodeStrings(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values), let text = String(data: data, encoding: .utf8) else { return "[]" }
        return text
    }

    func decodeStrings(_ text: String) -> [String] {
        guard let data = text.data(using: .utf8), let values = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return values
    }

    func encodeCaps(_ caps: [UUID: Double]) -> String {
        let raw = Dictionary(uniqueKeysWithValues: caps.map { ($0.key.uuidString, $0.value) })
        guard let data = try? JSONEncoder().encode(raw), let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    func decodeCaps(_ text: String) -> [UUID: Double] {
        guard let data = text.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: Double].self, from: data) else { return [:] }
        var caps: [UUID: Double] = [:]
        for (key, value) in raw {
            if let id = UUID(uuidString: key) { caps[id] = value }
        }
        return caps
    }

    private func deleteRow(_ sql: String, _ id: String) -> Bool {
        var removed = false
        step(sql, bind: { stmt in
            bindText(stmt, 1, id)
        })
        if sqlite3_changes(handle) > 0 { removed = true }
        return removed
    }
}
