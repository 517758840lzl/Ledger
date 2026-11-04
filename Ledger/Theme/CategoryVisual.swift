import SwiftUI

/// 对标 Android 流水左侧彩色圆标
enum CategoryVisual {
    struct Style {
        let systemImage: String
        let foreground: Color
        let background: Color
    }

    static func style(categoryName: String?, type: TxType) -> Style {
        let name = categoryName ?? ""
        switch type {
        case .income:
            return incomeStyle(name)
        case .transfer:
            return Style(
                systemImage: "arrow.left.arrow.right",
                foreground: AppTheme.greenDark,
                background: AppTheme.greenSoft
            )
        case .expense:
            return expenseStyle(name)
        }
    }

    private static func incomeStyle(_ name: String) -> Style {
        let greenBg = Color(red: 0.82, green: 0.93, blue: 0.78)
        if name.contains("工资") || name.localizedCaseInsensitiveContains("salary") {
            return Style(systemImage: "banknote.fill", foreground: AppTheme.greenDark, background: greenBg)
        }
        if name.contains("奖金") || name.localizedCaseInsensitiveContains("bonus") {
            return Style(systemImage: "gift.fill", foreground: AppTheme.greenDark, background: greenBg)
        }
        if name.contains("红包") {
            return Style(systemImage: "envelope.fill", foreground: Color(red: 0.75, green: 0.18, blue: 0.18), background: Color(red: 1, green: 0.88, blue: 0.88))
        }
        return Style(systemImage: "plus.circle.fill", foreground: AppTheme.greenDark, background: greenBg)
    }

    private static func expenseStyle(_ name: String) -> Style {
        if name.contains("外卖") || name.localizedCaseInsensitiveContains("delivery") {
            return Style(
                systemImage: "box.truck.fill",
                foreground: Color(red: 0.85, green: 0.35, blue: 0.15),
                background: Color(red: 1.0, green: 0.90, blue: 0.82)
            )
        }
        if name.contains("餐饮") || name.contains("堂食") || name.contains("咖啡")
            || name.localizedCaseInsensitiveContains("food") {
            return Style(
                systemImage: "fork.knife",
                foreground: Color(red: 0.85, green: 0.35, blue: 0.15),
                background: Color(red: 1.0, green: 0.90, blue: 0.82)
            )
        }
        if name.contains("交通") || name.localizedCaseInsensitiveContains("transport") {
            return Style(
                systemImage: "bus.fill",
                foreground: Color(red: 0.20, green: 0.45, blue: 0.85),
                background: Color(red: 0.86, green: 0.91, blue: 1.0)
            )
        }
        if name.contains("购物") || name.localizedCaseInsensitiveContains("shop") {
            return Style(
                systemImage: "bag.fill",
                foreground: Color(red: 0.55, green: 0.30, blue: 0.75),
                background: Color(red: 0.93, green: 0.88, blue: 0.98)
            )
        }
        if name.contains("居住") || name.contains("房租") {
            return Style(
                systemImage: "house.fill",
                foreground: Color(red: 0.35, green: 0.50, blue: 0.70),
                background: Color(red: 0.88, green: 0.92, blue: 0.96)
            )
        }
        if name.contains("日用") {
            return Style(
                systemImage: "basket.fill",
                foreground: Color(red: 0.45, green: 0.55, blue: 0.25),
                background: Color(red: 0.92, green: 0.95, blue: 0.85)
            )
        }
        if name.contains("通讯") {
            return Style(
                systemImage: "phone.fill",
                foreground: Color(red: 0.15, green: 0.55, blue: 0.65),
                background: Color(red: 0.85, green: 0.94, blue: 0.96)
            )
        }
        if name.contains("娱乐") {
            return Style(
                systemImage: "gamecontroller.fill",
                foreground: Color(red: 0.75, green: 0.25, blue: 0.45),
                background: Color(red: 0.98, green: 0.88, blue: 0.92)
            )
        }
        if name.contains("医疗") {
            return Style(
                systemImage: "cross.case.fill",
                foreground: Color(red: 0.80, green: 0.20, blue: 0.25),
                background: Color(red: 1.0, green: 0.88, blue: 0.88)
            )
        }
        if name.contains("教育") {
            return Style(
                systemImage: "book.fill",
                foreground: Color(red: 0.25, green: 0.40, blue: 0.70),
                background: Color(red: 0.88, green: 0.91, blue: 0.98)
            )
        }
        if name.contains("社交") {
            return Style(
                systemImage: "person.2.fill",
                foreground: Color(red: 0.55, green: 0.35, blue: 0.20),
                background: Color(red: 0.96, green: 0.91, blue: 0.85)
            )
        }
        return Style(
            systemImage: "tag.fill",
            foreground: AppTheme.textSecondary,
            background: Color(red: 0.92, green: 0.92, blue: 0.91)
        )
    }
}
