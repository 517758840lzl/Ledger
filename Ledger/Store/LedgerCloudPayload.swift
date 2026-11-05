//
//  LedgerCloudPayload.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation

struct LedgerTimedAccount {
    var account: Account
    var position: Int
    var updatedAt: TimeInterval
}

struct LedgerTimedCategory {
    var category: Category
    var position: Int
    var updatedAt: TimeInterval
}

struct LedgerTimedEntry {
    var transaction: Transaction
    var position: Int
    var updatedAt: TimeInterval
}

struct LedgerTimedBudget {
    var budget: MonthBudget
    var updatedAt: TimeInterval
}

struct LedgerCloudPayload {
    var accounts: [LedgerTimedAccount] = []
    var categories: [LedgerTimedCategory] = []
    var entries: [LedgerTimedEntry] = []
    var budgets: [LedgerTimedBudget] = []
    var savingsGoal: Double = 0
    var goalUpdatedAt: TimeInterval = 0
    var hasGoal = false
    var removed: [String: TimeInterval] = [:]

    var hasChanges: Bool {
        !accounts.isEmpty || !categories.isEmpty || !entries.isEmpty || !budgets.isEmpty || hasGoal || !removed.isEmpty
    }
}

enum LedgerRecordName {
    static func account(_ id: UUID) -> String { "account:\(id.uuidString)" }
    static func category(_ id: UUID) -> String { "category:\(id.uuidString)" }
    static func entry(_ id: UUID) -> String { "entry:\(id.uuidString)" }
    static func budget(_ yearMonth: String) -> String { "budget:\(yearMonth)" }
    static let goal = "goal:savings"
}
