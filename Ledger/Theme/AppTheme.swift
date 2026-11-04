//
//  AppTheme.swift
//  Ledger
//
//  Created by Ketty on 2026/11/01.
//

import SwiftUI

enum AppTheme {
    static let greenDark = Color(red: 0.12, green: 0.28, blue: 0.10)
    static let green = Color(red: 0.25, green: 0.55, blue: 0.28)
    static let greenSoft = Color(red: 0.78, green: 0.92, blue: 0.62)
    static let greenMuted = Color(red: 0.55, green: 0.72, blue: 0.45)
    /// Income amount on the balance card (bright lime, never near-white)
    static let incomeOnCard = Color(red: 0.72, green: 1.0, blue: 0.42)
    /// Monthly card amount when spending exceeds income
    static let shortfallOnCard = Color(red: 0.98, green: 0.67, blue: 0.64)
    /// Income amount green in lists
    static let incomeAmount = Color(red: 0.22, green: 0.58, blue: 0.28)
    static let page = Color(red: 0.96, green: 0.96, blue: 0.95)
    static let card = Color.white
    static let textPrimary = Color(red: 0.12, green: 0.14, blue: 0.13)
    static let textSecondary = Color(red: 0.45, green: 0.48, blue: 0.46)
}
