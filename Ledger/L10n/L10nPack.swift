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
        case "en": return english
        case "en-AU": return englishAustralia
        case "en-GB": return englishUK
        case "de": return german
        case "fr": return french
        case "fr-CA": return frenchCanada
        case "ja": return japanese
        case "ko": return korean
        case "ms": return malay
        case "zh-Hans": return chineseSimplified
        case "zh-Hant": return chineseTraditional
        case "zh-Hant-TW": return chineseTaiwan
        default: return [:]
        }
    }
}
