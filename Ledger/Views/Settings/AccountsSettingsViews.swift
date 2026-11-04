import SwiftUI

struct AccountsSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t("settings.accounts_hint"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(store.accounts) { acc in
                    LedgerAccountCell(
                        title: acc.name,
                        subtitle: acc.kind.localizedName,
                        amount: store.symbol(store.balance(for: acc)),
                        onTap: { router.settingsPath.append(SettingsRoute.accountHistory(acc.id)) },
                        onEdit: { router.settingsPath.append(SettingsRoute.accountEdit(acc.id)) }
                    )
                }

                LedgerPrimaryButton(title: L10n.t("settings.add_account")) {
                    router.settingsPath.append(SettingsRoute.accountNew)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.accounts)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}

struct AccountEditorView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let account: Account?
    @State private var name = ""
    @State private var kind: AccountKind = .other
    @State private var opening = ""
    @State private var enabled = true
    @State private var showKind = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LedgerCard {
                    VStack(alignment: .leading, spacing: 18) {
                        LedgerUnderlineField(label: L10n.sourceName, text: $name)
                        Button { showKind = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(L10n.sourceType)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text(kind.localizedName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                        LedgerUnderlineField(
                            label: L10n.t("settings.opening_balance"),
                            text: $opening,
                            keyboard: .decimalPad
                        )
                        Text(L10n.t("monthly.budget_quick"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(["100", "500", "1000", "5000"], id: \.self) { amount in
                                Button(amount) { opening = amount }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.greenSoft))
                                    .foregroundStyle(AppTheme.greenDark)
                            }
                        }
                    }
                }

                LedgerCard {
                    Toggle(L10n.t("settings.enable_account"), isOn: $enabled)
                        .tint(AppTheme.greenDark)
                    Text(L10n.t("settings.enable_account_footer"))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 6)
                }

                LedgerPrimaryButton(title: L10n.save) {
                    var acc = account ?? Account(name: name, kind: kind, openingBalance: 0)
                    acc.name = name.isEmpty ? kind.localizedName : name
                    acc.kind = kind
                    acc.openingBalance = Double(opening) ?? 0
                    acc.enabled = enabled
                    store.upsertAccount(acc)
                    dismiss()
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(account == nil ? L10n.t("settings.new_account") : L10n.t("settings.edit_account"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
        .onAppear {
            if let account {
                name = account.name
                kind = account.kind
                opening = String(format: "%g", account.openingBalance)
                enabled = account.enabled
            }
        }
        .sheet(isPresented: $showKind) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(AccountKind.allCases) { k in
                            LedgerSelectCell(title: k.localizedName, selected: kind == k) {
                                kind = k
                                showKind = false
                            }
                        }
                    }
                    .padding(16)
                }
                .background(AppTheme.page.ignoresSafeArea())
                .navigationTitle(L10n.sourceType)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.cancel) { showKind = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct AccountHistoryView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    let account: Account

    var body: some View {
        let rows = store.transactions(forAccount: account.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name).font(.title2.bold())
                        Text(account.kind.localizedName).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text(store.symbol(store.balance(for: account)))
                        .font(.title3.bold())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))

                if rows.isEmpty {
                    Text(L10n.t("settings.account_history_empty"))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    LedgerTxnDayCard {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, tx in
                            let cat = store.category(id: tx.categoryId)?.name
                            let visual = CategoryVisual.style(categoryName: cat, type: tx.type)
                            let title = (tx.subcategory?.isEmpty == false ? tx.subcategory! : (cat ?? tx.type.localizedName))
                            LedgerTxnCell(
                                title: title,
                                subtitle: tx.note.isEmpty ? mediumDate(tx.date) : tx.note,
                                amount: amountText(tx),
                                amountColor: tx.type == .income ? AppTheme.incomeAmount : AppTheme.textPrimary,
                                iconSystemImage: visual.systemImage,
                                iconForeground: visual.foreground,
                                iconBackground: visual.background,
                                showsChevron: true,
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
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.t("settings.account_history"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func amountText(_ tx: Transaction) -> String {
        switch tx.type {
        case .expense: return "-\(store.symbol(tx.amount))"
        case .income: return "+\(store.symbol(tx.amount))"
        case .transfer:
            if tx.accountId == account.id { return "-\(store.symbol(tx.amount))" }
            return "+\(store.symbol(tx.amount))"
        }
    }

    private func mediumDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}
