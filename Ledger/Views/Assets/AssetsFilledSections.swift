//
//  AssetsFilledSections.swift
//  Ledger
//
//  Created by Ketty on 2026/10/15.
//

import SwiftUI

/// Configured assets: net-worth card (with savings goal)
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
                // Dark green track + light green progress
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
                        // Show over-goal amount when progress exceeds 100%
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

/// Sources row: tinted icon + name + gray pill + amount (no chevron)
struct AssetsSourceCard: View {
    @EnvironmentObject private var store: LedgerStore
    let account: Account
    var onTap: () -> Void

    var body: some View {
        let visual = AccountVisual.style(for: account.kind)
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: visual.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(visual.foreground)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(visual.background))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(account.name.ledgerText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(account.manualOnly ? L10n.manualOnly : L10n.followLedger)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(account.manualOnly ? AppTheme.textSecondary : AppTheme.greenDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(account.manualOnly ? Color.black.opacity(0.06) : AppTheme.greenSoft)
                            )
                    }
                    Text(store.symbol(store.balance(for: account)))
                        .font(.body.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer(minLength: 0)
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

/// Recent 10 expenses block
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
                                Text(cat?.name.ledgerText ?? L10n.expense)
                                    .font(.subheadline.weight(.semibold))
                                // Account · note / no-note
                                let accName = store.account(id: tx.accountId)?.name.ledgerText ?? ""
                                let note = tx.note.isEmpty ? L10n.t("flow.no_note") : tx.note.ledgerText
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
