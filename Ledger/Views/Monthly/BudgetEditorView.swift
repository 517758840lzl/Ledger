import SwiftUI

struct BudgetEditorView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let yearMonth: String
    @State private var totalText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(yearMonth) \(L10n.budget)")
                    .font(.headline)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(store.settings.currencySymbol)
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.greenDark)
                    TextField("0", text: $totalText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.greenDark)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))

                Text(L10n.t("monthly.budget_quick"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 10) {
                    ForEach(["500", "1000", "2000", "5000"], id: \.self) { amount in
                        Button(amount) { totalText = amount }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.greenSoft))
                            .foregroundStyle(AppTheme.greenDark)
                    }
                }

                Text(L10n.t("monthly.budget_footer"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                LedgerPrimaryButton(title: L10n.save) {
                    let value = Double(totalText.replacingOccurrences(of: ",", with: "")) ?? 0
                    guard value > 0 else { return }
                    var b = store.budgets.first(where: { $0.yearMonth == yearMonth }) ?? MonthBudget(yearMonth: yearMonth)
                    b.total = value
                    store.upsertBudget(b)
                    dismiss()
                }
            }
            .padding(16)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.budget)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
        .onAppear {
            totalText = store.budgets.first(where: { $0.yearMonth == yearMonth }).map { String(format: "%g", $0.total) } ?? ""
        }
    }
}
