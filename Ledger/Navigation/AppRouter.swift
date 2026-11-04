import SwiftUI
import Combine

enum FlowRoute: Hashable {
    case add
    case edit(UUID)
    case calendar
    case history
    case month(String)
}

enum MonthlyRoute: Hashable {
    case budget(String)
    case categoryDetail(UUID, String)
    case canReduceSettings
}

enum AssetsRoute: Hashable {
    case editor
    case formNew(AccountKind)
    case formEdit(UUID)
}

enum SettingsRoute: Hashable {
    case accounts
    case accountNew
    case accountEdit(UUID)
    case accountHistory(UUID)
    case categories
    case categoryAddTop(TxType)
    case categoryAddChild(UUID)
    case export
    case importData
    case language
    case currency
    case reminder
    case about
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var tab: RootTab = .flow
    @Published var flowPath = NavigationPath()
    @Published var monthlyPath = NavigationPath()
    @Published var assetsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    /// 中央 + ：切到流水 Tab 并 push 记一笔（不是 modal）
    func openAdd(presetDate: Date? = nil) {
        pendingPresetDate = presetDate
        tab = .flow
        // 避免重复 push 叠多层「记一笔」，保存/返回后路径对不上
        flowPath = NavigationPath()
        flowPath.append(FlowRoute.add)
    }

    func openEdit(transactionId: UUID) {
        tab = .flow
        flowPath.append(FlowRoute.edit(transactionId))
    }

    /// 记一笔 / 详情退出：必须改 path，单靠 dismiss() 在 path 驱动的 NavigationStack 上常弹不干净
    func popFlow() {
        guard !flowPath.isEmpty else { return }
        flowPath.removeLast()
    }

    func popSettings() {
        guard !settingsPath.isEmpty else { return }
        settingsPath.removeLast()
    }

    /// 记一笔可选预填日期（日历空日 CTA）
    var pendingPresetDate: Date?
}
