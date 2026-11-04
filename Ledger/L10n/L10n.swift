//
//  L10n.swift
//  Ledger
//
//  Created by Ketty on 2026/10/26.
//

import Foundation

/// Typed localization keys. Prefer `L10n.xxx` over string literals in UI.
enum L10n {
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    // Tabs
    static var tabFlow: String { t("tab.flow") }
    static var tabMonthly: String { t("tab.monthly") }
    static var tabAssets: String { t("tab.assets") }
    static var tabSettings: String { t("tab.settings") }

    // Common
    static var save: String { t("common.save") }
    static var cancel: String { t("common.cancel") }
    static var done: String { t("common.done") }
    static var edit: String { t("common.edit") }
    static var delete: String { t("common.delete") }
    static var confirm: String { t("common.confirm") }
    static var discard: String { t("common.discard") }
    static var keepEditing: String { t("common.keep_editing") }
    static var today: String { t("common.today") }
    static var search: String { t("common.search") }
    static var optional: String { t("common.optional") }

    // Types
    static var expense: String { t("type.expense") }
    static var income: String { t("type.income") }
    static var transfer: String { t("type.transfer") }

    // Flow
    static var flowTitle: String { t("flow.title") }
    static var historyBills: String { t("flow.history") }
    static var calendarTitle: String { t("flow.calendar") }
    static var searchPlaceholder: String { t("flow.search_placeholder") }
    static var emptyFlow: String { t("flow.empty") }

    // Add
    static var addTitle: String { t("add.title") }
    static var txDetail: String { t("add.detail") }
    static var payAccount: String { t("add.pay_account") }
    static var receiveAccount: String { t("add.receive_account") }
    static var fromAccount: String { t("add.from_account") }
    static var toAccount: String { t("add.to_account") }
    static var date: String { t("add.date") }
    static var noteOptional: String { t("add.note_optional") }
    static var noteHintExpense: String { t("add.note_hint_expense") }
    static var noteHintIncome: String { t("add.note_hint_income") }
    static var category: String { t("add.category") }
    static var subcategoryHint: String { t("add.subcategory_hint") }
    static var discardTitle: String { t("add.discard_title") }
    static var discardMessage: String { t("add.discard_message") }
    static var select: String { t("add.select") }
    static var cash: String { t("account.cash") }

    // Monthly
    static var monthlyTitle: String { t("monthly.title") }
    static var budget: String { t("monthly.budget") }
    static var setBudget: String { t("monthly.set_budget") }
    static var canReduce: String { t("monthly.can_reduce") }
    static var essential: String { t("monthly.essential") }
    static var expenseShare: String { t("monthly.expense_share") }
    static var reduceHint: String { t("monthly.reduce_hint") }
    static var categoryBudgetOptional: String { t("monthly.category_budget_optional") }

    // Assets
    static var assetsTitle: String { t("assets.title") }
    static var fillAssets: String { t("assets.fill") }
    static var goFillAssets: String { t("assets.go_fill") }
    static var netWorth: String { t("assets.net_worth") }
    static var netWorthFootnote: String { t("assets.net_worth_footnote") }
    static var sources: String { t("assets.sources") }
    static var manualOnly: String { t("assets.manual_only") }
    static var followLedger: String { t("assets.follow_ledger") }
    static var assetsStats: String { t("assets.stats") }
    static var featureBoard: String { t("assets.feature_board") }
    static var featureBoardBody: String { t("assets.feature_board_body") }
    static var featureAuto: String { t("assets.feature_auto") }
    static var featureAutoBody: String { t("assets.feature_auto_body") }
    static var featureLocal: String { t("assets.feature_local") }
    static var featureLocalBody: String { t("assets.feature_local_body") }
    static var featureNoCard: String { t("assets.feature_nocard") }
    static var featureNoCardBody: String { t("assets.feature_nocard_body") }
    static var assetsStockHint: String { t("assets.stock_hint") }
    static var assetsEditorHint: String { t("assets.editor_hint") }
    static var addBank: String { t("assets.add_bank") }
    static var addWechatAlipay: String { t("assets.add_wechat_alipay") }
    static var addStockFund: String { t("assets.add_stock_fund") }
    static var addSource: String { t("assets.add_source") }
    static var newSource: String { t("assets.new_source") }
    static var editSource: String { t("assets.edit_source") }
    static var sourceType: String { t("assets.source_type") }
    static var sourceName: String { t("assets.source_name") }
    static var currentBalance: String { t("assets.current_balance") }
    static var currentDebt: String { t("assets.current_debt") }
    static var includeNetWorth: String { t("assets.include_net_worth") }
    static var manualFooterStock: String { t("assets.manual_footer_stock") }
    static var manualFooterDefault: String { t("assets.manual_footer_default") }

    // Settings
    static var settingsTitle: String { t("settings.title") }
    static var accounts: String { t("settings.accounts") }
    static var categories: String { t("settings.categories") }
    static var export: String { t("settings.export") }
    static var importSample: String { t("settings.import_sample") }
    static var clearLocal: String { t("settings.clear_local") }
    static var language: String { t("settings.language") }
    static var currency: String { t("settings.currency") }
    static var reminder: String { t("settings.reminder") }
    static var about: String { t("settings.about") }
    static var privacy: String { t("settings.privacy") }
    static var addSubcategory: String { t("settings.add_subcategory") }
    static var parentCategory: String { t("settings.parent_category") }
    static var childName: String { t("settings.child_name") }
    static var childPlaceholder: String { t("settings.child_placeholder") }
    static var exportHint: String { t("settings.export_hint") }
    static var exportCSV: String { t("settings.export_csv") }
    static var exportExcel: String { t("settings.export_excel") }
    static var exportStarted: String { t("settings.export_started") }
    static var exportFailed: String { t("settings.export_failed") }
    static var exportExcelNote: String { t("settings.export_excel_note") }
    static var importConfirm: String { t("settings.import_confirm") }
    static var aboutBody: String { t("settings.about_body") }

    // Onboarding (product only — no ads)
    static var onboardSkip: String { t("onboard.skip") }
    static var onboardNext: String { t("onboard.next") }
    static var onboardStart: String { t("onboard.start") }
    static var onboard1Title: String { t("onboard.1.title") }
    static var onboard1Body: String { t("onboard.1.body") }
    static var onboard2Title: String { t("onboard.2.title") }
    static var onboard2Body: String { t("onboard.2.body") }
    static var onboard3Title: String { t("onboard.3.title") }
    static var onboard3Body: String { t("onboard.3.body") }

    // Account kinds
    static func accountKind(_ raw: String) -> String {
        switch raw {
        case "现金": return t("kind.cash")
        case "银行卡": return t("kind.bank")
        case "信用卡": return t("kind.credit")
        case "微信": return t("kind.wechat")
        case "支付宝": return t("kind.alipay")
        case "股票": return t("kind.stock")
        case "基金": return t("kind.fund")
        default: return t("kind.other")
        }
    }
}
