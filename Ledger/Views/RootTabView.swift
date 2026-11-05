//
//  RootTabView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/24.
//

import SwiftUI

enum RootTab: Hashable {
    case flow, monthly, add, assets, settings
}

/// Applies the in-app locale and forces a full UI rebuild when language changes.
struct RootHostView: View {
    @EnvironmentObject private var store: LedgerStore

    var body: some View {
        RootTabView()
            .environment(\.locale, Locale(identifier: store.settings.languageCode))
            .id(store.settings.languageCode)
    }
}

struct RootTabView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    /// Hide the tab bar on pushed detail screens so the bottom Save button stays reachable.
    private var showsTabBar: Bool {
        switch router.tab {
        case .flow: return router.flowPath.isEmpty
        case .monthly: return router.monthlyPath.isEmpty
        case .assets: return router.assetsPath.isEmpty
        case .settings: return router.settingsPath.isEmpty
        case .add: return false
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.tab {
                case .flow: FlowHomeView()
                case .monthly: MonthlyReportView()
                case .add: FlowHomeView()
                case .assets: AssetsHomeView()
                case .settings: SettingsHomeView()
                }
            }
            .id(store.settings.languageCode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.page.ignoresSafeArea())

            if showsTabBar {
                tabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Keyboard must cover the bar. Letting the safe area shrink lifts the bar onto the keyboard.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.2), value: showsTabBar)
        .tint(AppTheme.greenDark)
        .overlay {
            if let pending = router.pendingConfirm {
                LedgerConfirmCard(
                    title: pending.title,
                    message: pending.message,
                    confirmTitle: pending.confirmTitle,
                    destructive: pending.destructive,
                    onCancel: { router.pendingConfirm = nil },
                    onConfirm: {
                        let run = pending.run
                        router.pendingConfirm = nil
                        run()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !store.settings.hasSeenOnboarding },
            set: { if !$0 { store.settings.hasSeenOnboarding = true; store.save() } }
        )) {
            OnboardingView {
                store.settings.hasSeenOnboarding = true
                store.save()
            }
            .tint(AppTheme.greenDark)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.flow, title: L10n.tabFlow, mark: "MarkPage")
            tabButton(.monthly, title: L10n.tabMonthly, mark: "MarkChart")
            Button {
                router.openAdd()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.greenSoft)
                        .frame(width: 58, height: 58)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    LedgerMark(symbol: "MarkPlusBold", point: 22, weight: .bold)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(L10n.addTitle)
            tabButton(.assets, title: L10n.tabAssets, mark: "MarkCoin", asset: "TabPiggy")
            tabButton(.settings, title: L10n.tabSettings, mark: "MarkGear")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(AppTheme.card)
    }

    private func tabButton(_ value: RootTab, title: String, mark: String, asset: String? = nil) -> some View {
        let on = router.tab == value
        return Button {
            router.tab = value
        } label: {
            VStack(spacing: 4) {
                Group {
                    if asset != nil {
                        // Outline when idle (matches SF Symbol weight); filled when selected.
                        Image(on ? "TabPiggy" : "TabPiggyOutline")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        LedgerMark(symbol: mark, point: 18)
                    }
                }
                .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textSecondary)
                .frame(width: 40, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(on ? AppTheme.greenSoft : Color.clear)
                )
                Text(title)
                    .font(.system(size: 11, weight: on ? .semibold : .medium))
                    .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
