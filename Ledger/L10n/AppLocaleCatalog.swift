//
//  AppLocaleCatalog.swift
//  Ledger
//
//  Created by Ketty on 2026/10/14.
//

import Foundation

/// One language entry per supported currency (counts stay in sync).
enum AppLocaleCatalog {
    struct Entry: Identifiable, Hashable {
        var id: String { currencyCode }
        let currencyCode: String
        let symbol: String
        let languageCode: String
        let languageName: String
    }

    static let all: [Entry] = [
        .init(currencyCode: "USD", symbol: "$", languageCode: "en", languageName: "English"),
        .init(currencyCode: "EUR", symbol: "€", languageCode: "de", languageName: "Deutsch"),
        .init(currencyCode: "GBP", symbol: "£", languageCode: "en-GB", languageName: "English (UK)"),
        .init(currencyCode: "JPY", symbol: "¥", languageCode: "ja", languageName: "日本語"),
        .init(currencyCode: "CNY", symbol: "¥", languageCode: "zh-Hans", languageName: "中文（简体）"),
        .init(currencyCode: "HKD", symbol: "HK$", languageCode: "zh-Hant", languageName: "中文（繁體）"),
        .init(currencyCode: "TWD", symbol: "NT$", languageCode: "zh-Hant-TW", languageName: "中文（台灣）"),
        .init(currencyCode: "KRW", symbol: "₩", languageCode: "ko", languageName: "한국어"),
        .init(currencyCode: "SGD", symbol: "S$", languageCode: "ms", languageName: "Bahasa Melayu"),
        .init(currencyCode: "AUD", symbol: "A$", languageCode: "en-AU", languageName: "English (Australia)"),
        .init(currencyCode: "CAD", symbol: "C$", languageCode: "fr-CA", languageName: "Français (Canada)"),
    ]

    static var defaultLanguageCode: String { "en" }
    static var defaultCurrencyCode: String { "USD" }
    static var defaultCurrencySymbol: String { "$" }

    static func entry(currencyCode: String) -> Entry? {
        all.first { $0.currencyCode == currencyCode }
    }

    static func entry(languageCode: String) -> Entry? {
        all.first { $0.languageCode == languageCode }
    }

    static func locale(for languageCode: String) -> Locale {
        Locale(identifier: languageCode.replacingOccurrences(of: "-", with: "_"))
    }
}
