import SwiftUI

struct MonthlyReportView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @State private var monthOffset = 0

    private var ym: String {
        let cal = Calendar.current
        let base = cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        return store.yearMonth(for: base)
    }

    private var expense: Double { store.monthExpense(ym) }
    private var income: Double { store.monthIncome(ym) }

    private var categoryBreakdown: [(Category, Double)] {
        let txs = store.transactions(in: ym, type: .expense)
        var map: [UUID: Double] = [:]
        for tx in txs {
            guard let cid = tx.categoryId else { continue }
            map[cid, default: 0] += tx.amount
        }
        return map.compactMap { id, value in
            guard let cat = store.category(id: id) else { return nil }
            return (cat, value)
        }
        .sorted { $0.1 > $1.1 }
    }

    private var recentMonths: [String] {
        let cal = Calendar.current
        let anchor = cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        return (0..<6).compactMap { offset in
            guard let d = cal.date(byAdding: .month, value: -offset, to: anchor) else { return nil }
            return store.yearMonth(for: d)
        }.reversed()
    }

    private var vsLastMonth: String {
        let cal = Calendar.current
        guard let prev = cal.date(
            byAdding: .month,
            value: -1,
            to: cal.date(from: DateComponents(year: Int(ym.prefix(4)) ?? 2026, month: Int(ym.suffix(2)) ?? 1)) ?? Date()
        ) else {
            return L10n.t("monthly.flat")
        }
        let prevYm = store.yearMonth(for: prev)
        let prevExp = store.monthExpense(prevYm)
        if prevExp == 0 && expense == 0 { return L10n.t("monthly.flat") }
        if prevExp == 0 { return L10n.t("monthly.up") }
        let delta = (expense - prevExp) / prevExp
        if abs(delta) < 0.02 { return L10n.t("monthly.flat") }
        return delta > 0 ? L10n.t("monthly.up") : L10n.t("monthly.down")
    }

    var body: some View {
        NavigationStack(path: $router.monthlyPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    monthSwitcher
                    SummaryCard(yearMonth: ym, vsLastMonth: vsLastMonth)
                    budgetBlock
                    monthsBlock
                    if expense > 0 {
                        shareBlock
                        mainSpendBlock
                        reducibleBlock
                    }
                }
                .padding(16)
                .padding(.bottom, 110)
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(L10n.monthlyTitle)
            .tint(AppTheme.greenDark)
            .navigationDestination(for: MonthlyRoute.self) { route in
                switch route {
                case .budget(let key):
                    BudgetEditorView(yearMonth: key)
                case .categoryDetail(let id, let key):
                    MonthlyCategoryDetailView(categoryId: id, yearMonth: key)
                case .canReduceSettings:
                    CanReduceSettingsView()
                }
            }
        }
    }

    private var monthSwitcher: some View {
        HStack {
            Button { monthOffset -= 1 } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(L10n.t("common.back"))
            Spacer()
            Text(monthTitle(ym)).font(.title3.weight(.bold))
            Spacer()
            Button {
                if monthOffset < 0 { monthOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(monthOffset < 0 ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.35))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(L10n.t("common.forward"))
            .disabled(monthOffset >= 0)
        }
    }

    private var budgetBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let b = store.budgets.first(where: { $0.yearMonth == ym }), b.total > 0 {
                Text("\(L10n.t("monthly.budget_label")) \(store.symbol(b.total))")
                ProgressView(value: min(expense / max(b.total, 1), 1))
                    .tint(AppTheme.green)
                Button(L10n.t("monthly.set_budget")) {
                    router.monthlyPath.append(MonthlyRoute.budget(ym))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.greenDark)
            } else {
                Text(L10n.t("monthly.budget_empty"))
                    .foregroundStyle(AppTheme.textSecondary)
                Button(L10n.t("monthly.set_budget_full")) {
                    router.monthlyPath.append(MonthlyRoute.budget(ym))
                }
                .font(.headline)
                .foregroundStyle(AppTheme.greenDark)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Capsule().stroke(AppTheme.greenDark.opacity(0.75), lineWidth: 1.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }

    private var monthsBlock: some View {
        let values = recentMonths.map { store.monthExpense($0) }
        let maxV = max(values.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("monthly.last_6")).font(.headline)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(recentMonths.enumerated()), id: \.offset) { _, m in
                    let v = store.monthExpense(m)
                    let h = v <= 0 ? 8 : max(16, CGFloat(v / maxV) * 120)
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(m == ym && v > 0 ? AppTheme.green : Color.black.opacity(v > 0 ? 0.18 : 0.12))
                            .frame(height: h)
                        Text(String(m.suffix(2)))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
            .padding(.top, 8)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }

    /// 对标 Android：支出占比甜甜圈 + 图例
    private var shareBlock: some View {
        let items: [(String, Double, Color)] = categoryBreakdown.enumerated().map { idx, pair in
            (pair.0.name, pair.1, MonthlyPalette.color(at: idx))
        }
        return VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("monthly.expense_share")).font(.headline)
            MonthlySpendDonut(
                items: items.map { (name: $0.0, amount: $0.1, color: $0.2) },
                total: expense,
                totalLabel: L10n.t("monthly.month_expense"),
                totalText: store.symbol(expense)
            )
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }

    /// 对标 Android：主要支出（icon + 名称 + % + 金额）
    private var mainSpendBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("monthly.main_spend")).font(.headline)
            ForEach(Array(categoryBreakdown.enumerated()), id: \.element.0.id) { idx, item in
                let pct = expense > 0 ? Int((item.1 / expense) * 100) : 0
                let visual = CategoryVisual.style(categoryName: item.0.name, type: .expense)
                HStack(spacing: 12) {
                    Image(systemName: visual.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(visual.foreground)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(visual.background))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(pct)%")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Text(store.symbol(item.1))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.03))
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }

    /// 对标 Android：能少花的支出 + 明细入口 + 设置可少花
    private var reducibleBlock: some View {
        let rows = categoryBreakdown.filter { $0.0.canReduce }
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("monthly.reducible")).font(.headline)
            Text(L10n.t("monthly.reducible_hint"))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            if rows.isEmpty {
                Text(L10n.t("monthly.can_reduce"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(rows, id: \.0.id) { item in
                    let pct = expense > 0 ? Int((item.1 / expense) * 100) : 0
                    let save = (item.1 * 0.2).rounded(.towardZero)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.0.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text(String(format: L10n.t("monthly.reducible_save"), store.symbol(save)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.greenDark)
                        }
                        Text(String(format: L10n.t("monthly.reducible_reason_pct"), item.0.name, pct))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Button {
                            router.monthlyPath.append(MonthlyRoute.categoryDetail(item.0.id, ym))
                        } label: {
                            HStack {
                                Text(String(format: L10n.t("monthly.view_category_detail"), item.0.name))
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.greenDark))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.greenSoft.opacity(0.45)))
                }
            }
            Button {
                router.monthlyPath.append(MonthlyRoute.canReduceSettings)
            } label: {
                HStack {
                    Text(L10n.t("monthly.set_reducible_cats"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.03)))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }

    private func monthTitle(_ ym: String) -> String {
        let p = ym.split(separator: "-")
        guard p.count == 2 else { return ym }
        let code = store.settings.languageCode
        if code.hasPrefix("zh") {
            return "\(p[0])年\(Int(p[1]) ?? 0)月"
        }
        let names = ["January","February","March","April","May","June","July","August","September","October","November","December"]
        let mi = max(1, min(12, Int(p[1]) ?? 1)) - 1
        return "\(names[mi]) \(p[0])"
    }
}
