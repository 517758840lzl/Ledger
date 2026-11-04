//
//  MonthlyCharts.swift
//  Ledger
//
//  Created by Ketty on 2026/10/11.
//

import SwiftUI

/// Monthly expense-share donut + legend
struct MonthlySpendDonut: View {
    let items: [(name: String, amount: Double, color: Color)]
    let total: Double
    let totalLabel: String
    let totalText: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.06), lineWidth: 28)
                    .frame(width: 140, height: 140)
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    Circle()
                        .trim(from: seg.start, to: seg.end)
                        .stroke(seg.color, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                }
                VStack(spacing: 4) {
                    Text(totalLabel)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(totalText)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .frame(width: 148, height: 148)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.prefix(5).enumerated()), id: \.offset) { _, item in
                    let pct = total > 0 ? Int((item.amount / total) * 100) : 0
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(pct)%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var segments: [(start: CGFloat, end: CGFloat, color: Color)] {
        guard total > 0 else { return [] }
        var cursor: CGFloat = 0
        var out: [(CGFloat, CGFloat, Color)] = []
        for item in items {
            let span = CGFloat(item.amount / total)
            out.append((cursor, cursor + span, item.color))
            cursor += span
        }
        return out
    }
}

enum MonthlyPalette {
    static let colors: [Color] = [
        Color(red: 0.95, green: 0.55, blue: 0.25),
        Color(red: 0.35, green: 0.65, blue: 0.90),
        Color(red: 0.55, green: 0.45, blue: 0.85),
        Color(red: 0.30, green: 0.70, blue: 0.55),
        Color(red: 0.90, green: 0.40, blue: 0.50),
        Color(red: 0.70, green: 0.55, blue: 0.30)
    ]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }
}
