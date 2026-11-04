//
//  L10nPack.swift
//  Ledger
//
//  Created by Ketty on 2026/10/01.
//

import Foundation

/// In-memory copy for the selected language. Views read this during body,
/// the same way a published locale resolves its strings immediately.
enum L10nPack {
    static func text(_ key: String, language: String) -> String {
        let table = map(for: language)
        if let value = table[key] {
            return value
        }
        return key
    }

    private static func map(for language: String) -> [String: String] {
        switch language {
        case "en", "en-AU", "en-GB": return english
        case "de": return german
        case "fr", "fr-CA": return french
        case "ja": return japanese
        case "ko": return korean
        case "ms": return malay
        case "zh-Hans": return chineseSimplified
        case "zh-Hant", "zh-Hant-TW": return chineseTraditional
        default: return [:]
        }
    }
}
