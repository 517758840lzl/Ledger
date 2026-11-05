//
//  LedgerCloudMirror+Records.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import CloudKit
import Foundation

enum LedgerCloudKind {
    static let account = "LedgerAccount"
    static let category = "LedgerCategory"
    static let entry = "LedgerEntry"
    static let budget = "LedgerBudget"
    static let goal = "LedgerGoal"
}

enum LedgerCloudField {
    static let id = "id"
    static let name = "name"
    static let kind = "kind"
    static let opening = "opening"
    static let enabled = "enabled"
    static let manualOnly = "manualOnly"
    static let includeInNetWorth = "includeInNetWorth"
    static let updatedAt = "updatedAt"
    static let position = "position"
    static let type = "type"
    static let essential = "essential"
    static let canReduce = "canReduce"
    static let children = "children"
    static let disabled = "disabled"
    static let amount = "amount"
    static let accountId = "accountId"
    static let toAccountId = "toAccountId"
    static let categoryId = "categoryId"
    static let subcategory = "subcategory"
    static let note = "note"
    static let date = "date"
    static let yearMonth = "yearMonth"
    static let total = "total"
    static let caps = "caps"
    static let goal = "goal"
}

extension LedgerCloudMirror {
    static func records(from payload: LedgerCloudPayload, zoneID: CKRecordZone.ID) -> [CKRecord] {
        var records: [CKRecord] = []
        for item in payload.accounts {
            let record = CKRecord(recordType: LedgerCloudKind.account, recordID: id(LedgerRecordName.account(item.account.id), zoneID))
            write(record, item.account, position: item.position, updatedAt: item.updatedAt)
            records.append(record)
        }
        for item in payload.categories {
            let record = CKRecord(recordType: LedgerCloudKind.category, recordID: id(LedgerRecordName.category(item.category.id), zoneID))
            write(record, item.category, position: item.position, updatedAt: item.updatedAt)
            records.append(record)
        }
        for item in payload.entries {
            let record = CKRecord(recordType: LedgerCloudKind.entry, recordID: id(LedgerRecordName.entry(item.transaction.id), zoneID))
            write(record, item.transaction, position: item.position, updatedAt: item.updatedAt)
            records.append(record)
        }
        for item in payload.budgets {
            let record = CKRecord(recordType: LedgerCloudKind.budget, recordID: id(LedgerRecordName.budget(item.budget.yearMonth), zoneID))
            write(record, item.budget, updatedAt: item.updatedAt)
            records.append(record)
        }
        if payload.hasGoal {
            let record = CKRecord(recordType: LedgerCloudKind.goal, recordID: id(LedgerRecordName.goal, zoneID))
            record[LedgerCloudField.goal] = payload.savingsGoal as CKRecordValue
            record[LedgerCloudField.updatedAt] = payload.goalUpdatedAt as CKRecordValue
            records.append(record)
        }
        return records
    }

    static func absorb(_ record: CKRecord, into payload: inout LedgerCloudPayload) {
        switch record.recordType {
        case LedgerCloudKind.account:
            guard let account = account(from: record) else { return }
            payload.accounts.append(LedgerTimedAccount(account: account, position: integer(record, LedgerCloudField.position), updatedAt: number(record, LedgerCloudField.updatedAt)))
        case LedgerCloudKind.category:
            guard let category = category(from: record) else { return }
            payload.categories.append(LedgerTimedCategory(category: category, position: integer(record, LedgerCloudField.position), updatedAt: number(record, LedgerCloudField.updatedAt)))
        case LedgerCloudKind.entry:
            guard let transaction = transaction(from: record) else { return }
            payload.entries.append(LedgerTimedEntry(transaction: transaction, position: integer(record, LedgerCloudField.position), updatedAt: number(record, LedgerCloudField.updatedAt)))
        case LedgerCloudKind.budget:
            guard let budget = budget(from: record) else { return }
            payload.budgets.append(LedgerTimedBudget(budget: budget, updatedAt: number(record, LedgerCloudField.updatedAt)))
        case LedgerCloudKind.goal:
            payload.savingsGoal = number(record, LedgerCloudField.goal)
            payload.goalUpdatedAt = number(record, LedgerCloudField.updatedAt)
            payload.hasGoal = true
        default:
            break
        }
    }

    static func account(from record: CKRecord) -> Account? {
        guard let id = uuid(record, LedgerCloudField.id) ?? uuid(from: record.recordID.recordName),
              let name = text(record, LedgerCloudField.name),
              let kind = AccountKind(rawValue: text(record, LedgerCloudField.kind) ?? "") else { return nil }
        return Account(
            id: id,
            name: name,
            kind: kind,
            openingBalance: number(record, LedgerCloudField.opening),
            enabled: flag(record, LedgerCloudField.enabled),
            manualOnly: flag(record, LedgerCloudField.manualOnly),
            includeInNetWorth: flag(record, LedgerCloudField.includeInNetWorth)
        )
    }

    static func category(from record: CKRecord) -> Category? {
        guard let id = uuid(record, LedgerCloudField.id) ?? uuid(from: record.recordID.recordName),
              let name = text(record, LedgerCloudField.name),
              let type = TxType(rawValue: text(record, LedgerCloudField.type) ?? "") else { return nil }
        return Category(
            id: id,
            name: name,
            type: type,
            isEssential: flag(record, LedgerCloudField.essential),
            canReduce: flag(record, LedgerCloudField.canReduce),
            enabled: flag(record, LedgerCloudField.enabled),
            children: strings(text(record, LedgerCloudField.children)),
            disabledChildren: strings(text(record, LedgerCloudField.disabled))
        )
    }

    static func transaction(from record: CKRecord) -> Transaction? {
        guard let id = uuid(record, LedgerCloudField.id) ?? uuid(from: record.recordID.recordName),
              let type = TxType(rawValue: text(record, LedgerCloudField.type) ?? ""),
              let accountId = uuid(record, LedgerCloudField.accountId) else { return nil }
        return Transaction(
            id: id,
            type: type,
            amount: number(record, LedgerCloudField.amount),
            accountId: accountId,
            toAccountId: uuid(record, LedgerCloudField.toAccountId),
            categoryId: uuid(record, LedgerCloudField.categoryId),
            subcategory: text(record, LedgerCloudField.subcategory),
            note: text(record, LedgerCloudField.note) ?? "",
            date: Date(timeIntervalSince1970: number(record, LedgerCloudField.date))
        )
    }

    static func budget(from record: CKRecord) -> MonthBudget? {
        guard let yearMonth = text(record, LedgerCloudField.yearMonth),
              let id = uuid(record, LedgerCloudField.id) else { return nil }
        return MonthBudget(id: id, yearMonth: yearMonth, total: number(record, LedgerCloudField.total), categoryCaps: caps(text(record, LedgerCloudField.caps)))
    }

    private static func write(_ record: CKRecord, _ account: Account, position: Int, updatedAt: TimeInterval) {
        record[LedgerCloudField.id] = account.id.uuidString as CKRecordValue
        record[LedgerCloudField.name] = account.name as CKRecordValue
        record[LedgerCloudField.kind] = account.kind.rawValue as CKRecordValue
        record[LedgerCloudField.opening] = account.openingBalance as CKRecordValue
        record[LedgerCloudField.enabled] = (account.enabled ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.manualOnly] = (account.manualOnly ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.includeInNetWorth] = (account.includeInNetWorth ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.position] = position as CKRecordValue
        record[LedgerCloudField.updatedAt] = updatedAt as CKRecordValue
    }

    private static func write(_ record: CKRecord, _ category: Category, position: Int, updatedAt: TimeInterval) {
        record[LedgerCloudField.id] = category.id.uuidString as CKRecordValue
        record[LedgerCloudField.name] = category.name as CKRecordValue
        record[LedgerCloudField.type] = category.type.rawValue as CKRecordValue
        record[LedgerCloudField.essential] = (category.isEssential ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.canReduce] = (category.canReduce ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.enabled] = (category.enabled ? 1 : 0) as CKRecordValue
        record[LedgerCloudField.children] = json(category.children) as CKRecordValue
        record[LedgerCloudField.disabled] = json(category.disabledChildren) as CKRecordValue
        record[LedgerCloudField.position] = position as CKRecordValue
        record[LedgerCloudField.updatedAt] = updatedAt as CKRecordValue
    }

    private static func write(_ record: CKRecord, _ transaction: Transaction, position: Int, updatedAt: TimeInterval) {
        record[LedgerCloudField.id] = transaction.id.uuidString as CKRecordValue
        record[LedgerCloudField.type] = transaction.type.rawValue as CKRecordValue
        record[LedgerCloudField.amount] = transaction.amount as CKRecordValue
        record[LedgerCloudField.accountId] = transaction.accountId.uuidString as CKRecordValue
        if let toAccountId = transaction.toAccountId?.uuidString {
            record[LedgerCloudField.toAccountId] = toAccountId as CKRecordValue
        }
        if let categoryId = transaction.categoryId?.uuidString {
            record[LedgerCloudField.categoryId] = categoryId as CKRecordValue
        }
        if let subcategory = transaction.subcategory {
            record[LedgerCloudField.subcategory] = subcategory as CKRecordValue
        }
        record[LedgerCloudField.note] = transaction.note as CKRecordValue
        record[LedgerCloudField.date] = transaction.date.timeIntervalSince1970 as CKRecordValue
        record[LedgerCloudField.position] = position as CKRecordValue
        record[LedgerCloudField.updatedAt] = updatedAt as CKRecordValue
    }

    private static func write(_ record: CKRecord, _ budget: MonthBudget, updatedAt: TimeInterval) {
        record[LedgerCloudField.id] = budget.id.uuidString as CKRecordValue
        record[LedgerCloudField.yearMonth] = budget.yearMonth as CKRecordValue
        record[LedgerCloudField.total] = budget.total as CKRecordValue
        record[LedgerCloudField.caps] = jsonCaps(budget.categoryCaps) as CKRecordValue
        record[LedgerCloudField.updatedAt] = updatedAt as CKRecordValue
    }

    private static func id(_ name: String, _ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: name, zoneID: zoneID)
    }

    private static func text(_ record: CKRecord, _ key: String) -> String? {
        record[key] as? String
    }

    private static func number(_ record: CKRecord, _ key: String) -> Double {
        if let value = record[key] as? Double { return value }
        if let value = record[key] as? NSNumber { return value.doubleValue }
        return 0
    }

    private static func integer(_ record: CKRecord, _ key: String) -> Int {
        if let value = record[key] as? Int { return value }
        if let value = record[key] as? NSNumber { return value.intValue }
        return 0
    }

    private static func flag(_ record: CKRecord, _ key: String) -> Bool {
        if let value = record[key] as? Bool { return value }
        if let value = record[key] as? NSNumber { return value.intValue != 0 }
        return false
    }

    private static func uuid(_ record: CKRecord, _ key: String) -> UUID? {
        guard let text = text(record, key) else { return nil }
        return UUID(uuidString: text)
    }

    private static func uuid(from recordName: String) -> UUID? {
        guard let raw = recordName.split(separator: ":", maxSplits: 1).last else { return nil }
        return UUID(uuidString: String(raw))
    }

    private static func json(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values), let text = String(data: data, encoding: .utf8) else { return "[]" }
        return text
    }

    private static func strings(_ text: String?) -> [String] {
        guard let text, let data = text.data(using: .utf8), let values = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return values
    }

    private static func jsonCaps(_ caps: [UUID: Double]) -> String {
        let raw = Dictionary(uniqueKeysWithValues: caps.map { ($0.key.uuidString, $0.value) })
        guard let data = try? JSONEncoder().encode(raw), let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private static func caps(_ text: String?) -> [UUID: Double] {
        guard let text, let data = text.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: Double].self, from: data) else { return [:] }
        var caps: [UUID: Double] = [:]
        for (key, value) in raw {
            if let id = UUID(uuidString: key) { caps[id] = value }
        }
        return caps
    }
}
