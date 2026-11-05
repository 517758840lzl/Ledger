//
//  FlowHomeView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/31.
//

import SwiftUI

struct FlowHomeView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @State private var filter: TxType? = nil
    @State private var query = ""

    private var ym: String { store.yearMonth() }

    private var filtered: [Transaction] {
        let matched = store.transactions(in: ym, type: filter)
            .filter { tx in
                guard !query.isEmpty else { return true }
                let cat = store.category(id: tx.categoryId)?.name.ledgerText ?? ""
                let acc = store.account(id: tx.accountId)?.name.ledgerText ?? ""
                let note = tx.note.ledgerText
                let sub = tx.subcategory?.ledgerText ?? ""
                return String(format: "%.2f", tx.amount).contains(query)
                    || cat.localizedCaseInsensitiveContains(query)
                    || acc.localizedCaseInsensitiveContains(query)
                    || note.localizedCaseInsensitiveContains(query)
                    || sub.localizedCaseInsensitiveContains(query)
            }
        return store.listed(matched)
    }

    var body: some View {
        NavigationStack(path: $router.flowPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SummaryCard(yearMonth: ym)

                    Button {
                        router.flowPath.append(FlowRoute.history)
                    } label: {
                        HStack {
                            Text(L10n.historyBills)
                            Spacer()
                            LedgerMark(symbol: "MarkChevronRight", point: 12)
                                .foregroundStyle(Color(white: 0.75))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
                    }
                    .buttonStyle(.plain)

                    HStack {
                        LedgerMark(symbol: "MarkSearch", point: 17, weight: .regular).foregroundStyle(AppTheme.textSecondary)
                        TextField(L10n.searchPlaceholder, text: $query)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.card))

                    // Gray capsule track, equal segments, white selected pill
                    filterSegmentedBar

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        daySections
                        Button {
                            router.flowPath.append(FlowRoute.history)
                        } label: {
                            Text(L10n.t("flow.see_earlier"))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.page)
            .navigationTitle(L10n.flowTitle)
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.greenDark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.flowPath.append(FlowRoute.calendar)
                    } label: {
                        LedgerMark(symbol: "MarkCalendar", point: 17, weight: .regular)
                            .foregroundStyle(AppTheme.greenDark)
                    }
                    .accessibilityLabel(L10n.calendarTitle)
                }
            }
            .navigationDestination(for: FlowRoute.self) { route in
                switch route {
                case .add:
                    AddEntryView(presetDate: router.pendingPresetDate)
                        .onAppear { router.pendingPresetDate = nil }
                case .edit(let id):
                    if let tx = store.transactions.first(where: { $0.id == id }) {
                        AddEntryView(editing: tx)
                    } else {
                        Text(L10n.t("flow.missing_tx")).foregroundStyle(AppTheme.textSecondary)
                    }
                case .calendar:
                    CalendarFlowView()
                case .history:
                    HistoryBillsView()
                case .month(let ym):
                    MonthTransactionsView(yearMonth: ym)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(AppTheme.greenSoft.opacity(0.45)).frame(width: 88, height: 88)
                LedgerMark(symbol: "MarkPage", point: 30, weight: .regular).foregroundStyle(AppTheme.green)
            }
            Text(L10n.emptyFlow)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                router.openAdd()
            } label: {
                Text(L10n.addTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.greenSoft))
                    .foregroundStyle(AppTheme.greenDark)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var daySections: some View {
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return ForEach(grouped.keys.sorted(by: >), id: \.self) { day in
            let rows = grouped[day] ?? []
            let exp = rows.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let inc = rows.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(dayTitle(day)).font(.subheadline.weight(.semibold))
                    Spacer()
                    HStack(spacing: 0) {
                        Text("\(L10n.t("flow.expense_short")) \(store.symbol(exp))")
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(" · ")
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(L10n.t("flow.income_short")) \(store.symbol(inc))")
                            .foregroundStyle(inc > 0 ? AppTheme.incomeAmount : AppTheme.textSecondary)
                    }
                    .font(.caption)
                }
                LedgerTxnDayCard {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, tx in
                        txnRow(tx)
                        if index < rows.count - 1 {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
            }
        }
    }

    private func txnRow(_ tx: Transaction) -> some View {
        let catName = store.category(id: tx.categoryId)?.name
        let title = TxRowText.title(tx: tx, store: store)
        let subtitle = TxRowText.subtitle(tx: tx, store: store)
        let visual = CategoryVisual.style(categoryName: catName ?? title, type: tx.type)
        return LedgerTxnCell(
            title: title,
            subtitle: subtitle,
            amount: amountText(tx),
            amountColor: tx.type == .income ? AppTheme.incomeAmount : AppTheme.textPrimary,
            iconMark: visual.markName,
            iconForeground: visual.foreground,
            iconBackground: visual.background,
            embedded: true
        ) {
            router.openEdit(transactionId: tx.id)
        }
        .contextMenu {
            Button(L10n.edit) { router.openEdit(transactionId: tx.id) }
            Button(L10n.t("common.delete"), role: .destructive) {
                store.deleteTransaction(tx.id)
            }
        }
    }

    private func amountText(_ tx: Transaction) -> String {
        let sign = tx.type == .expense ? "-" : (tx.type == .income ? "+" : "")
        return "\(sign)\(store.symbol(tx.amount))"
    }

    private var filterSegmentedBar: some View {
        let items: [(String, TxType?)] = [
            (L10n.t("flow.this_month"), nil),
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
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            Capsule()
                                .fill(on ? AppTheme.card : Color.clear)
                                .shadow(color: on ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.black.opacity(0.06)))
    }

    private func dayTitle(_ day: Date) -> String {
        let f = DateFormatter()
        f.locale = AppLocaleCatalog.locale(for: store.settings.languageCode)
        f.setLocalizedDateFormatFromTemplate("MMMd")
        let md = f.string(from: day)
        if Calendar.current.isDateInToday(day) { return "\(L10n.today) \(md)" }
        if Calendar.current.isDateInYesterday(day) {
            return "\(L10n.t("flow.yesterday_prefix")) \(md)"
        }
        return md
    }
}
