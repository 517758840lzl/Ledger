//
//  LedgerStore+Book.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation

extension LedgerStore {
    func bootDatabase(_ book: LedgerBookDatabase) {
        if book.containsBook {
            loadLocalSettings()
            reloadBook()
        } else if load() {
            book.setOrigin("legacy")
            persist(markUserEdit: false)
        } else {
            seedDefaults()
            book.setOrigin("seed")
            persist(markUserEdit: false)
        }
    }

    func persist(markUserEdit: Bool) {
        guard let book else {
            writeLegacyFile()
            return
        }
        let changed = book.store(
            accounts: accounts,
            categories: categories,
            transactions: transactions,
            budgets: budgets,
            savingsGoal: settings.savingsGoal
        )
        writeLocalSettings()
        if changed && markUserEdit {
            if book.origin == "seed" { book.setOrigin("user") }
            cloud?.requestSync()
        }
    }

    func writeLegacyFile() {
        let snap = Snapshot(accounts: accounts, categories: categories, transactions: transactions, budgets: budgets, settings: settings)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func loadLocalSettings() {
        guard let data = defaults.data(forKey: settingsKey()),
              let stored = try? JSONDecoder().decode(AppSettings.self, from: data) else { return }
        settings = stored
    }

    func reloadBook() {
        guard let book else { return }
        let loaded = book.loadBook()
        accounts = loaded.accounts
        categories = loaded.categories
        transactions = loaded.transactions
        budgets = loaded.budgets
        settings.savingsGoal = loaded.savingsGoal
    }

    private func settingsKey() -> String {
        LedgerCloudIdentity.localKey("settings", bundleID: bundleID)
    }

    private func writeLocalSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey())
        }
    }
}
