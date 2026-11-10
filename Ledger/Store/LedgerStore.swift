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

    let fileURL: URL
    let defaults: UserDefaults
    let bundleID: String
    let book: LedgerBookDatabase?
    var cloud: LedgerCloudCoordinator?

    init(storageRoot: URL? = nil, defaults: UserDefaults = .standard, bundleID: String? = nil, opensCloud: Bool = true) {
        let root = storageRoot ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = root.appendingPathComponent("ledger-data.json")
        self.defaults = defaults
        self.bundleID = bundleID ?? LedgerCloudIdentity.currentBundleID
        book = LedgerBookDatabase(root: root)
        if let book {
            bootDatabase(book)
        } else if !load() {
            seedDefaults()
            save()
        }
        migrateDefaultLocaleIfNeeded()
        applyLocale(settings.languageCode, currencyCode: settings.currencyCode, currencySymbol: settings.currencySymbol, persist: false)
        if opensCloud, let book {
            cloud = LedgerCloudCoordinator(book: book, bundleID: self.bundleID) { [weak self] in
                self?.reloadBook()
            }
        }
    }

    /// One-time switch from the old Chinese default to English + USD.
    private func migrateDefaultLocaleIfNeeded() {
        let key = "ledger.migratedDefaultEn"
        guard !defaults.bool(forKey: key) else { return }
        settings.languageCode = AppLocaleCatalog.defaultLanguageCode
        settings.currencyCode = AppLocaleCatalog.defaultCurrencyCode
        settings.currencySymbol = AppLocaleCatalog.defaultCurrencySymbol
        defaults.set(true, forKey: key)
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
        defaults.set([languageCode], forKey: "AppleLanguages")
        localeEpoch &+= 1
        if persist { save() }
        ReminderScheduler.resync(settings)
    }

    // MARK: - Persistence

    struct Snapshot: Codable {
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
        return true
    }

    func save() {
        if book != nil {
            persist(markUserEdit: true)
        } else {
            writeLegacyFile()
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

    /// Flow lists: income, then expense, then transfer; older rows first inside a type.
    func listed(_ items: [Transaction]) -> [Transaction] {
        items.sorted { a, b in
            let left = listRank(a.type)
            let right = listRank(b.type)
            if left != right { return left < right }
            return a.date < b.date
        }
    }

    private func listRank(_ type: TxType) -> Int {
        switch type {
        case .income: return 0
        case .expense: return 1
        case .transfer: return 2
        }
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

    /// Spending change against the previous month. Flat only when the amounts match.
    func expenseChangeLabel(for ym: String) -> String {
        guard let prev = previousYearMonth(ym) else { return L10n.t("monthly.flat") }
        let delta = monthExpense(ym) - monthExpense(prev)
        if abs(delta) < 0.005 { return L10n.t("monthly.flat") }
        if delta > 0 { return String(format: L10n.t("monthly.vs_more"), symbol(delta)) }
        return String(format: L10n.t("monthly.vs_less"), symbol(-delta))
    }

    func previousYearMonth(_ ym: String) -> String? {
        let parts = ym.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = Calendar.current.date(from: comps),
              let prev = Calendar.current.date(byAdding: .month, value: -1, to: date) else { return nil }
        return yearMonth(for: prev)
    }

    /// Credit balances stay positive while the cardholder owes money.
    func balance(for account: Account) -> Double {
        if account.manualOnly { return account.openingBalance }
        let owes = account.kind == .credit
        var value = account.openingBalance
        for tx in transactions {
            value += ledgerDelta(tx, accountID: account.id, owes: owes)
        }
        return value
    }

    /// Cash grows with income and money transferred in. Credit debt uses the opposite sign.
    private func ledgerDelta(_ tx: Transaction, accountID: UUID, owes: Bool) -> Double {
        var delta = 0.0
        switch tx.type {
        case .expense:
            if tx.accountId == accountID { delta -= tx.amount }
        case .income:
            if tx.accountId == accountID { delta += tx.amount }
        case .transfer:
            if tx.accountId == accountID { delta -= tx.amount }
            if tx.toAccountId == accountID { delta += tx.amount }
        }
        return owes ? -delta : delta
    }

    var netWorth: Double {
        accounts.filter(\.includeInNetWorth).reduce(0) { sum, acc in
            let b = balance(for: acc)
            if acc.kind == .credit { return sum - b }
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
