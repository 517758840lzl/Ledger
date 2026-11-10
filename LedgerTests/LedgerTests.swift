//
//  LedgerTests.swift
//  LedgerTests
//
//  Created by Flynn on 2026/11/3.
//

import CloudKit
import XCTest
@testable import Ledger

@MainActor
final class LedgerTests: XCTestCase {
    private var root: URL!
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        suite = "ledger.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    func testCloudNamesFollowTheAppID() {
        XCTAssertEqual(LedgerCloudIdentity.containerID(bundleID: "com.example.ledger"), "iCloud.com.example.ledger")
        XCTAssertEqual(LedgerCloudIdentity.zoneName(bundleID: "com.example.ledger"), "com.example.ledger")
        XCTAssertEqual(LedgerCloudIdentity.localKey("settings", bundleID: "com.example.ledger"), "com.example.ledger.settings")
        XCTAssertNotEqual(
            LedgerCloudIdentity.containerID(bundleID: "com.example.other"),
            LedgerCloudIdentity.containerID(bundleID: "com.example.ledger")
        )
        XCTAssertFalse(LedgerCloudIdentity.containerID(bundleID: "com.example.ledger").contains("luozhilin"))
    }

    func testLegacyFileBecomesTheDatabaseAndSurvivesRelaunch() throws {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let account = Account(name: "Cash", kind: .cash, openingBalance: 20)
        let category = Category(name: "cat.dining", type: .expense, isEssential: true, canReduce: true, children: ["cat.coffee"])
        let bill = Transaction(type: .expense, amount: 18, accountId: account.id, categoryId: category.id, note: "lunch", date: Date(timeIntervalSince1970: 1_700_000_000))
        var budget = MonthBudget(yearMonth: "2026-11", total: 300)
        budget.categoryCaps[category.id] = 40
        var settings = AppSettings()
        settings.languageCode = "de"
        settings.currencyCode = "EUR"
        settings.currencySymbol = "€"
        settings.hasSeenOnboarding = true
        settings.savingsGoal = 80
        let file = LegacyBox(accounts: [account], categories: [category], transactions: [bill], budgets: [budget], settings: settings)
        let data = try JSONEncoder().encode(file)
        try data.write(to: root.appendingPathComponent("ledger-data.json"))

        let store = makeStore(bundleID: "com.example.ledger")
        XCTAssertEqual(store.accounts.map(\.id), [account.id])
        XCTAssertEqual(store.transactions.map(\.id), [bill.id])
        XCTAssertEqual(store.budgets.first?.categoryCaps[category.id], 40)
        XCTAssertEqual(store.settings.languageCode, "de")
        XCTAssertEqual(store.settings.savingsGoal, 80)
        XCTAssertEqual(store.balance(for: account), 2)
        try FileManager.default.removeItem(at: root.appendingPathComponent("ledger-data.json"))

        let again = makeStore(bundleID: "com.example.ledger")
        XCTAssertEqual(again.transactions.map(\.id), [bill.id])
        XCTAssertEqual(again.categories.first?.children, ["cat.coffee"])
        XCTAssertEqual(again.settings.currencyCode, "EUR")
        XCTAssertEqual(again.settings.savingsGoal, 80)
        XCTAssertEqual(again.balance(for: account), 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("ledger.sqlite").path))
    }

    func testBookEditsKeepBalanceClearAndLocalSettings() {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let store = makeStore(bundleID: "com.example.one")
        let cash = store.accounts[0]
        let bank = Account(name: "Bank", kind: .bank, openingBalance: 0)
        store.upsertAccount(bank)
        store.addTransaction(Transaction(type: .expense, amount: 40, accountId: cash.id, note: "fare"))
        store.addTransaction(Transaction(type: .transfer, amount: 15, accountId: cash.id, toAccountId: bank.id))
        store.applyLocale("fr", currencyCode: "EUR", currencySymbol: "€")
        store.settings.savingsGoal = 500
        store.save()
        if let dining = store.categories.first(where: { $0.name == "cat.dining" }) {
            store.addSubcategory(to: dining.id, name: "tea")
        }

        XCTAssertEqual(store.balance(for: cash), -55)
        XCTAssertEqual(store.balance(for: bank), 15)
        let keptCategories = store.categories.count
        store.clearLocalDataKeepingCash()
        XCTAssertEqual(store.accounts.count, 1)
        XCTAssertEqual(store.accounts[0].kind, .cash)
        XCTAssertTrue(store.transactions.isEmpty)
        XCTAssertTrue(store.budgets.isEmpty)
        XCTAssertEqual(store.categories.count, keptCategories)

        let again = makeStore(bundleID: "com.example.one")
        XCTAssertEqual(again.accounts.count, 1)
        XCTAssertTrue(again.transactions.isEmpty)
        XCTAssertEqual(again.settings.languageCode, "fr")
        XCTAssertEqual(again.settings.savingsGoal, 500)
        XCTAssertTrue(again.categories.contains { $0.children.contains("tea") })
        let storedKey = LedgerCloudIdentity.localKey("settings", bundleID: "com.example.one")
        XCTAssertNotNil(defaults.data(forKey: storedKey))
    }

    func testListOrderStaysIncomeThenExpenseThenTransfer() {
        let store = makeStore(bundleID: "com.example.list")
        let cash = store.accounts[0].id
        let older = Date(timeIntervalSince1970: 10)
        let newer = Date(timeIntervalSince1970: 20)
        let rows = [
            Transaction(type: .transfer, amount: 1, accountId: cash, date: older),
            Transaction(type: .expense, amount: 1, accountId: cash, date: newer),
            Transaction(type: .income, amount: 1, accountId: cash, date: newer),
            Transaction(type: .expense, amount: 1, accountId: cash, date: older)
        ]
        let listed = store.listed(rows)
        XCTAssertEqual(listed.map(\.type), [.income, .expense, .expense, .transfer])
        XCTAssertEqual(listed[1].date, older)
        XCTAssertEqual(listed[2].date, newer)
    }

    func testNewerLocalRowWinsAndNewerRemoteRowReplacesIt() throws {
        let database = try XCTUnwrap(LedgerBookDatabase(root: root))
        let id = UUID()
        var account = Account(id: id, name: "Cash", kind: .cash, openingBalance: 10)
        XCTAssertTrue(database.store(accounts: [account], categories: [], transactions: [], budgets: [], savingsGoal: 0))
        account.openingBalance = 50
        XCTAssertTrue(database.store(accounts: [account], categories: [], transactions: [], budgets: [], savingsGoal: 0))

        var older = account
        older.openingBalance = 1
        var stale = LedgerCloudPayload()
        stale.accounts = [LedgerTimedAccount(account: older, position: 0, updatedAt: 1)]
        XCTAssertFalse(database.merge(stale))
        XCTAssertEqual(database.loadBook().accounts[0].openingBalance, 50)

        var newer = account
        newer.name = "Wallet"
        newer.openingBalance = 80
        var fresh = LedgerCloudPayload()
        fresh.accounts = [LedgerTimedAccount(account: newer, position: 0, updatedAt: Date().timeIntervalSince1970 + 120)]
        XCTAssertTrue(database.merge(fresh))
        XCTAssertEqual(database.loadBook().accounts[0].name, "Wallet")
        XCTAssertEqual(database.loadBook().accounts[0].openingBalance, 80)
    }

    func testCloudMirrorStaysClosedWhenTheContainerIsNotDeclared() {
        XCTAssertFalse(LedgerCloudIdentity.declaresContainer(bundleID: "com.example.ledger"))
        XCTAssertNil(LedgerCloudMirror(bundleID: "com.example.ledger"))
    }

    func testContainerListIsReadFromTheSignedExecutable() {
        let xml = Data("""
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict>
        <key>com.apple.developer.icloud-container-identifiers</key>
        <array><string>iCloud.com.example.ledger</string></array>
        </dict></plist>
        """.utf8)
        let signed = signedExecutable(entitlements: xml)
        XCTAssertEqual(
            LedgerCloudIdentity.containerIdentifiers(inExecutable: signed),
            ["iCloud.com.example.ledger"]
        )
        XCTAssertTrue(LedgerCloudIdentity.containerIdentifiers(inExecutable: Data([0, 1, 2, 3])).isEmpty)
    }

    func testCloudRecordRoundTrip() {
        let id = UUID()
        let account = Account(id: id, name: "Cash", kind: .cash, openingBalance: 12.5, enabled: true, manualOnly: true, includeInNetWorth: false)
        let category = Category(name: "cat.dining", type: .expense, children: ["tea"], disabledChildren: ["old"])
        let bill = Transaction(type: .transfer, amount: 9, accountId: id, toAccountId: UUID(), categoryId: category.id, subcategory: "tea", note: "move", date: Date(timeIntervalSince1970: 1_700_000_000))
        var budget = MonthBudget(yearMonth: "2026-11", total: 20)
        budget.categoryCaps[category.id] = 5
        var payload = LedgerCloudPayload()
        payload.accounts = [LedgerTimedAccount(account: account, position: 1, updatedAt: 11)]
        payload.categories = [LedgerTimedCategory(category: category, position: 2, updatedAt: 12)]
        payload.entries = [LedgerTimedEntry(transaction: bill, position: 3, updatedAt: 13)]
        payload.budgets = [LedgerTimedBudget(budget: budget, updatedAt: 14)]
        payload.savingsGoal = 70
        payload.goalUpdatedAt = 15
        payload.hasGoal = true
        let zoneID = CKRecordZone.ID(zoneName: "com.example.ledger", ownerName: CKCurrentUserDefaultName)
        let records = LedgerCloudMirror.records(from: payload, zoneID: zoneID)
        var decoded = LedgerCloudPayload()
        records.forEach { LedgerCloudMirror.absorb($0, into: &decoded) }
        XCTAssertEqual(decoded.accounts.first?.account, account)
        XCTAssertEqual(decoded.accounts.first?.position, 1)
        XCTAssertEqual(decoded.categories.first?.category.children, ["tea"])
        XCTAssertEqual(decoded.categories.first?.category.disabledChildren, ["old"])
        XCTAssertEqual(decoded.entries.first?.transaction, bill)
        XCTAssertEqual(decoded.budgets.first?.budget.categoryCaps[category.id], 5)
        XCTAssertEqual(decoded.savingsGoal, 70)
        XCTAssertEqual(records.first?.recordID.zoneID.zoneName, "com.example.ledger")
    }

    func testCreditSpendRaisesDebtAndPaymentLowersIt() {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let store = makeStore(bundleID: "com.example.card")
        let cash = store.accounts[0]
        let card = Account(name: "Card", kind: .credit, openingBalance: 5000)
        store.upsertAccount(card)
        store.addTransaction(Transaction(type: .expense, amount: 100, accountId: card.id))
        XCTAssertEqual(store.balance(for: card), 5100)
        XCTAssertEqual(store.netWorth, -5100)
        store.addTransaction(Transaction(type: .transfer, amount: 100, accountId: cash.id, toAccountId: card.id))
        XCTAssertEqual(store.balance(for: cash), -100)
        XCTAssertEqual(store.balance(for: card), 5000)
        XCTAssertEqual(store.netWorth, -5100)
    }

    func testExportRestoresAccountsBudgetsAndTransfers() throws {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let store = makeStore(bundleID: "com.example.export")
        let cash = store.accounts[0]
        let card = Account(name: "Card", kind: .credit, openingBalance: 40)
        store.upsertAccount(card)
        let dining = try XCTUnwrap(store.categories.first { $0.name == "cat.dining" })
        let payment = Transaction(type: .transfer, amount: 15, accountId: cash.id, toAccountId: card.id, note: "pay, \"card\"")
        let lunch = Transaction(type: .expense, amount: 9, accountId: card.id, categoryId: dining.id, subcategory: "tea", note: "lunch")
        store.addTransaction(payment)
        store.addTransaction(lunch)
        var budget = MonthBudget(yearMonth: "2026-11", total: 200)
        budget.categoryCaps[dining.id] = 30
        store.upsertBudget(budget)
        store.settings.savingsGoal = 80
        store.save()

        let url = try XCTUnwrap(store.exportFullCSV())
        let text = try String(contentsOf: url, encoding: .utf8)
        store.clearLocalDataKeepingCash()
        XCTAssertEqual(store.importCSV(text: text), 2)
        let restoredCard = try XCTUnwrap(store.accounts.first { $0.id == card.id })
        XCTAssertEqual(store.balance(for: restoredCard), 34)
        XCTAssertEqual(store.transactions.map(\.id).sorted { $0.uuidString < $1.uuidString }, [payment.id, lunch.id].sorted { $0.uuidString < $1.uuidString })
        XCTAssertEqual(store.transactions.first { $0.id == payment.id }?.note, "pay, \"card\"")
        XCTAssertEqual(store.transactions.first { $0.id == lunch.id }?.subcategory, "tea")
        XCTAssertEqual(store.budgets.first { $0.id == budget.id }?.categoryCaps[dining.id], 30)
        XCTAssertEqual(store.settings.savingsGoal, 80)
        XCTAssertEqual(store.categories.first { $0.id == dining.id }?.children, dining.children)
    }

    func testFlatCSVAppendsWithoutReplacingAccounts() {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let store = makeStore(bundleID: "com.example.flat")
        let before = store.accounts.count
        let csv = "date,type,amount,account,category,note\n2026-11-01,expense,12,Cash,cat.dining,soup\n"
        XCTAssertEqual(store.importCSV(text: csv), 1)
        XCTAssertEqual(store.accounts.count, before)
        XCTAssertEqual(store.transactions.count, 1)
        XCTAssertEqual(store.transactions[0].note, "soup")
    }

    func testExpenseChangeLabelUsesTheAmount() {
        defaults.set(true, forKey: "ledger.migratedDefaultEn")
        let store = makeStore(bundleID: "com.example.delta")
        let cash = store.accounts[0].id
        let thisMonth = store.yearMonth()
        let previous = store.previousYearMonth(thisMonth) ?? "2026-10"
        store.addTransaction(Transaction(type: .expense, amount: 20, accountId: cash, date: monthDate(previous)))
        store.addTransaction(Transaction(type: .expense, amount: 50, accountId: cash, date: monthDate(thisMonth)))
        XCTAssertEqual(
            store.expenseChangeLabel(for: thisMonth),
            String(format: L10n.t("monthly.vs_more"), store.symbol(30))
        )
    }

    private func monthDate(_ ym: String) -> Date {
        let parts = ym.split(separator: "-")
        var comps = DateComponents()
        comps.year = Int(parts[0])
        comps.month = Int(parts[1])
        comps.day = 15
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func makeStore(bundleID: String) -> LedgerStore {
        LedgerStore(storageRoot: root, defaults: defaults, bundleID: bundleID, opensCloud: false)
    }
}

private func signedExecutable(entitlements xml: Data) -> Data {
    func be(_ value: UInt32, into data: inout Data) {
        data.append(UInt8((value >> 24) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8(value & 0xff))
    }
    func le(_ value: UInt32, into data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 24) & 0xff))
    }
    var signature = Data()
    let entitlementsLength = UInt32(8 + xml.count)
    let signatureLength = UInt32(20) + entitlementsLength
    be(0xFADE0CC0, into: &signature)
    be(signatureLength, into: &signature)
    be(1, into: &signature)
    be(5, into: &signature)
    be(20, into: &signature)
    be(0xFADE7171, into: &signature)
    be(entitlementsLength, into: &signature)
    signature.append(xml)

    var executable = Data()
    le(0xFEEDFACF, into: &executable)
    le(0x0100000C, into: &executable)
    le(0, into: &executable)
    le(2, into: &executable)
    le(1, into: &executable)
    le(16, into: &executable)
    le(0, into: &executable)
    le(0, into: &executable)
    le(0x1D, into: &executable)
    le(16, into: &executable)
    le(48, into: &executable)
    le(UInt32(signature.count), into: &executable)
    executable.append(signature)
    return executable
}

private struct LegacyBox: Codable {
    var accounts: [Ledger.Account]
    var categories: [Ledger.Category]
    var transactions: [Ledger.Transaction]
    var budgets: [Ledger.MonthBudget]
    var settings: Ledger.AppSettings
}
