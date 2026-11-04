//
//  LocaleSettingsViews.swift
//  Ledger
//
//  Created by Ketty on 2026/10/22.
//

import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var store: LedgerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(AppLocaleCatalog.all) { entry in
                    LedgerSelectCell(
                        title: entry.languageName,
                        selected: store.settings.languageCode == entry.languageCode
                    ) {
                        store.settings.languageCode = entry.languageCode
                        store.settings.currencyCode = entry.currencyCode
                        store.settings.currencySymbol = entry.symbol
                        UserDefaults.standard.set([entry.languageCode], forKey: "AppleLanguages")
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

struct CurrencySettingsView: View {
    @EnvironmentObject private var store: LedgerStore

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(AppLocaleCatalog.all) { entry in
                    Button {
                        store.settings.currencySymbol = entry.symbol
                        store.settings.currencyCode = entry.currencyCode
                        store.settings.languageCode = entry.languageCode
                        UserDefaults.standard.set([entry.languageCode], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        store.save()
                    } label: {
                        HStack(spacing: 12) {
                            Text(entry.symbol)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 52, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(entry.currencyCode) · \(L10n.t("currency.\(entry.currencyCode.lowercased())"))")
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(entry.languageName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if store.settings.currencyCode == entry.currencyCode {
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
