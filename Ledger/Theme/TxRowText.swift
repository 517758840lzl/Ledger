//
//  TxRowText.swift
//  Ledger
//
//  Created by Ketty on 2026/10/06.
//

import Foundation

/// Flow row title/subtitle copy aligned with Android
enum TxRowText {
    static func title(tx: Transaction, store: LedgerStore) -> String {
        if tx.type == .transfer {
            let from = store.account(id: tx.accountId)?.name.ledgerText ?? ""
            let to = store.account(id: tx.toAccountId ?? UUID())?.name.ledgerText ?? ""
            return "\(from) → \(to)"
        }
        if let sub = tx.subcategory, !sub.isEmpty { return sub.ledgerText }
        if let cat = store.category(id: tx.categoryId)?.name { return cat.ledgerText }
        return tx.type.localizedName
    }

    static func subtitle(tx: Transaction, store: LedgerStore) -> String {
        if tx.type == .transfer {
            return "\(L10n.transfer) · \(shortDate(tx.date))"
        }
        let acc = store.account(id: tx.accountId)?.name.ledgerText ?? ""
        if tx.note.isEmpty { return "\(acc) · \(L10n.t("flow.no_note"))" }
        return "\(acc) · \(tx.note.ledgerText)"
    }

    private static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MM/dd"
        return f.string(from: date)
    }
}
