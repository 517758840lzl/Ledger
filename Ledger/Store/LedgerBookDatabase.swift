//
//  LedgerBookDatabase.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation
import SQLite3

struct LedgerBookContents {
    var accounts: [Account] = []
    var categories: [Category] = []
    var transactions: [Transaction] = []
    var budgets: [MonthBudget] = []
    var savingsGoal: Double = 0
}

/// Local book. Small preferences stay outside this file.
final class LedgerBookDatabase {
    var handle: OpaquePointer?
    let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init?(root: URL) {
        let url = root.appendingPathComponent("ledger.sqlite")
        var opened: OpaquePointer?
        guard sqlite3_open(url.path, &opened) == SQLITE_OK, let opened else { return nil }
        handle = opened
        sqlite3_exec(opened, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        guard createTables() else {
            sqlite3_close(opened)
            handle = nil
            return nil
        }
    }

    deinit {
        if let handle { sqlite3_close(handle) }
    }

    var containsBook: Bool { count("account") > 0 }

    var origin: String { meta("origin") ?? "user" }

    func setOrigin(_ value: String) { setMeta("origin", value) }

    func changeTokenData() -> Data? {
        guard let text = meta("cloudToken") else { return nil }
        return Data(base64Encoded: text)
    }

    func setChangeTokenData(_ data: Data) {
        setMeta("cloudToken", data.base64EncodedString())
    }

    func loadBook() -> LedgerBookContents {
        var book = LedgerBookContents()
        book.accounts = loadAccounts()
        book.categories = loadCategories()
        book.transactions = loadEntries()
        book.budgets = loadBudgets()
        book.savingsGoal = Double(meta("savingsGoal") ?? "") ?? 0
        return book
    }

    func makePayload() -> LedgerCloudPayload {
        var payload = LedgerCloudPayload()
        payload.accounts = loadTimedAccounts()
        payload.categories = loadTimedCategories()
        payload.entries = loadTimedEntries()
        payload.budgets = loadTimedBudgets()
        payload.savingsGoal = Double(meta("savingsGoal") ?? "") ?? 0
        payload.goalUpdatedAt = Double(meta("savingsGoalUpdatedAt") ?? "") ?? 0
        payload.hasGoal = payload.goalUpdatedAt > 0
        payload.removed = loadTombstones()
        return payload
    }

    /// Writes the in-memory book. Returns true when a row actually changed.
    func store(
        accounts: [Account],
        categories: [Category],
        transactions: [Transaction],
        budgets: [MonthBudget],
        savingsGoal: Double
    ) -> Bool {
        let now = Date().timeIntervalSince1970
        let oldAccounts = Dictionary(uniqueKeysWithValues: loadTimedAccounts().map { ($0.account.id, $0) })
        let oldCategories = Dictionary(uniqueKeysWithValues: loadTimedCategories().map { ($0.category.id, $0) })
        let oldEntries = Dictionary(uniqueKeysWithValues: loadTimedEntries().map { ($0.transaction.id, $0) })
        let oldBudgets = Dictionary(uniqueKeysWithValues: loadTimedBudgets().map { ($0.budget.yearMonth, $0) })
        var nextAccounts: [LedgerTimedAccount] = []
        var nextCategories: [LedgerTimedCategory] = []
        var nextEntries: [LedgerTimedEntry] = []
        var nextBudgets: [LedgerTimedBudget] = []
        var changed = false
        for (index, account) in accounts.enumerated() {
            if let old = oldAccounts[account.id], old.account == account, old.position == index {
                nextAccounts.append(old)
            } else {
                changed = true
                nextAccounts.append(LedgerTimedAccount(account: account, position: index, updatedAt: now))
            }
        }
        for (index, category) in categories.enumerated() {
            if let old = oldCategories[category.id], old.category == category, old.position == index {
                nextCategories.append(old)
            } else {
                changed = true
                nextCategories.append(LedgerTimedCategory(category: category, position: index, updatedAt: now))
            }
        }
        for (index, transaction) in transactions.enumerated() {
            if let old = oldEntries[transaction.id], old.transaction == transaction, old.position == index {
                nextEntries.append(old)
            } else {
                changed = true
                nextEntries.append(LedgerTimedEntry(transaction: transaction, position: index, updatedAt: now))
            }
        }
        for budget in budgets {
            if let old = oldBudgets[budget.yearMonth], old.budget == budget {
                nextBudgets.append(old)
            } else {
                changed = true
                nextBudgets.append(LedgerTimedBudget(budget: budget, updatedAt: now))
            }
        }
        let removedAccounts = Set(oldAccounts.keys).subtracting(accounts.map(\.id))
        let removedCategories = Set(oldCategories.keys).subtracting(categories.map(\.id))
        let removedEntries = Set(oldEntries.keys).subtracting(transactions.map(\.id))
        let removedBudgets = Set(oldBudgets.keys).subtracting(budgets.map(\.yearMonth))
        if !removedAccounts.isEmpty || !removedCategories.isEmpty || !removedEntries.isEmpty || !removedBudgets.isEmpty {
            changed = true
        }
        let oldGoal = Double(meta("savingsGoal") ?? "") ?? 0
        let oldGoalTime = Double(meta("savingsGoalUpdatedAt") ?? "") ?? 0
        var goalTime = oldGoalTime
        if abs(oldGoal - savingsGoal) > 0.000_001 || oldGoalTime == 0 {
            changed = true
            goalTime = now
        }
        guard changed else { return false }
        sqlite3_exec(handle, "BEGIN", nil, nil, nil)
        exec("DELETE FROM account")
        exec("DELETE FROM category")
        exec("DELETE FROM entry")
        exec("DELETE FROM budget")
        nextAccounts.forEach { insert($0) }
        nextCategories.forEach { insert($0) }
        nextEntries.forEach { insert($0) }
        nextBudgets.forEach { insert($0) }
        removedAccounts.forEach { markRemoved(LedgerRecordName.account($0), now) }
        removedCategories.forEach { markRemoved(LedgerRecordName.category($0), now) }
        removedEntries.forEach { markRemoved(LedgerRecordName.entry($0), now) }
        removedBudgets.forEach { markRemoved(LedgerRecordName.budget($0), now) }
        let alive = Set(nextAccounts.map { LedgerRecordName.account($0.account.id) }
            + nextCategories.map { LedgerRecordName.category($0.category.id) }
            + nextEntries.map { LedgerRecordName.entry($0.transaction.id) }
            + nextBudgets.map { LedgerRecordName.budget($0.budget.yearMonth) })
        alive.forEach { clearRemoved($0) }
        setMeta("savingsGoal", String(savingsGoal))
        setMeta("savingsGoalUpdatedAt", String(goalTime))
        sqlite3_exec(handle, "COMMIT", nil, nil, nil)
        return true
    }

    /// Cloud book replaces an untouched local seed. Tombstones are cleared so the download is not deleted again.
    func replace(with payload: LedgerCloudPayload) {
        sqlite3_exec(handle, "BEGIN", nil, nil, nil)
        exec("DELETE FROM account")
        exec("DELETE FROM category")
        exec("DELETE FROM entry")
        exec("DELETE FROM budget")
        exec("DELETE FROM tombstone")
        payload.accounts.forEach { insert($0) }
        payload.categories.forEach { insert($0) }
        payload.entries.forEach { insert($0) }
        payload.budgets.forEach { insert($0) }
        if payload.hasGoal {
            setMeta("savingsGoal", String(payload.savingsGoal))
            setMeta("savingsGoalUpdatedAt", String(payload.goalUpdatedAt))
        }
        sqlite3_exec(handle, "COMMIT", nil, nil, nil)
    }

    /// Keeps the newer copy of each row. Returns true when the local book changed.
    func merge(_ payload: LedgerCloudPayload) -> Bool {
        sqlite3_exec(handle, "BEGIN", nil, nil, nil)
        var changed = false
        for item in payload.accounts {
            let name = LedgerRecordName.account(item.account.id)
            if shouldSkip(name, item.updatedAt, local: timedAccount(item.account.id)?.updatedAt) { continue }
            insert(item)
            clearRemoved(name)
            changed = true
        }
        for item in payload.categories {
            let name = LedgerRecordName.category(item.category.id)
            if shouldSkip(name, item.updatedAt, local: timedCategory(item.category.id)?.updatedAt) { continue }
            insert(item)
            clearRemoved(name)
            changed = true
        }
        for item in payload.entries {
            let name = LedgerRecordName.entry(item.transaction.id)
            if shouldSkip(name, item.updatedAt, local: timedEntry(item.transaction.id)?.updatedAt) { continue }
            insert(item)
            clearRemoved(name)
            changed = true
        }
        for item in payload.budgets {
            let name = LedgerRecordName.budget(item.budget.yearMonth)
            if shouldSkip(name, item.updatedAt, local: timedBudget(item.budget.yearMonth)?.updatedAt) { continue }
            insert(item)
            clearRemoved(name)
            changed = true
        }
        if payload.hasGoal {
            let local = Double(meta("savingsGoalUpdatedAt") ?? "") ?? 0
            if payload.goalUpdatedAt > local {
                setMeta("savingsGoal", String(payload.savingsGoal))
                setMeta("savingsGoalUpdatedAt", String(payload.goalUpdatedAt))
                changed = true
            }
        }
        for (name, _) in payload.removed {
            if removeRow(named: name) { changed = true }
            markRemoved(name, Date().timeIntervalSince1970)
        }
        sqlite3_exec(handle, "COMMIT", nil, nil, nil)
        return changed
    }

    private func shouldSkip(_ name: String, _ remote: TimeInterval, local: TimeInterval?) -> Bool {
        if let removed = tombstoneTime(name), removed >= remote { return true }
        if let local, local >= remote { return true }
        return false
    }

    private func createTables() -> Bool {
        let sql = """
        CREATE TABLE IF NOT EXISTS account (
          id TEXT PRIMARY KEY, position INTEGER NOT NULL, name TEXT NOT NULL, kind TEXT NOT NULL,
          opening REAL NOT NULL, enabled INTEGER NOT NULL, manualOnly INTEGER NOT NULL,
          includeInNetWorth INTEGER NOT NULL, updatedAt REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS category (
          id TEXT PRIMARY KEY, position INTEGER NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL,
          isEssential INTEGER NOT NULL, canReduce INTEGER NOT NULL, enabled INTEGER NOT NULL,
          childrenJSON TEXT NOT NULL, disabledJSON TEXT NOT NULL, updatedAt REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS entry (
          id TEXT PRIMARY KEY, position INTEGER NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL,
          accountId TEXT NOT NULL, toAccountId TEXT, categoryId TEXT, subcategory TEXT,
          note TEXT NOT NULL, date REAL NOT NULL, updatedAt REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS budget (
          yearMonth TEXT PRIMARY KEY, id TEXT NOT NULL, total REAL NOT NULL,
          capsJSON TEXT NOT NULL, updatedAt REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS tombstone (recordName TEXT PRIMARY KEY, removedAt REAL NOT NULL);
        """
        return sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK
    }
}
