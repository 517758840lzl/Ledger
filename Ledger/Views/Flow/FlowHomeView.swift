import SwiftUI

struct FlowHomeView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @State private var filter: TxType? = nil
    @State private var query = ""

    private var ym: String { store.yearMonth() }

    private var filtered: [Transaction] {
        store.transactions(in: ym, type: filter)
            .filter { tx in
                guard !query.isEmpty else { return true }
                let cat = store.category(id: tx.categoryId)?.name ?? ""
                let acc = store.account(id: tx.accountId)?.name ?? ""
                return String(format: "%.2f", tx.amount).contains(query)
                    || cat.contains(query)
                    || acc.contains(query)
                    || tx.note.contains(query)
            }
            .sorted { $0.date > $1.date }
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
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(white: 0.75))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.textSecondary)
                        TextField(L10n.searchPlaceholder, text: $query)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.card))

                    HStack(spacing: 8) {
                        chip(L10n.t("flow.this_month"), selected: filter == nil) { filter = nil }
                        chip(L10n.expense, selected: filter == .expense) { filter = .expense }
                        chip(L10n.income, selected: filter == .income) { filter = .income }
                        chip(L10n.transfer, selected: filter == .transfer) { filter = .transfer }
                    }

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        daySections
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.page)
            .navigationTitle(L10n.flowTitle)
            .tint(AppTheme.greenDark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.flowPath.append(FlowRoute.calendar)
                    } label: {
                        Image(systemName: "calendar")
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
                Image(systemName: "doc.text").font(.system(size: 30)).foregroundStyle(AppTheme.green)
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
        let titleBase = catName
            ?? (tx.type == .transfer ? L10n.transfer : L10n.t("flow.uncategorized"))
        // Android 有子类时标题常直接用子类名（如 Delivery）
        let title: String = {
            if let sub = tx.subcategory, !sub.isEmpty { return sub }
            return titleBase
        }()
        let subtitle: String = {
            let acc = store.account(id: tx.accountId)?.name ?? ""
            if tx.note.isEmpty { return "\(acc) · \(L10n.t("flow.no_note"))" }
            return "\(acc) · \(tx.note)"
        }()
        let visual = CategoryVisual.style(categoryName: catName ?? title, type: tx.type)
        return LedgerTxnCell(
            title: title,
            subtitle: subtitle,
            amount: amountText(tx),
            amountColor: tx.type == .income ? AppTheme.incomeAmount : AppTheme.textPrimary,
            iconSystemImage: visual.systemImage,
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

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? Color.white : Color.clear))
                .foregroundStyle(selected ? AppTheme.greenDark : AppTheme.textSecondary)
        }
    }

    private func dayTitle(_ day: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMMd")
        let md = f.string(from: day)
        if Calendar.current.isDateInToday(day) { return "\(L10n.today) \(md)" }
        if Calendar.current.isDateInYesterday(day) {
            return "\(L10n.t("flow.yesterday_prefix")) \(md)"
        }
        return md
    }
}
