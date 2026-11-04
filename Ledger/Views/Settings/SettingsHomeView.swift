//
//  SettingsHomeView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/24.
//

import SwiftUI

struct SettingsHomeView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    var body: some View {
        let languageCode = store.settings.languageCode
        NavigationStack(path: $router.settingsPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsGroup(L10n.t("settings.section_ledger")) {
                        settingsPush(L10n.accounts, icon: "creditcard.fill", tint: Color(red: 0.20, green: 0.55, blue: 0.35), route: .accounts)
                        settingsPush(L10n.categories, icon: "square.grid.3x3.fill", tint: Color(red: 0.72, green: 0.55, blue: 0.28), route: .categories)
                        settingsPush(L10n.export, icon: "arrow.down.to.line", tint: Color(red: 0.25, green: 0.45, blue: 0.85), route: .export)
                        settingsPush(L10n.t("settings.import"), icon: "arrow.up.to.line", tint: Color(red: 0.20, green: 0.65, blue: 0.70), route: .importData)
                        Button {
                            router.pendingConfirm = PendingConfirm(
                                title: L10n.t("settings.clear_confirm_title"),
                                message: L10n.t("settings.clear_confirm_body"),
                                confirmTitle: L10n.t("settings.clear_action"),
                                run: { store.clearLocalDataKeepingCash() }
                            )
                        } label: {
                            settingsRow(L10n.clearLocal, icon: "trash.fill", tint: Color(red: 0.85, green: 0.25, blue: 0.25), destructive: true)
                        }
                    }

                    settingsGroup(L10n.t("settings.section_general")) {
                        settingsPush(L10n.language, icon: "character.book.closed.fill", tint: Color(red: 0.30, green: 0.45, blue: 0.90), route: .language)
                        settingsPush(L10n.currency, icon: "dollarsign.circle.fill", tint: Color(red: 0.35, green: 0.65, blue: 0.90), route: .currency)
                        settingsPush(L10n.reminder, icon: "bell.fill", tint: Color(red: 0.95, green: 0.55, blue: 0.20), route: .reminder)
                        settingsPush(L10n.about, icon: "info.circle.fill", tint: Color(red: 0.90, green: 0.40, blue: 0.55), route: .about)
                    }
                }
                .padding(16)
                .padding(.bottom, 110)
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.greenDark)
            .navigationDestination(for: SettingsRoute.self) { route in
                settingsDestination(route)
                    .id(languageCode)
            }
        }
        .id(languageCode)
    }

    @ViewBuilder
    private func settingsDestination(_ route: SettingsRoute) -> some View {
        switch route {
        case .accounts:
            AccountsSettingsView()
        case .accountNew:
            AccountEditorView(account: nil)
        case .accountEdit(let id):
            AccountEditorView(account: store.accounts.first(where: { $0.id == id }))
        case .accountHistory(let id):
            if let acc = store.accounts.first(where: { $0.id == id }) {
                AccountHistoryView(account: acc)
            }
        case .categories:
            CategoriesSettingsView()
        case .categoryAddTop(let type):
            CategoryNameEditorView(mode: .top(type))
        case .categoryAddChild(let id):
            if let cat = store.categories.first(where: { $0.id == id }) {
                CategoryNameEditorView(mode: .child(cat))
            }
        case .export:
            ExportSettingsView()
        case .importData:
            ImportSettingsView()
        case .language:
            LanguageSettingsView()
        case .currency:
            CurrencySettingsView()
        case .reminder:
            ReminderSettingsView()
        case .about:
            AboutSettingsView()
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
        }
    }

    private func settingsPush(_ title: String, icon: String, tint: Color, route: SettingsRoute) -> some View {
        Button {
            router.settingsPath.append(route)
        } label: {
            settingsRow(title, icon: icon, tint: tint, destructive: false)
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(_ title: String, icon: String, tint: Color, destructive: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.14)))
            Text(title)
                .font(.body)
                .foregroundStyle(destructive ? Color.red : AppTheme.textPrimary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(white: 0.75))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
