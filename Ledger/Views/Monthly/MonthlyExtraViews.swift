//
//  MonthlyExtraViews.swift
//  Ledger
//
//  Created by Ketty on 2026/10/28.
//

import SwiftUI

/// Monthly category expense detail
struct MonthlyCategoryDetailView: View {
    @EnvironmentObject private var store: LedgerStore
    let categoryId: UUID
    let yearMonth: String

    private var category: Category? { store.category(id: categoryId) }

    private var rows: [Transaction] {
        store.transactions(in: yearMonth, type: .expense)
            .filter { $0.categoryId == categoryId }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                ForEach(rows) { tx in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.note.isEmpty ? (category?.name.ledgerText ?? L10n.expense) : tx.note.ledgerText)
                                .font(.subheadline.weight(.semibold))
                            Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text(store.symbol(tx.amount))
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .listRowBackground(AppTheme.card)
                }
            } header: {
                Text(String(format: L10n.t("monthly.category_detail_title"), category?.name.ledgerText ?? "", yearMonth))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(category?.name.ledgerText ?? L10n.expense)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}

/// Settings entry for which categories can be reduced
struct CanReduceSettingsView: View {
    @EnvironmentObject private var store: LedgerStore

    private var expenseCats: [Category] {
        store.categories.filter { $0.type == .expense && $0.enabled }
    }

    var body: some View {
        List {
            Section {
                ForEach(expenseCats) { cat in
                    Toggle(isOn: Binding(
                        get: { cat.canReduce },
                        set: { store.setCategoryCanReduce(cat.id, value: $0) }
                    )) {
                        Text(cat.name.ledgerText)
                    }
                    .tint(AppTheme.green)
                    .listRowBackground(AppTheme.card)
                }
            } footer: {
                Text(L10n.t("monthly.reducible_hint"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.t("monthly.set_reducible_cats"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}
