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
                if months.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(AppTheme.greenSoft).frame(width: 72, height: 72)
                            Image(systemName: "doc.text")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(AppTheme.greenDark)
                        }
                        Text(L10n.t("flow.history_empty"))
                            .foregroundStyle(AppTheme.textSecondary)
                        Button {
                            if !router.flowPath.isEmpty { router.flowPath.removeLast() }
                        } label: {
                            Text(L10n.t("flow.back_to_flow"))
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.greenSoft))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    Text(L10n.t("flow.history_hint"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    ForEach(months, id: \.self) { ym in
                        monthCard(ym)
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

    private func monthCard(_ ym: String) -> some View {
        let count = store.transactions(in: ym).count
        let expense = store.monthExpense(ym)
        let income = store.monthIncome(ym)
        let balance = abs(store.monthBalance(ym))
        return Button {
            router.flowPath.append(FlowRoute.month(ym))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(monthTitle(ym)).font(.headline)
                    Spacer()
                    Text(String(format: L10n.t("flow.tx_count"), count))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                HStack(spacing: 14) {
                    Text("\(L10n.expense) \(store.symbol(expense))")
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(L10n.income) \(store.symbol(income))")
                        .foregroundStyle(AppTheme.incomeAmount)
                    Text("\(L10n.t("summary.balance")) \(store.symbol(balance))")
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .font(.subheadline)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
        }
        .buttonStyle(.plain)
    }

    private func monthTitle(_ ym: String) -> String {
        let parts = ym.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return ym }
        if store.settings.languageCode.hasPrefix("zh") {
            return "\(year)年\(month)月"
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = AppLocaleCatalog.locale(for: store.settings.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMM")
        return formatter.string(from: date)
    }
}

struct MonthTransactionsView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    let yearMonth: String
    @State private var filter: TxType? = nil

    private var rows: [Transaction] {
        let matched = store.transactions(in: yearMonth).filter { filter == nil || $0.type == filter }
        return store.listed(matched)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SummaryCard(yearMonth: yearMonth)
                typeFilter
                if !rows.isEmpty { dayHeader }
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
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageTitle: String {
        let parts = yearMonth.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]),
              store.settings.languageCode.hasPrefix("zh") else {
            return yearMonth
        }
        return "\(year)年\(month)月 \(L10n.flowTitle)"
    }

    private var typeFilter: some View {
        let items: [(String, TxType?)] = [
            (L10n.t("flow.all"), nil),
            (L10n.expense, .expense),
            (L10n.income, .income),
            (L10n.transfer, .transfer),
        ]
        return HStack(spacing: 0) {
            ForEach(items, id: \.0) { title, value in
                let on = filter == value
                Button {
                    filter = value
                } label: {
                    Text(title)
                        .font(.subheadline.weight(on ? .semibold : .medium))
                        .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Capsule().fill(on ? AppTheme.card : Color.clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.black.opacity(0.06)))
    }

    private var dayHeader: some View {
        let expense = rows.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let income = rows.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let day = rows.first?.date ?? Date()
        let formatter = DateFormatter()
        formatter.locale = AppLocaleCatalog.locale(for: store.settings.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let title = Calendar.current.isDateInToday(day) ? "\(L10n.today) \(formatter.string(from: day))" : formatter.string(from: day)
        return HStack {
            Text(title)
            Spacer()
            Text("\(L10n.t("flow.expense_short")) \(store.symbol(expense)) · \(L10n.t("flow.income_short")) \(store.symbol(income))")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .font(.subheadline.weight(.semibold))
    }
}
