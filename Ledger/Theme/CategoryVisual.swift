//
//  CategoryVisual.swift
//  Ledger
//
//  Created by Ketty on 2026/10/21.
//

import SwiftUI

/// Colored circle icons for flow rows
enum CategoryVisual {
    struct Style {
        let markName: String
        let foreground: Color
        let background: Color
    }

    static func style(categoryName: String?, type: TxType) -> Style {
        let key = LedgerText.canonical(categoryName ?? "")
        switch type {
        case .income:
            return incomeStyle(key)
        case .transfer:
            return Style(
                markName: "MarkSwap",
                foreground: Color(red: 0.20, green: 0.45, blue: 0.85),
                background: Color(red: 0.86, green: 0.91, blue: 1.0)
            )
        case .expense:
            return expenseStyle(key)
        }
    }

    private static func incomeStyle(_ key: String) -> Style {
        let greenBg = Color(red: 0.82, green: 0.93, blue: 0.78)
        switch key {
        case "cat.salary":
            return Style(markName: "MarkCash", foreground: AppTheme.greenDark, background: greenBg)
        case "cat.bonus":
            return Style(markName: "MarkGift", foreground: AppTheme.greenDark, background: greenBg)
        case "cat.gift":
            return Style(markName: "MarkEnvelope", foreground: Color(red: 0.75, green: 0.18, blue: 0.18), background: Color(red: 1, green: 0.88, blue: 0.88))
        default:
            return Style(markName: "MarkPlusCircle", foreground: AppTheme.greenDark, background: greenBg)
        }
    }

    private static func expenseStyle(_ key: String) -> Style {
        switch key {
        case "cat.takeout":
            return Style(markName: "MarkTakeout", foreground: Color(red: 0.85, green: 0.35, blue: 0.15), background: Color(red: 1.0, green: 0.90, blue: 0.82))
        case "cat.dining", "cat.dinein", "cat.coffee":
            return Style(markName: "MarkDining", foreground: Color(red: 0.85, green: 0.35, blue: 0.15), background: Color(red: 1.0, green: 0.90, blue: 0.82))
        case "cat.transit":
            return Style(markName: "MarkTransit", foreground: Color(red: 0.20, green: 0.45, blue: 0.85), background: Color(red: 0.86, green: 0.91, blue: 1.0))
        case "cat.shopping":
            return Style(markName: "MarkBag", foreground: Color(red: 0.55, green: 0.30, blue: 0.75), background: Color(red: 0.93, green: 0.88, blue: 0.98))
        case "cat.housing":
            return Style(markName: "MarkHouse", foreground: Color(red: 0.35, green: 0.50, blue: 0.70), background: Color(red: 0.88, green: 0.92, blue: 0.96))
        case "cat.daily":
            return Style(markName: "MarkBasket", foreground: Color(red: 0.45, green: 0.55, blue: 0.25), background: Color(red: 0.92, green: 0.95, blue: 0.85))
        case "cat.phone":
            return Style(markName: "MarkPhone", foreground: Color(red: 0.15, green: 0.55, blue: 0.65), background: Color(red: 0.85, green: 0.94, blue: 0.96))
        case "cat.fun":
            return Style(markName: "MarkPlay", foreground: Color(red: 0.75, green: 0.25, blue: 0.45), background: Color(red: 0.98, green: 0.88, blue: 0.92))
        case "cat.medical":
            return Style(markName: "MarkCross", foreground: Color(red: 0.80, green: 0.20, blue: 0.25), background: Color(red: 1.0, green: 0.88, blue: 0.88))
        case "cat.education":
            return Style(markName: "MarkBook", foreground: Color(red: 0.25, green: 0.40, blue: 0.70), background: Color(red: 0.88, green: 0.91, blue: 0.98))
        case "cat.social":
            return Style(markName: "MarkPeople", foreground: Color(red: 0.55, green: 0.35, blue: 0.20), background: Color(red: 0.96, green: 0.91, blue: 0.85))
        default:
            return Style(markName: "MarkTag", foreground: AppTheme.textSecondary, background: Color(red: 0.92, green: 0.92, blue: 0.91))
        }
    }
}
