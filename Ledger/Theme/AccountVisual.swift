//
//  AccountVisual.swift
//  Ledger
//
//  Created by Ketty on 2026/10/19.
//

import SwiftUI

/// Tinted leading icons for asset sources
enum AccountVisual {
    struct Style {
        let systemImage: String
        let foreground: Color
        let background: Color
    }

    static func style(for kind: AccountKind) -> Style {
        switch kind {
        case .cash:
            return Style(
                systemImage: "wallet.pass.fill",
                foreground: Color(red: 0.25, green: 0.55, blue: 0.28),
                background: Color(red: 0.78, green: 0.92, blue: 0.62)
            )
        case .bank:
            return Style(
                systemImage: "building.columns.fill",
                foreground: Color(red: 0.20, green: 0.40, blue: 0.85),
                background: Color(red: 0.82, green: 0.88, blue: 0.98)
            )
        case .credit:
            return Style(
                systemImage: "creditcard.fill",
                foreground: Color(red: 0.75, green: 0.25, blue: 0.30),
                background: Color(red: 0.98, green: 0.86, blue: 0.86)
            )
        case .wechat:
            return Style(
                systemImage: "message.fill",
                foreground: Color(red: 0.15, green: 0.65, blue: 0.30),
                background: Color(red: 0.82, green: 0.94, blue: 0.84)
            )
        case .alipay:
            return Style(
                systemImage: "yensign.circle.fill",
                foreground: Color(red: 0.15, green: 0.45, blue: 0.90),
                background: Color(red: 0.82, green: 0.90, blue: 0.98)
            )
        case .stock, .fund:
            return Style(
                systemImage: "chart.line.uptrend.xyaxis",
                foreground: Color(red: 0.75, green: 0.45, blue: 0.15),
                background: Color(red: 0.98, green: 0.92, blue: 0.82)
            )
        case .other:
            return Style(
                systemImage: "tray.full.fill",
                foreground: Color(red: 0.40, green: 0.45, blue: 0.55),
                background: Color(red: 0.90, green: 0.91, blue: 0.94)
            )
        }
    }
}
