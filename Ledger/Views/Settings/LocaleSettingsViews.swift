import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    private let options = [("zh-Hans", "中文（简体）"), ("en", "English"), ("es", "Español")]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(options, id: \.0) { code, name in
                    LedgerSelectCell(title: name, selected: store.settings.languageCode == code) {
                        store.settings.languageCode = code
                        UserDefaults.standard.set([code], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        store.save()
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.language)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}

private struct CurrencyOption: Identifiable {
    let id: String
    let symbol: String
    var titleKey: String { "currency.\(id.lowercased())" }
}

struct CurrencySettingsView: View {
    @EnvironmentObject private var store: LedgerStore

    private let options: [CurrencyOption] = [
        .init(id: "USD", symbol: "$"),
        .init(id: "EUR", symbol: "€"),
        .init(id: "GBP", symbol: "£"),
        .init(id: "JPY", symbol: "¥"),
        .init(id: "CNY", symbol: "¥"),
        .init(id: "HKD", symbol: "HK$"),
        .init(id: "TWD", symbol: "NT$"),
        .init(id: "KRW", symbol: "₩"),
        .init(id: "SGD", symbol: "S$"),
        .init(id: "AUD", symbol: "A$"),
        .init(id: "CAD", symbol: "C$")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(options) { opt in
                    Button {
                        store.settings.currencySymbol = opt.symbol
                        store.settings.currencyCode = opt.id
                        store.save()
                    } label: {
                        HStack(spacing: 12) {
                            Text(opt.symbol)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 52, alignment: .leading)
                            Text("\(opt.id) · \(L10n.t(opt.titleKey))")
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if store.settings.currencyCode == opt.id {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AppTheme.greenDark)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.currency)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}
