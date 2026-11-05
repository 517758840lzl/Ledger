//
//  LedgerBookDatabase+Rows.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation
import SQLite3

extension LedgerBookDatabase {
    func loadAccounts() -> [Account] { loadTimedAccounts().map(\.account) }
    func loadCategories() -> [Category] { loadTimedCategories().map(\.category) }
    func loadEntries() -> [Transaction] { loadTimedEntries().map(\.transaction) }
    func loadBudgets() -> [MonthBudget] { loadTimedBudgets().map(\.budget) }

    func timedAccount(_ id: UUID) -> LedgerTimedAccount? {
        loadTimedAccounts().first { $0.account.id == id }
    }

    func timedCategory(_ id: UUID) -> LedgerTimedCategory? {
        loadTimedCategories().first { $0.category.id == id }
    }

    func timedEntry(_ id: UUID) -> LedgerTimedEntry? {
        loadTimedEntries().first { $0.transaction.id == id }
    }

    func timedBudget(_ yearMonth: String) -> LedgerTimedBudget? {
        loadTimedBudgets().first { $0.budget.yearMonth == yearMonth }
    }

    func loadTimedAccounts() -> [LedgerTimedAccount] {
        var rows: [LedgerTimedAccount] = []
        step("SELECT id, position, name, kind, opening, enabled, manualOnly, includeInNetWorth, updatedAt FROM account ORDER BY position", read: { stmt in
            guard let id = uuid(stmt, 0), let name = columnText(stmt, 2), let kindRaw = columnText(stmt, 3),
                  let kind = AccountKind(rawValue: kindRaw) else { return }
            let account = Account(
                id: id,
                name: name,
                kind: kind,
                openingBalance: sqlite3_column_double(stmt, 4),
                enabled: sqlite3_column_int(stmt, 5) != 0,
                manualOnly: sqlite3_column_int(stmt, 6) != 0,
                includeInNetWorth: sqlite3_column_int(stmt, 7) != 0
            )
            rows.append(LedgerTimedAccount(account: account, position: Int(sqlite3_column_int(stmt, 1)), updatedAt: sqlite3_column_double(stmt, 8)))
        })
        return rows
    }

    func loadTimedCategories() -> [LedgerTimedCategory] {
        var rows: [LedgerTimedCategory] = []
        step("SELECT id, position, name, type, isEssential, canReduce, enabled, childrenJSON, disabledJSON, updatedAt FROM category ORDER BY position", read: { stmt in
            guard let id = uuid(stmt, 0), let name = columnText(stmt, 2), let typeRaw = columnText(stmt, 3),
                  let type = TxType(rawValue: typeRaw) else { return }
            let category = Category(
                id: id,
                name: name,
                type: type,
                isEssential: sqlite3_column_int(stmt, 4) != 0,
                canReduce: sqlite3_column_int(stmt, 5) != 0,
                enabled: sqlite3_column_int(stmt, 6) != 0,
                children: decodeStrings(columnText(stmt, 7) ?? "[]"),
                disabledChildren: decodeStrings(columnText(stmt, 8) ?? "[]")
            )
            rows.append(LedgerTimedCategory(category: category, position: Int(sqlite3_column_int(stmt, 1)), updatedAt: sqlite3_column_double(stmt, 9)))
        })
        return rows
    }

    func loadTimedEntries() -> [LedgerTimedEntry] {
        var rows: [LedgerTimedEntry] = []
        step("SELECT id, position, type, amount, accountId, toAccountId, categoryId, subcategory, note, date, updatedAt FROM entry ORDER BY position", read: { stmt in
            guard let id = uuid(stmt, 0), let typeRaw = columnText(stmt, 2), let type = TxType(rawValue: typeRaw),
                  let accountId = uuid(stmt, 4) else { return }
            let transaction = Transaction(
                id: id,
                type: type,
                amount: sqlite3_column_double(stmt, 3),
                accountId: accountId,
                toAccountId: uuid(stmt, 5),
                categoryId: uuid(stmt, 6),
                subcategory: columnText(stmt, 7),
                note: columnText(stmt, 8) ?? "",
                date: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 9))
            )
            rows.append(LedgerTimedEntry(transaction: transaction, position: Int(sqlite3_column_int(stmt, 1)), updatedAt: sqlite3_column_double(stmt, 10)))
        })
        return rows
    }

    func loadTimedBudgets() -> [LedgerTimedBudget] {
        var rows: [LedgerTimedBudget] = []
        step("SELECT yearMonth, id, total, capsJSON, updatedAt FROM budget ORDER BY yearMonth", read: { stmt in
            guard let yearMonth = columnText(stmt, 0), let id = uuid(stmt, 1) else { return }
            let budget = MonthBudget(
                id: id,
                yearMonth: yearMonth,
                total: sqlite3_column_double(stmt, 2),
                categoryCaps: decodeCaps(columnText(stmt, 3) ?? "{}")
            )
            rows.append(LedgerTimedBudget(budget: budget, updatedAt: sqlite3_column_double(stmt, 4)))
        })
        return rows
    }

    func insert(_ row: LedgerTimedAccount) {
        let account = row.account
        step("INSERT OR REPLACE INTO account (id, position, name, kind, opening, enabled, manualOnly, includeInNetWorth, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", bind: { stmt in
            bindText(stmt, 1, account.id.uuidString)
            sqlite3_bind_int(stmt, 2, Int32(row.position))
            bindText(stmt, 3, account.name)
            bindText(stmt, 4, account.kind.rawValue)
            sqlite3_bind_double(stmt, 5, account.openingBalance)
            sqlite3_bind_int(stmt, 6, account.enabled ? 1 : 0)
            sqlite3_bind_int(stmt, 7, account.manualOnly ? 1 : 0)
            sqlite3_bind_int(stmt, 8, account.includeInNetWorth ? 1 : 0)
            sqlite3_bind_double(stmt, 9, row.updatedAt)
        })
    }

    func insert(_ row: LedgerTimedCategory) {
        let category = row.category
        step("INSERT OR REPLACE INTO category (id, position, name, type, isEssential, canReduce, enabled, childrenJSON, disabledJSON, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", bind: { stmt in
            bindText(stmt, 1, category.id.uuidString)
            sqlite3_bind_int(stmt, 2, Int32(row.position))
            bindText(stmt, 3, category.name)
            bindText(stmt, 4, category.type.rawValue)
            sqlite3_bind_int(stmt, 5, category.isEssential ? 1 : 0)
            sqlite3_bind_int(stmt, 6, category.canReduce ? 1 : 0)
            sqlite3_bind_int(stmt, 7, category.enabled ? 1 : 0)
            bindText(stmt, 8, encodeStrings(category.children))
            bindText(stmt, 9, encodeStrings(category.disabledChildren))
            sqlite3_bind_double(stmt, 10, row.updatedAt)
        })
    }

    func insert(_ row: LedgerTimedEntry) {
        let transaction = row.transaction
        step("INSERT OR REPLACE INTO entry (id, position, type, amount, accountId, toAccountId, categoryId, subcategory, note, date, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", bind: { stmt in
            bindText(stmt, 1, transaction.id.uuidString)
            sqlite3_bind_int(stmt, 2, Int32(row.position))
            bindText(stmt, 3, transaction.type.rawValue)
            sqlite3_bind_double(stmt, 4, transaction.amount)
            bindText(stmt, 5, transaction.accountId.uuidString)
            bindOptional(stmt, 6, transaction.toAccountId?.uuidString)
            bindOptional(stmt, 7, transaction.categoryId?.uuidString)
            bindOptional(stmt, 8, transaction.subcategory)
            bindText(stmt, 9, transaction.note)
            sqlite3_bind_double(stmt, 10, transaction.date.timeIntervalSince1970)
            sqlite3_bind_double(stmt, 11, row.updatedAt)
        })
    }

    func insert(_ row: LedgerTimedBudget) {
        let budget = row.budget
        step("INSERT OR REPLACE INTO budget (yearMonth, id, total, capsJSON, updatedAt) VALUES (?, ?, ?, ?, ?)", bind: { stmt in
            bindText(stmt, 1, budget.yearMonth)
            bindText(stmt, 2, budget.id.uuidString)
            sqlite3_bind_double(stmt, 3, budget.total)
            bindText(stmt, 4, encodeCaps(budget.categoryCaps))
            sqlite3_bind_double(stmt, 5, row.updatedAt)
        })
    }

    private func uuid(_ stmt: OpaquePointer, _ index: Int32) -> UUID? {
        guard let text = columnText(stmt, index) else { return nil }
        return UUID(uuidString: text)
    }

    private func bindOptional(_ stmt: OpaquePointer, _ index: Int32, _ value: String?) {
        if let value {
            bindText(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }
}
