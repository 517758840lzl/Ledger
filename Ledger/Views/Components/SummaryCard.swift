import SwiftUI

struct SummaryCard: View {
    @EnvironmentObject private var store: LedgerStore
    let yearMonth: String
    /// 对标 Android Insights：结余卡底部「较上月」
    var vsLastMonth: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(yearMonth) \(L10n.t("summary.balance"))")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.greenMuted)
            Text(store.symbol(store.monthBalance(yearMonth)))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Divider().overlay(Color.white.opacity(0.2))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.expense.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(store.symbol(store.monthExpense(yearMonth)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.income.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.incomeOnCard.opacity(0.85))
                    Text(store.symbol(store.monthIncome(yearMonth)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.incomeOnCard)
                }
                Spacer()
            }
            if let vsLastMonth {
                HStack {
                    Text(L10n.t("monthly.vs_last"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    Text(vsLastMonth)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
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
