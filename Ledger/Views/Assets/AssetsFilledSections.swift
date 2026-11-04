import SwiftUI

/// 对标 Android 资产已配置态：净资产卡（含储蓄目标）
struct AssetsNetWorthCard: View {
    @EnvironmentObject private var store: LedgerStore

    private var goal: Double { store.settings.savingsGoal }
    private var worth: Double { store.netWorth }
    private var remaining: Double { max(0, goal - worth) }
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, max(0, worth / goal))
    }
    private var pct: Int { Int((progress * 100).rounded(.towardZero)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.netWorth)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.greenMuted)
            Text(store.symbol(worth))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if goal > 0 {
                // 对标 Android：深绿轨道 + 浅绿进度
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.28))
                        Capsule()
                            .fill(AppTheme.greenSoft)
                            .frame(width: max(6, geo.size.width * progress))
                    }
                }
                .frame(height: 8)
                .padding(.top, 2)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("assets.goal_remaining"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(store.symbol(remaining))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(L10n.t("assets.savings_goal"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(store.symbol(goal))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }

                Group {
                    if progress >= 1 {
                        // 对标 Android：超出目标时展示超额金额
                        Text(String(format: L10n.t("assets.goal_over"), store.symbol(worth - goal)))
                    } else {
                        Text(String(format: L10n.t("assets.goal_progress"), pct))
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.greenMuted)
            } else {
                Text(L10n.netWorthFootnote)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [AppTheme.greenDark, AppTheme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

/// 对标 Android「各来源」：色块 icon + 名称 + 灰 pill + 金额（无 chevron）
struct AssetsSourceCard: View {
    @EnvironmentObject private var store: LedgerStore
    let account: Account
    var onTap: () -> Void

    var body: some View {
        let visual = AccountVisual.style(for: account.kind)
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: visual.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(visual.foreground)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(visual.background))

                HStack(spacing: 8) {
                    Text(account.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(account.manualOnly ? L10n.manualOnly : L10n.followLedger)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.06)))
                }

                Spacer(minLength: 8)

                Text(store.symbol(store.balance(for: account)))
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 对标 Android「最近 10 笔支出」
struct AssetsRecentExpensesBlock: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    private var followIds: Set<UUID> {
        Set(store.accounts.filter { $0.enabled && $0.includeInNetWorth && !$0.manualOnly }.map(\.id))
    }

    private var rows: [Transaction] {
        store.transactions
            .filter { $0.type == .expense && followIds.contains($0.accountId) }
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("assets.recent_expenses")).font(.headline)
            Text(L10n.t("assets.recent_hint"))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if rows.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppTheme.greenDark.opacity(0.45))
                        .frame(width: 88, height: 88)
                        .background(Circle().fill(AppTheme.greenSoft.opacity(0.55)))
                    Text(L10n.t("assets.recent_empty"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        router.openAdd()
                    } label: {
                        Text(L10n.t("assets.record_one"))
                            .font(.headline)
                            .foregroundStyle(AppTheme.greenDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.greenSoft))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(rows) { tx in
                        let cat = store.category(id: tx.categoryId)
                        let visual = CategoryVisual.style(categoryName: cat?.name ?? "", type: .expense)
                        HStack(spacing: 12) {
                            Image(systemName: visual.systemImage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(visual.foreground)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(visual.background))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat?.name ?? L10n.expense)
                                    .font(.subheadline.weight(.semibold))
                                // 对标 Android：现金 · 备注/无备注
                                let accName = store.account(id: tx.accountId)?.name ?? ""
                                let note = tx.note.isEmpty ? L10n.t("flow.no_note") : tx.note
                                Text("\(accName) · \(note)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Text("-" + store.symbol(tx.amount))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 10)
                        if tx.id != rows.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.card)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                )
            }
        }
    }
}
