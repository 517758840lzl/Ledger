//
//  HistoryBillsView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/28.
//

import SwiftUI

struct HistoryBillsView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    private var months: [String] {
        let set = Set(store.transactions.map { store.yearMonth(for: $0.date) })
        return set.sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.t("flow.history_hint"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                if months.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.green)
                        Text(L10n.t("flow.history_empty"))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    ForEach(months, id: \.self) { ym in
                        LedgerTxnCell(
                            title: ym,
                            subtitle: "\(L10n.t("flow.income_short")) \(store.symbol(store.monthIncome(ym))) · \(L10n.t("flow.expense_short")) \(store.symbol(store.monthExpense(ym)))",
                            amount: store.symbol(store.monthBalance(ym)),
                            amountColor: AppTheme.greenDark,
                            showsChevron: true
                        ) {
                            router.flowPath.append(FlowRoute.month(ym))
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.historyBills)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthTransactionsView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    let yearMonth: String

    private var rows: [Transaction] {
        store.transactions(in: yearMonth).sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LedgerTxnDayCard {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, tx in
                    let cat = store.category(id: tx.categoryId)?.name
                    let visual = CategoryVisual.style(categoryName: cat, type: tx.type)
                    let title = TxRowText.title(tx: tx, store: store)
                    LedgerTxnCell(
                        title: title,
                        subtitle: TxRowText.subtitle(tx: tx, store: store),
                        amount: {
                            let sign = tx.type == .expense ? "-" : (tx.type == .income ? "+" : "")
                            return "\(sign)\(store.symbol(tx.amount))"
                        }(),
                        amountColor: tx.type == .income ? AppTheme.incomeAmount : AppTheme.textPrimary,
                        iconSystemImage: visual.systemImage,
                        iconForeground: visual.foreground,
                        iconBackground: visual.background,
                        embedded: true
                    ) {
                        router.openEdit(transactionId: tx.id)
                    }
                    if index < rows.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(yearMonth)
        .navigationBarTitleDisplayMode(.inline)
    }
}
