//
//  BudgetEditorView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/18.
//

import SwiftUI

struct BudgetEditorView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let yearMonth: String
    @State private var totalText = ""
    @State private var caps: [UUID: String] = [:]

    private var expenseCategories: [Category] {
        store.categories(for: .expense)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("monthly.month_total"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField(L10n.t("monthly.total_example"), text: $totalText)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.page))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))

                Text(L10n.categoryBudgetOptional)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: 0) {
                    ForEach(expenseCategories) { category in
                        categoryRow(category)
                        if category.id != expenseCategories.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))

                LedgerPrimaryButton(title: L10n.save) {
                    var budget = store.budgets.first(where: { $0.yearMonth == yearMonth }) ?? MonthBudget(yearMonth: yearMonth)
                    budget.total = Double(totalText.replacingOccurrences(of: ",", with: "")) ?? 0
                    var next: [UUID: Double] = [:]
                    for category in expenseCategories {
                        let raw = caps[category.id, default: ""].replacingOccurrences(of: ",", with: "")
                        if let value = Double(raw), value > 0 { next[category.id] = value }
                    }
                    budget.categoryCaps = next
                    store.upsertBudget(budget)
                    dismiss()
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle("\(yearMonth) \(L10n.budget)")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
        .onAppear {
            let existing = store.budgets.first(where: { $0.yearMonth == yearMonth })
            totalText = existing.flatMap { $0.total > 0 ? String(format: "%g", $0.total) : nil } ?? ""
            var loaded: [UUID: String] = [:]
            for (id, value) in existing?.categoryCaps ?? [:] where value > 0 {
                loaded[id] = String(format: "%g", value)
            }
            caps = loaded
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        let visual = CategoryVisual.style(categoryName: category.name, type: category.type)
        return HStack(spacing: 12) {
            LedgerMark(symbol: visual.markName, point: 17, weight: .regular)
                .foregroundStyle(visual.foreground)
                .frame(width: 36, height: 36)
                .background(Circle().fill(visual.background))
            VStack(alignment: .leading, spacing: 6) {
                Text(category.name.ledgerText)
                    .font(.subheadline.weight(.semibold))
                TextField(L10n.t("monthly.cap_empty"), text: binding(for: category.id))
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.page))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: { caps[id, default: ""] },
            set: { caps[id] = $0 }
        )
    }
}
