import SwiftUI

struct AssetsHomeView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    private var configured: Bool {
        store.accounts.contains { $0.kind != .cash }
            || store.accounts.contains { $0.openingBalance != 0 }
            || !store.transactions.isEmpty
    }

    var body: some View {
        NavigationStack(path: $router.assetsPath) {
            Group {
                if configured {
                    assetsList
                } else {
                    onboarding
                }
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(L10n.assetsTitle)
            .toolbar {
                if configured {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            router.assetsPath.append(AssetsRoute.editor)
                        } label: {
                            Text(L10n.edit)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                        .background(Capsule().fill(AppTheme.card))
                                )
                        }
                    }
                }
            }
            .navigationDestination(for: AssetsRoute.self) { route in
                switch route {
                case .editor:
                    AssetsEditorView()
                case .formNew(let kind):
                    AssetFormView(kind: kind, existing: nil)
                case .formEdit(let id):
                    AssetFormView(kind: .other, existing: store.accounts.first(where: { $0.id == id }))
                }
            }
        }
    }

    private var onboarding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 对标 Android：深绿英雄卡 + 图标功能行 + 底部说明卡
                VStack(alignment: .leading, spacing: 12) {
                    Image("TabPiggy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.14)))
                        .accessibilityLabel(L10n.featureBoard)
                    Text(L10n.featureBoard)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.greenMuted)
                    Text(L10n.t("assets.hero_title"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text(L10n.t("assets.hero_body"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.greenDark, AppTheme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                )

                featureRow(icon: "chart.line.uptrend.xyaxis", title: L10n.featureAuto, body: L10n.featureAutoBody)
                featureRow(icon: "lock.shield", title: L10n.featureLocal, body: L10n.featureLocalBody)
                featureRow(icon: "iphone", title: L10n.featureNoCard, body: L10n.featureNoCardBody)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(AppTheme.greenDark)
                        .frame(width: 28, height: 28)
                    Text(L10n.assetsStockHint)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))

                LedgerPrimaryButton(title: L10n.t("assets.setup_cta")) {
                    router.assetsPath.append(AssetsRoute.editor)
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
    }

    private var assetsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AssetsNetWorthCard()

                Text(L10n.sources).font(.headline)
                ForEach(store.accounts.filter(\.enabled)) { acc in
                    AssetsSourceCard(account: acc) {
                        router.assetsPath.append(AssetsRoute.formEdit(acc.id))
                    }
                }

                AssetsRecentExpensesBlock()
            }
            .padding(16)
            .padding(.bottom, 110)
        }
    }

    private func featureRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.greenDark)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.greenSoft))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(AppTheme.greenDark)
                Text(body).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.greenSoft.opacity(0.45)))
    }
}

struct AssetsEditorView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var goalText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.assetsEditorHint)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                LedgerCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("assets.edit_goal"))
                            .font(.subheadline.weight(.semibold))
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(store.settings.currencySymbol)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.greenDark)
                            TextField("0", text: $goalText)
                                .keyboardType(.decimalPad)
                                .font(.title3.weight(.bold))
                        }
                        HStack(spacing: 8) {
                            ForEach(["0", "200", "500", "2000"], id: \.self) { amount in
                                Button(amount == "0" ? L10n.t("common.clear") : amount) {
                                    goalText = amount == "0" ? "" : amount
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.greenSoft))
                                .foregroundStyle(AppTheme.greenDark)
                            }
                        }
                    }
                }

                ForEach(store.accounts) { acc in
                    Button {
                        router.assetsPath.append(AssetsRoute.formEdit(acc.id))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(acc.name).foregroundStyle(AppTheme.textPrimary)
                                Text(acc.kind.localizedName + (acc.manualOnly ? " · " + L10n.manualOnly : ""))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(store.symbol(store.balance(for: acc)))
                                .foregroundStyle(AppTheme.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(white: 0.75))
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.card))
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    quick(L10n.addBank, .bank)
                    quick(L10n.addWechatAlipay, .wechat)
                }
                HStack {
                    quick(L10n.addStockFund, .stock)
                    Button(L10n.addSource) {
                        router.assetsPath.append(AssetsRoute.formNew(.other))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.greenMuted))
                    .foregroundStyle(AppTheme.greenDark)
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.fillAssets)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    store.settings.savingsGoal = Double(goalText.replacingOccurrences(of: ",", with: "")) ?? 0
                    store.save()
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.greenDark)
            }
        }
        .onAppear {
            let g = store.settings.savingsGoal
            goalText = g > 0 ? String(format: "%g", g) : ""
        }
    }

    private func quick(_ title: String, _ kind: AccountKind) -> some View {
        Button(title) {
            router.assetsPath.append(AssetsRoute.formNew(kind))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.greenSoft))
        .foregroundStyle(AppTheme.greenDark)
    }
}

struct AssetFormView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let kind: AccountKind
    let existing: Account?

    @State private var name = ""
    @State private var balance = ""
    @State private var selectedKind: AccountKind = .bank
    @State private var manualOnly = false
    @State private var includeInNetWorth = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LedgerCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.sourceType)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Picker("", selection: $selectedKind) {
                            ForEach(AccountKind.allCases) { k in
                                Text(k.localizedName).tag(k)
                            }
                        }
                        .pickerStyle(.menu)

                        LedgerUnderlineField(label: L10n.sourceName, text: $name)
                        LedgerUnderlineField(
                            label: selectedKind == .credit ? L10n.currentDebt : L10n.currentBalance,
                            text: $balance,
                            keyboard: .decimalPad
                        )

                        Text(L10n.t("monthly.budget_quick"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(["100", "500", "1000", "5000"], id: \.self) { amount in
                                Button(amount) { balance = amount }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.greenSoft))
                                    .foregroundStyle(AppTheme.greenDark)
                            }
                        }
                    }
                }

                LedgerCard {
                    Toggle(L10n.manualOnly, isOn: $manualOnly).tint(AppTheme.greenDark)
                    Toggle(L10n.includeNetWorth, isOn: $includeInNetWorth).tint(AppTheme.greenDark)
                    Text(selectedKind == .stock || selectedKind == .fund
                         ? L10n.t("assets.footer_manual_stock")
                         : L10n.t("assets.footer_follow_ledger"))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 4)
                }

                LedgerPrimaryButton(title: L10n.save) {
                    var acc = existing ?? Account(name: name, kind: selectedKind, openingBalance: 0)
                    acc.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultName(for: selectedKind) : name
                    acc.kind = selectedKind
                    acc.openingBalance = Double(balance) ?? 0
                    acc.manualOnly = manualOnly
                    acc.includeInNetWorth = includeInNetWorth
                    store.upsertAccount(acc)
                    dismiss()
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(existing == nil ? L10n.newSource : L10n.editSource)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedKind = existing?.kind ?? kind
            name = existing?.name ?? defaultName(for: selectedKind)
            balance = existing.map { String(format: "%.2f", $0.openingBalance) } ?? ""
            manualOnly = existing?.manualOnly ?? (kind == .stock || kind == .fund)
            includeInNetWorth = existing?.includeInNetWorth ?? true
            if kind == .wechat && existing == nil {
                selectedKind = .wechat
                name = "微信"
            }
        }
        .onChange(of: selectedKind) { _, new in
            if existing == nil {
                name = defaultName(for: new)
                if new == .stock || new == .fund { manualOnly = true }
            }
        }
    }

    private func defaultName(for k: AccountKind) -> String {
        switch k {
        case .bank: return "招商银行"
        case .wechat: return "微信"
        case .alipay: return "支付宝"
        case .stock: return "股票"
        case .fund: return "基金"
        case .credit: return "信用卡"
        case .cash: return "现金"
        case .other: return "资金来源"
        }
    }
}
