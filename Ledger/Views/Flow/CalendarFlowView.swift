import SwiftUI

struct CalendarFlowView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @State private var cursor = Date()
    @State private var selected = Date()

    private var cal: Calendar { Calendar.current }

    private var days: [Date?] {
        let start = cal.date(from: cal.dateComponents([.year, .month], from: cursor)) ?? cursor
        let weekday = cal.component(.weekday, from: start)
        let pad = (weekday - cal.firstWeekday + 7) % 7
        let range = cal.range(of: .day, in: .month, for: cursor) ?? 1..<31
        var cells: [Date?] = Array(repeating: nil, count: pad)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: start) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var dayRows: [Transaction] {
        store.transactions
            .filter { cal.isDate($0.date, inSameDayAs: selected) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 对标 Android：无结余卡，只有月份切换 + 日格
                HStack {
                    Button {
                        cursor = cal.date(byAdding: .month, value: -1, to: cursor) ?? cursor
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text(monthTitle(cursor)).font(.headline.weight(.semibold))
                    Spacer()
                    Button {
                        cursor = cal.date(byAdding: .month, value: 1, to: cursor) ?? cursor
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(L10n.t("common.forward"))
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                        Text(s)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }

                HStack {
                    Text(dayTitle(selected)).font(.headline)
                    Spacer()
                    let exp = dayRows.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    let inc = dayRows.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    Text("\(L10n.t("flow.expense_short")) \(store.symbol(exp)) · \(L10n.t("flow.income_short")) \(store.symbol(inc))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if dayRows.isEmpty {
                    emptyDay
                } else {
                    LedgerTxnDayCard {
                        ForEach(Array(dayRows.enumerated()), id: \.element.id) { index, tx in
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
                            if index < dayRows.count - 1 {
                                Divider().padding(.leading, 66)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.calendarTitle)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
        .onAppear { selected = Date(); cursor = Date() }
    }

    private func dayCell(_ day: Date) -> some View {
        let selectedDay = cal.isDate(day, inSameDayAs: selected)
        let dayTx = store.transactions.filter { cal.isDate($0.date, inSameDayAs: day) }
        let hasExp = dayTx.contains { $0.type == .expense }
        let hasInc = dayTx.contains { $0.type == .income }
        return Button {
            selected = day
        } label: {
            VStack(spacing: 4) {
                Text("\(cal.component(.day, from: day))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selectedDay ? Color.white : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedDay ? AppTheme.greenDark : Color.black.opacity(0.05))
                    )
                HStack(spacing: 3) {
                    if hasExp {
                        Circle().fill(AppTheme.green).frame(width: 4, height: 4)
                    }
                    if hasInc {
                        Circle().fill(AppTheme.incomeAmount).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyDay: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.greenSoft.opacity(0.55)).frame(width: 72, height: 72)
                Image(systemName: "doc.text")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppTheme.green)
            }
            Text(L10n.t("flow.calendar_empty"))
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                router.openAdd(presetDate: selected)
            } label: {
                Text(L10n.addTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.greenSoft))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var weekdaySymbols: [String] {
        var c = Calendar.current
        c.locale = .current
        return c.veryShortWeekdaySymbols
    }

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("yyyyMMM")
        return f.string(from: d)
    }

    private func dayTitle(_ d: Date) -> String {
        if cal.isDateInToday(d) { return L10n.today }
        if cal.isDateInYesterday(d) { return L10n.t("flow.yesterday_prefix") }
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("MMMd")
        return f.string(from: d)
    }
}
