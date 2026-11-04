//
//  LedgerText.swift
//  Ledger
//
//  Created by Ketty on 2026/10/29.
//

import Foundation

/// Built-in names are stable keys. Custom names typed by the user stay as written.
enum LedgerText {
    static let cashAccount = "preset.cash"
    static let dining = "cat.dining"
    static let shopping = "cat.shopping"
    static let salary = "cat.salary"

    static func show(_ stored: String) -> String {
        let key = canonical(stored)
        let value = L10n.t(key)
        return value == key ? stored : value
    }

    /// Map an older stored label onto its key. Unknown text is returned unchanged.
    static func canonical(_ stored: String) -> String {
        reverse[stored] ?? stored
    }

    static func preset(for kind: AccountKind) -> String {
        switch kind {
        case .cash: return "preset.cash"
        case .bank: return "preset.cmb"
        case .wechat: return "preset.wechat"
        case .alipay: return "preset.alipay"
        case .stock: return "preset.stock"
        case .fund: return "preset.fund"
        case .credit: return "preset.credit"
        case .other: return "preset.source"
        }
    }

    /// Keep a preset key when the field still shows that preset's current translation.
    static func store(_ typed: String, fallback: String) -> String {
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return fallback }
        if trimmed == show(fallback) { return fallback }
        return canonical(trimmed)
    }

    static func isTranslation(_ typed: String, of key: String) -> Bool {
        let needle = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return packs.contains { $0[key] == needle }
    }

    static func kind(fromLegacy raw: String) -> AccountKind? {
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return kindTokens[token] ?? kindLabels[token]
    }

    static func txType(from raw: String) -> TxType {
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if token.caseInsensitiveCompare("income") == .orderedSame || isTranslation(token, of: "type.income") {
            return .income
        }
        if token.caseInsensitiveCompare("transfer") == .orderedSame || isTranslation(token, of: "type.transfer") {
            return .transfer
        }
        return .expense
    }

    private static let packs: [[String: String]] = [
        L10nPack.english, L10nPack.englishAustralia, L10nPack.englishUK,
        L10nPack.german, L10nPack.french, L10nPack.frenchCanada,
        L10nPack.japanese, L10nPack.korean, L10nPack.malay,
        L10nPack.chineseSimplified, L10nPack.chineseTraditional, L10nPack.chineseTaiwan,
    ]

    private static let namePrefixes = ["cat.", "preset.", "sample."]

    private static let kindTokens: [String: AccountKind] = [
        "cash": .cash, "bank": .bank, "credit": .credit, "wechat": .wechat,
        "alipay": .alipay, "stock": .stock, "fund": .fund, "other": .other,
    ]

    /// Stored English token stays. Display names come from `kind.*` in the packs.
    private static let kindLabels: [String: AccountKind] = {
        let pairs: [(String, AccountKind)] = [
            ("kind.cash", .cash), ("kind.bank", .bank), ("kind.credit", .credit),
            ("kind.wechat", .wechat), ("kind.alipay", .alipay), ("kind.stock", .stock),
            ("kind.fund", .fund), ("kind.other", .other),
        ]
        var map: [String: AccountKind] = [:]
        for table in packs {
            for (key, kind) in pairs {
                if let value = table[key] { map[value] = kind }
            }
        }
        return map
    }()

    /// Display string from any pack -> key, when that string belongs to a single key.
    private static let reverse: [String: String] = {
        var hits: [String: Set<String>] = [:]
        let keys = Set(packs.flatMap { table in
            table.keys.filter { key in namePrefixes.contains { key.hasPrefix($0) } }
        })
        for table in packs {
            for key in keys {
                if let value = table[key] {
                    hits[value, default: []].insert(key)
                }
            }
        }
        var unique: [String: String] = [:]
        for (value, keys) in hits where keys.count == 1 {
            unique[value] = keys.first
        }
        return unique
    }()
}

extension String {
    var ledgerText: String { LedgerText.show(self) }
}
