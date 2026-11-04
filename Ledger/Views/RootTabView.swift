import SwiftUI

enum RootTab: Hashable {
    case flow, monthly, add, assets, settings
}

struct RootTabView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter

    /// 对标 Android：二级页（记一笔/账户等）全屏 push，底栏隐藏，避免挡住「保存」
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.page.ignoresSafeArea())

            if showsTabBar {
                tabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsTabBar)
        .tint(AppTheme.greenDark)
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
            tabButton(.flow, title: L10n.tabFlow, system: "doc.text")
            tabButton(.monthly, title: L10n.tabMonthly, system: "chart.xyaxis.line")
            Button {
                router.openAdd()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.greenSoft)
                        .frame(width: 58, height: 58)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(L10n.addTitle)
            tabButton(.assets, title: L10n.tabAssets, system: "dollarsign.circle", asset: "TabPiggy")
            tabButton(.settings, title: L10n.tabSettings, system: "gearshape")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(AppTheme.card)
    }

    private func tabButton(_ value: RootTab, title: String, system: String, asset: String? = nil) -> some View {
        let on = router.tab == value
        return Button {
            router.tab = value
        } label: {
            VStack(spacing: 4) {
                Group {
                    if let asset {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: system)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(width: 40, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(on ? AppTheme.greenSoft : Color.clear)
                )
                Text(title)
                    .font(.system(size: 11, weight: on ? .semibold : .medium))
            }
            .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}
