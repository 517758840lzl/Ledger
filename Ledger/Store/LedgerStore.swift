//
//  LedgerStore.swift
//  Ledger
//
//  Created by Ketty on 2026/10/17.
//

import Foundation
import Combine

@MainActor
final class LedgerStore: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var budgets: [MonthBudget] = []
    @Published var settings: AppSettings = AppSettings()
    /// Bumped on locale change so SwiftUI rebuilds every screen.
    @Published var localeEpoch: Int = 0

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("ledger-data.json")
    }()

    init() {
        if !load() {
            seedDefaults()
            save()
        }
        migrateDefaultLocaleIfNeeded()
        applyLocale(settings.languageCode, currencyCode: settings.currencyCode, currencySymbol: settings.currencySymbol, persist: false)
    }

    /// One-time switch from the old Chinese default to English + USD.
    private func migrateDefaultLocaleIfNeeded() {
        let key = "ledger.migratedDefaultEn"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        settings.languageCode = AppLocaleCatalog.defaultLanguageCode
        settings.currencyCode = AppLocaleCatalog.defaultCurrencyCode
        settings.currencySymbol = AppLocaleCatalog.defaultCurrencySymbol
        UserDefaults.standard.set(true, forKey: key)
        save()
    }

    /// Apply in-app language (+ optional paired currency) and refresh UI immediately.
    func applyLocale(
        _ languageCode: String,
        currencyCode: String? = nil,
        currencySymbol: String? = nil,
        persist: Bool = true
    ) {
        L10n.languageCode = languageCode
        var next = settings
        next.languageCode = languageCode
        if let currencyCode { next.currencyCode = currencyCode }
        if let currencySymbol { next.currencySymbol = currencySymbol }
        settings = next
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        localeEpoch &+= 1
        if persist { save() }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var accounts: [Account]
        var categories: [Category]
        var transactions: [Transaction]
        var budgets: [MonthBudget]
        var settings: AppSettings
    }

    @discardableResult
    func load() -> Bool {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return false }
        accounts = snap.accounts
        categories = snap.categories
        transactions = snap.transactions
        budgets = snap.budgets
        settings = snap.settings
        if relabelBuiltIns() { save() }
        return true
    }

    /// Rewrite labels saved by older builds into stable keys.
    private func relabelBuiltIns() -> Bool {
        var changed = false
        for index in categories.indices {
            let name = LedgerText.canonical(categories[index].name)
            let children = categories[index].children.map(LedgerText.canonical)
            let disabled = categories[index].disabledChildren.map(LedgerText.canonical)
            if name != categories[index].name || children != categories[index].children || disabled != categories[index].disabledChildren {
                categories[index].name = name
                categories[index].children = children
                categories[index].disabledChildren = disabled
                changed = true
            }
        }
        for index in accounts.indices {
            let name = LedgerText.canonical(accounts[index].name)
            if name != accounts[index].name {
                accounts[index].name = name
                changed = true
            }
        }
        for index in transactions.indices {
            let note = LedgerText.canonical(transactions[index].note)
            let sub = transactions[index].subcategory.map(LedgerText.canonical)
            if note != transactions[index].note || sub != transactions[index].subcategory {
                transactions[index].note = note
                transactions[index].subcategory = sub
                changed = true
            }
        }
        return changed
    }

    func save() {
        let snap = Snapshot(accounts: accounts, categories: categories, transactions: transactions, budgets: budgets, settings: settings)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func seedDefaults() {
        let cash = Account(name: LedgerText.cashAccount, kind: .cash, openingBalance: 0)
        accounts = [cash]
        categories = [
            Category(name: "cat.dining", type: .expense, isEssential: true, canReduce: true, children: ["cat.takeout", "cat.dinein", "cat.coffee"]),
            Category(name: "cat.transit", type: .expense, isEssential: true, canReduce: true, children: []),
            Category(name: "cat.shopping", type: .expense, isEssential: false, canReduce: true, children: []),
            Category(name: "cat.housing", type: .expense, isEssential: true, canReduce: false, children: []),
            Category(name: "cat.daily", type: .expense, isEssential: true, canReduce: true, children: []),
            Category(name: "cat.phone", type: .expense, isEssential: true, canReduce: false, children: []),
            Category(name: "cat.fun", type: .expense, isEssential: false, canReduce: true, children: []),
            Category(name: "cat.medical", type: .expense, isEssential: true, canReduce: false, children: []),
            Category(name: "cat.social", type: .expense, isEssential: false, canReduce: true, children: []),
            Category(name: "cat.education", type: .expense, isEssential: true, canReduce: false, children: []),
            Category(name: "cat.other", type: .expense, isEssential: false, canReduce: true, children: []),
            Category(name: "cat.salary", type: .income, children: []),
            Category(name: "cat.bonus", type: .income, children: []),
            Category(name: "cat.side", type: .income, children: []),
            Category(name: "cat.gift", type: .income, children: []),
            Category(name: "cat.other", type: .income, children: [])
        ]
        transactions = []
        budgets = []
        settings = AppSettings()
    }

    // MARK: - Mutations

    func addTransaction(_ tx: Transaction) {
        transactions.insert(tx, at: 0)
        save()
    }

    func updateTransaction(_ tx: Transaction) {
        guard let i = transactions.firstIndex(where: { $0.id == tx.id }) else { return }
        transactions[i] = tx
        save()
    }

    func deleteTransaction(_ id: UUID) {
        transactions.removeAll { $0.id == id }
        save()
    }

    func upsertAccount(_ account: Account) {
        if let i = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[i] = account
        } else {
            accounts.append(account)
        }
        save()
    }

    func upsertCategory(_ category: Category) {
        if let i = categories.firstIndex(where: { $0.id == category.id }) {
            categories[i] = category
        } else {
            categories.append(category)
        }
        save()
    }

    func addSubcategory(to categoryId: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        guard !categories[i].children.contains(trimmed) else { return }
        categories[i].children.append(trimmed)
        categories[i].disabledChildren.removeAll { $0 == trimmed }
        save()
    }

    func addTopCategory(name: String, type: TxType) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !categories.contains(where: { $0.name == trimmed && $0.type == type }) else { return }
        categories.append(Category(name: trimmed, type: type, isEssential: type == .expense, canReduce: type == .expense))
        save()
    }

    func setCategoryEssential(_ id: UUID, value: Bool) {
        guard let i = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[i].isEssential = value
        save()
    }

    func setCategoryCanReduce(_ id: UUID, value: Bool) {
        guard let i = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[i].canReduce = value
        save()
    }

    func setCategoryEnabled(_ id: UUID, value: Bool) {
        guard let i = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[i].enabled = value
        save()
    }

    func setChildEnabled(categoryId: UUID, child: String, enabled: Bool) {
        guard let i = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        if enabled {
            categories[i].disabledChildren.removeAll { $0 == child }
        } else if !categories[i].disabledChildren.contains(child) {
            categories[i].disabledChildren.append(child)
        }
        save()
    }

    func categoriesForSettings(type: TxType) -> [Category] {
        categories.filter { $0.type == type }
    }

    func transactions(forAccount id: UUID) -> [Transaction] {
        transactions.filter { $0.accountId == id || $0.toAccountId == id }
            .sorted { $0.date > $1.date }
    }

    /// Parse app-exported CSV (sectioned or flat transaction table)
    @discardableResult
    func importCSV(text: String) -> Int {
        var added = 0
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard !lines.isEmpty else { return 0 }
        let header = lines[0].lowercased()
        if header.contains("date") && header.contains("amount") {
            for line in lines.dropFirst() {
                let cols = parseCSVLine(line)
                guard cols.count >= 3, let amount = Double(cols[2]) else { continue }
                let typeRaw = cols.count > 1 ? cols[1] : "expense"
                let type = LedgerText.txType(from: typeRaw)
                let note = LedgerText.canonical(cols.count > 5 ? cols[5] : (cols.count > 4 ? cols[4] : ""))
                if transactions.contains(where: { LedgerText.canonical($0.note) == note && $0.amount == amount && note != "" }) { continue }
                let cash = accounts.first(where: { $0.kind == .cash }) ?? accounts.first
                guard let cash else { continue }
                var catId = categories.first(where: { $0.type == type && $0.enabled })?.id
                if cols.count > 4 {
                    let catName = LedgerText.canonical(cols[4])
                    if let found = categories.first(where: { LedgerText.canonical($0.name) == catName && $0.type == type }) {
                        catId = found.id
                    }
                }
                let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]
                let date = df.date(from: cols[0]) ?? Date()
                let tx = Transaction(type: type, amount: amount, accountId: cash.id, categoryId: type == .transfer ? nil : catId, note: note, date: date)
                transactions.append(tx)
                added += 1
            }
            save()
        }
        return added
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" { inQuotes.toggle(); continue }
            if ch == "," && !inQuotes { result.append(current); current = ""; continue }
            current.append(ch)
        }
        result.append(current)
        return result
    }

    func exportFullCSV() -> URL? {
        var lines: [String] = []
        lines.append("# ledger-export v1")
        lines.append("section,accounts")
        lines.append("id,name,kind,opening,enabled,manualOnly,includeInNetWorth")
        for a in accounts {
            lines.append("\(a.id.uuidString),\(csvEscape(a.name)),\(a.kind.rawValue),\(a.openingBalance),\(a.enabled),\(a.manualOnly),\(a.includeInNetWorth)")
        }
        lines.append("section,categories")
        lines.append("id,name,type,essential,canReduce,enabled,children")
        for c in categories {
            lines.append("\(c.id.uuidString),\(csvEscape(c.name)),\(c.type.rawValue),\(c.isEssential),\(c.canReduce),\(c.enabled),\(csvEscape(c.children.joined(separator: "|")))")
        }
        lines.append("section,budgets")
        lines.append("yearMonth,total")
        for b in budgets {
            lines.append("\(b.yearMonth),\(b.total)")
        }
        lines.append("section,transactions")
        lines.append("date,type,amount,account,category,note")
        let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]
        for tx in transactions {
            let acc = account(id: tx.accountId)?.name ?? ""
            let cat = category(id: tx.categoryId)?.name ?? ""
            lines.append("\(df.string(from: tx.date)),\(tx.type.rawValue),\(tx.amount),\(csvEscape(acc)),\(csvEscape(cat)),\(csvEscape(tx.note))")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-export.csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }

    func upsertBudget(_ budget: MonthBudget) {
        if let i = budgets.firstIndex(where: { $0.yearMonth == budget.yearMonth }) {
            budgets[i] = budget
        } else {
            budgets.append(budget)
        }
        save()
    }

    func clearLocalDataKeepingCash() {
        let cash = Account(name: LedgerText.cashAccount, kind: .cash, openingBalance: 0)
        accounts = [cash]
        transactions = []
        budgets = []
        UserDefaults.standard.removeObject(forKey: "ledger.assetsConfigured")
        save()
    }

    func loadSampleBills() {
        guard let cash = accounts.first(where: { $0.kind == .cash }) ?? accounts.first else { return }
        let lunchCat = categories.first(where: { $0.name == LedgerText.dining && $0.type == .expense })
        let shopCat = categories.first(where: { $0.name == LedgerText.shopping && $0.type == .expense })
        let wageCat = categories.first(where: { $0.name == LedgerText.salary && $0.type == .income })
        let lunch = Transaction(type: .expense, amount: 55, accountId: cash.id, categoryId: lunchCat?.id, note: "sample.lunch", date: date(y: 2026, m: 9, d: 3))
        let ear = Transaction(type: .expense, amount: 199, accountId: cash.id, categoryId: shopCat?.id, note: "sample.case", date: date(y: 2026, m: 8, d: 28))
        let todayCoffee = Transaction(type: .expense, amount: 28, accountId: cash.id, categoryId: lunchCat?.id, note: "sample.coffee", date: Date())
        let todayWage = Transaction(type: .income, amount: 3000, accountId: cash.id, categoryId: wageCat?.id, note: "sample.pay", date: Date())
        for tx in [lunch, ear, todayCoffee, todayWage] where !transactions.contains(where: { $0.note == tx.note && $0.amount == tx.amount }) {
            transactions.append(tx)
        }
        save()
    }

    private func date(y: Int, m: Int, d: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = m; c.day = d
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: - Queries

    func symbol(_ amount: Double) -> String {
        let sign = amount < 0 ? "-" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let body = formatter.string(from: NSNumber(value: abs(amount))) ?? String(format: "%.2f", abs(amount))
        return "\(sign)\(settings.currencySymbol)\(body)"
    }

    func yearMonth(for date: Date = Date()) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"; return f.string(from: date)
    }

    func transactions(in yearMonth: String, type: TxType? = nil) -> [Transaction] {
        transactions.filter { tx in
            self.yearMonth(for: tx.date) == yearMonth && (type == nil || tx.type == type)
        }
    }

    func monthExpense(_ ym: String) -> Double {
        transactions(in: ym, type: .expense).reduce(0) { $0 + $1.amount }
    }

    func monthIncome(_ ym: String) -> Double {
        transactions(in: ym, type: .income).reduce(0) { $0 + $1.amount }
    }

    func monthBalance(_ ym: String) -> Double {
        monthIncome(ym) - monthExpense(ym)
    }

    func balance(for account: Account) -> Double {
        if account.manualOnly { return account.openingBalance }
        var value = account.openingBalance
        for tx in transactions {
            switch tx.type {
            case .expense:
                if tx.accountId == account.id { value -= tx.amount }
            case .income:
                if tx.accountId == account.id { value += tx.amount }
            case .transfer:
                if tx.accountId == account.id { value -= tx.amount }
                if tx.toAccountId == account.id { value += tx.amount }
            }
        }
        return value
    }

    var netWorth: Double {
        accounts.filter(\.includeInNetWorth).reduce(0) { sum, acc in
            let b = balance(for: acc)
            // credit card openingBalance is debt when positive
            if acc.kind == .credit { return sum - abs(b) }
            return sum + b
        }
    }

    func account(id: UUID) -> Account? { accounts.first { $0.id == id } }
    func category(id: UUID?) -> Category? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    func enabledAccounts() -> [Account] { accounts.filter(\.enabled) }

    func categories(for type: TxType) -> [Category] {
        categories.filter { $0.type == type && $0.enabled }
    }
}
