//
//  AppRouter.swift
//  Ledger
//
//  Created by Ketty on 2026/10/14.
//

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

    /// Center + : switch to Flow and push Add (not a modal)
    func openAdd(presetDate: Date? = nil) {
        pendingPresetDate = presetDate
        tab = .flow
        // Reset path so Save/Back cannot stack multiple Add screens
        flowPath = NavigationPath()
        flowPath.append(FlowRoute.add)
    }

    func openEdit(transactionId: UUID) {
        tab = .flow
        flowPath.append(FlowRoute.edit(transactionId))
    }

    /// Pop via path; dismiss() often fails to leave path-driven stacks
    func popFlow() {
        guard !flowPath.isEmpty else { return }
        flowPath.removeLast()
    }

    func popSettings() {
        guard !settingsPath.isEmpty else { return }
        settingsPath.removeLast()
    }

    func popAssets() {
        guard !assetsPath.isEmpty else { return }
        assetsPath.removeLast()
    }

    /// Optional preset date from the calendar empty-day CTA
    var pendingPresetDate: Date?
}
