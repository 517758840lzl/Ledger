//
//  LedgerStore+CSV.swift
//  Ledger
//
//  Created by Ketty on 2026/11/09.
//

import Foundation

extension LedgerStore {
    /// Own exports replace the book. A plain transaction table still appends rows.
    @discardableResult
    func importCSV(text: String) -> Int {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return 0 }
        if lines[0].hasPrefix("# ledger-export") {
            return restoreExportedBook(lines)
        }
        return appendFlatTransactions(lines)
    }

    func exportFullCSV() -> URL? {
        let df = Self.dayFormatter()
        var lines: [String] = ["# ledger-export v2"]
        lines.append("section,savingsGoal")
        lines.append("amount")
        lines.append(String(settings.savingsGoal))
        lines.append("section,accounts")
        lines.append("id,name,kind,opening,enabled,manualOnly,includeInNetWorth")
        for account in accounts {
            lines.append([
                account.id.uuidString,
                csvEscape(account.name),
                account.kind.rawValue,
                String(account.openingBalance),
                String(account.enabled),
                String(account.manualOnly),
                String(account.includeInNetWorth)
            ].joined(separator: ","))
        }
        lines.append("section,categories")
        lines.append("id,name,type,essential,canReduce,enabled,children,disabledChildren")
        for category in categories {
            lines.append([
                category.id.uuidString,
                csvEscape(category.name),
                category.type.rawValue,
                String(category.isEssential),
                String(category.canReduce),
                String(category.enabled),
                csvEscape(category.children.joined(separator: "|")),
                csvEscape(category.disabledChildren.joined(separator: "|"))
            ].joined(separator: ","))
        }
        lines.append("section,budgets")
        lines.append("yearMonth,total,caps,id")
        for budget in budgets {
            let caps = budget.categoryCaps
                .map { "\($0.key.uuidString)=\($0.value)" }
                .sorted()
                .joined(separator: "|")
            lines.append("\(budget.yearMonth),\(budget.total),\(csvEscape(caps)),\(budget.id.uuidString)")
        }
        lines.append("section,transactions")
        lines.append("date,type,amount,accountId,toAccountId,categoryId,subcategory,note,id")
        for tx in transactions {
            lines.append([
                df.string(from: tx.date),
                tx.type.rawValue,
                String(tx.amount),
                tx.accountId.uuidString,
                tx.toAccountId?.uuidString ?? "",
                tx.categoryId?.uuidString ?? "",
                csvEscape(tx.subcategory ?? ""),
                csvEscape(tx.note),
                tx.id.uuidString
            ].joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-export.csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func restoreExportedBook(_ lines: [String]) -> Int {
        let sections = csvSections(lines)
        let nextAccounts = accounts(from: sections["accounts"])
        guard !nextAccounts.isEmpty else { return 0 }
        let nextCategories = categories(from: sections["categories"])
        let nextBudgets = budgets(from: sections["budgets"])
        let nextTransactions = transactions(from: sections["transactions"], accounts: nextAccounts, categories: nextCategories)
        accounts = nextAccounts
        categories = nextCategories
        budgets = nextBudgets
        transactions = nextTransactions
        if let goal = sections["savingsGoal"]?.rows.first?.first, let amount = Double(goal) {
            settings.savingsGoal = amount
        }
        save()
        return nextTransactions.count
    }

    private func appendFlatTransactions(_ lines: [String]) -> Int {
        guard let header = lines.first?.lowercased(), header.contains("date"), header.contains("amount") else { return 0 }
        var added = 0
        let df = Self.dayFormatter()
        for line in lines.dropFirst() {
            let cols = parseCSVLine(line)
            guard cols.count >= 3, let amount = Double(cols[2]) else { continue }
            let type = LedgerText.txType(from: cols.count > 1 ? cols[1] : "expense")
            let note = (cols.count > 5 ? cols[5] : (cols.count > 4 ? cols[4] : ""))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if note != "" && transactions.contains(where: { $0.amount == amount && ($0.note == note || $0.note.ledgerText == note) }) { continue }
            let cash = accounts.first(where: { $0.kind == .cash }) ?? accounts.first
            guard let cash else { continue }
            var categoryId = categories.first(where: { $0.type == type && $0.enabled })?.id
            if cols.count > 4 {
                let name = LedgerText.canonical(cols[4])
                if let found = categories.first(where: { LedgerText.canonical($0.name) == name && $0.type == type }) {
                    categoryId = found.id
                }
            }
            let tx = Transaction(
                type: type,
                amount: amount,
                accountId: cash.id,
                categoryId: type == .transfer ? nil : categoryId,
                note: note,
                date: df.date(from: cols[0]) ?? Date()
            )
            transactions.append(tx)
            added += 1
        }
        if added > 0 { save() }
        return added
    }

    private struct CSVSection {
        var header: [String] = []
        var rows: [[String]] = []
    }

    private func csvSections(_ lines: [String]) -> [String: CSVSection] {
        var result: [String: CSVSection] = [:]
        var name = ""
        var section = CSVSection()
        var awaitingHeader = false
        func commit() {
            guard !name.isEmpty else { return }
            result[name] = section
        }
        for line in lines {
            let cols = parseCSVLine(line)
            if cols.first == "section", cols.count > 1 {
                commit()
                name = cols[1]
                section = CSVSection()
                awaitingHeader = true
                continue
            }
            if line.hasPrefix("#") { continue }
            guard !name.isEmpty else { continue }
            if awaitingHeader {
                section.header = cols
                awaitingHeader = false
            } else {
                section.rows.append(cols)
            }
        }
        commit()
        return result
    }

    private func accounts(from section: CSVSection?) -> [Account] {
        guard let section else { return [] }
        return section.rows.compactMap { cols in
            guard cols.count >= 7, let id = UUID(uuidString: cols[0]), let opening = Double(cols[3]) else { return nil }
            let kind = AccountKind(rawValue: cols[2]) ?? .other
            return Account(
                id: id,
                name: cols[1],
                kind: kind,
                openingBalance: opening,
                enabled: flag(cols[4]),
                manualOnly: flag(cols[5]),
                includeInNetWorth: flag(cols[6])
            )
        }
    }

    private func categories(from section: CSVSection?) -> [Category] {
        guard let section else { return [] }
        return section.rows.compactMap { cols in
            guard cols.count >= 7, let id = UUID(uuidString: cols[0]) else { return nil }
            var category = Category(
                id: id,
                name: cols[1],
                type: LedgerText.txType(from: cols[2]),
                isEssential: flag(cols[3]),
                canReduce: flag(cols[4]),
                enabled: flag(cols[5]),
                children: pipeList(cols[6])
            )
            if cols.count > 7 { category.disabledChildren = pipeList(cols[7]) }
            return category
        }
    }

    private func budgets(from section: CSVSection?) -> [MonthBudget] {
        guard let section else { return [] }
        return section.rows.compactMap { cols in
            guard cols.count >= 2, let total = Double(cols[1]) else { return nil }
            let id = cols.count > 3 ? UUID(uuidString: cols[3]) ?? UUID() : UUID()
            var budget = MonthBudget(id: id, yearMonth: cols[0], total: total)
            if cols.count > 2 {
                for piece in cols[2].split(separator: "|") {
                    let pair = piece.split(separator: "=", maxSplits: 1).map(String.init)
                    guard pair.count == 2, let id = UUID(uuidString: pair[0]), let amount = Double(pair[1]) else { continue }
                    budget.categoryCaps[id] = amount
                }
            }
            return budget
        }
    }

    private func transactions(from section: CSVSection?, accounts: [Account], categories: [Category]) -> [Transaction] {
        guard let section else { return [] }
        let usesIDs = section.header.contains("accountId")
        let df = Self.dayFormatter()
        return section.rows.compactMap { cols in
            guard cols.count >= 3, let amount = Double(cols[2]) else { return nil }
            let type = LedgerText.txType(from: cols[1])
            let date = df.date(from: cols[0]) ?? Date()
            if usesIDs {
                guard cols.count >= 4, let accountId = UUID(uuidString: cols[3]) else { return nil }
                let id = cols.count > 8 ? UUID(uuidString: cols[8]) ?? UUID() : UUID()
                return Transaction(
                    id: id,
                    type: type,
                    amount: amount,
                    accountId: accountId,
                    toAccountId: cols.count > 4 ? UUID(uuidString: cols[4]) : nil,
                    categoryId: cols.count > 5 ? UUID(uuidString: cols[5]) : nil,
                    subcategory: cols.count > 6 && !cols[6].isEmpty ? cols[6] : nil,
                    note: cols.count > 7 ? cols[7] : "",
                    date: date
                )
            }
            let accountName = cols.count > 3 ? cols[3] : ""
            let accountId = accounts.first { LedgerText.canonical($0.name) == LedgerText.canonical(accountName) }?.id
                ?? accounts.first { $0.kind == .cash }?.id
            guard let accountId else { return nil }
            let categoryName = cols.count > 4 ? LedgerText.canonical(cols[4]) : ""
            let categoryId = categories.first { LedgerText.canonical($0.name) == categoryName && $0.type == type }?.id
            return Transaction(
                type: type,
                amount: amount,
                accountId: accountId,
                categoryId: type == .transfer ? nil : categoryId,
                note: cols.count > 5 ? cols[5] : "",
                date: date
            )
        }
    }

    private func pipeList(_ raw: String) -> [String] {
        raw.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    private func flag(_ raw: String) -> Bool {
        raw == "true" || raw == "1"
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var quoted = false
        var index = line.startIndex
        while index < line.endIndex {
            let ch = line[index]
            if ch == "\"" {
                let next = line.index(after: index)
                if quoted, next < line.endIndex, line[next] == "\"" {
                    current.append("\"")
                    index = line.index(after: next)
                    continue
                }
                quoted.toggle()
                index = next
                continue
            }
            if ch == "," && !quoted {
                result.append(current)
                current = ""
                index = line.index(after: index)
                continue
            }
            current.append(ch)
            index = line.index(after: index)
        }
        result.append(current)
        return result
    }

    private func csvEscape(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }

    private static func dayFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }
}
