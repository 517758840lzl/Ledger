//
//  SummaryCard.swift
//  Ledger
//
//  Created by Ketty on 2026/11/02.
//

import SwiftUI

struct SummaryCard: View {
    @EnvironmentObject private var store: LedgerStore
    let yearMonth: String
    /// Balance card footer: vs last month
    var vsLastMonth: String? = nil

    private var balance: Double { store.monthBalance(yearMonth) }
    private var expense: Double { store.monthExpense(yearMonth) }
    private var income: Double { store.monthIncome(yearMonth) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(yearMonth) \(L10n.t("summary.balance"))")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.greenMuted)
            Text(store.symbol(abs(balance)))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(vsLastMonth != nil && balance < 0 ? AppTheme.shortfallOnCard : .white)
            Divider().overlay(Color.white.opacity(0.2))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.expense.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(store.symbol(expense))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.income.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.incomeOnCard.opacity(0.85))
                    Text(store.symbol(income))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.incomeOnCard)
                }
                Spacer()
            }
            if let vsLastMonth {
                VStack(spacing: 6) {
                    if expense != income {
                        HStack {
                            Text(expense > income ? L10n.t("summary.spend_more") : L10n.t("summary.income_more"))
                            Spacer()
                            Text(store.symbol(abs(expense - income)))
                        }
                    }
                    HStack {
                        Text(L10n.t("monthly.vs_last"))
                        Spacer()
                        Text(vsLastMonth).fontWeight(.semibold)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(colors: [AppTheme.greenDark, AppTheme.green], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
    }
}
