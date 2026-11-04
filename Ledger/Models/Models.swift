//
//  Models.swift
//  Ledger
//
//  Created by Ketty on 2026/11/03.
//

import Foundation

enum TxType: String, Codable, CaseIterable, Identifiable {
    case expense = "支出"
    case income = "收入"
    case transfer = "转账"
    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .expense: return L10n.expense
        case .income: return L10n.income
        case .transfer: return L10n.transfer
        }
    }
}

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case cash = "现金"
    case bank = "银行卡"
    case credit = "信用卡"
    case wechat = "微信"
    case alipay = "支付宝"
    case stock = "股票"
    case fund = "基金"
    case other = "其他"
    var id: String { rawValue }
    var localizedName: String { L10n.accountKind(rawValue) }
}

struct Account: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var kind: AccountKind
    var openingBalance: Double
    var enabled: Bool = true
    /// When true, balance only changes by manual edit (stocks/funds).
    var manualOnly: Bool = false
    var includeInNetWorth: Bool = true
}

struct Category: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: TxType
    var isEssential: Bool = true
    var canReduce: Bool = false
    var enabled: Bool = true
    var children: [String] = []
    /// Disabled subcategory names (hidden in Add; re-enable in Settings)
    var disabledChildren: [String] = []

    func activeChildren() -> [String] {
        children.filter { !disabledChildren.contains($0) }
    }
}

extension Category: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, isEssential, canReduce, enabled, children, disabledChildren
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(TxType.self, forKey: .type)
        isEssential = try c.decodeIfPresent(Bool.self, forKey: .isEssential) ?? true
        canReduce = try c.decodeIfPresent(Bool.self, forKey: .canReduce) ?? false
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        children = try c.decodeIfPresent([String].self, forKey: .children) ?? []
        disabledChildren = try c.decodeIfPresent([String].self, forKey: .disabledChildren) ?? []
    }
}

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: TxType
    var amount: Double
    var accountId: UUID
    var toAccountId: UUID? = nil
    var categoryId: UUID? = nil
    var subcategory: String? = nil
    var note: String = ""
    var date: Date = Date()
}

struct MonthBudget: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var yearMonth: String // yyyy-MM
    var total: Double = 0
    var categoryCaps: [UUID: Double] = [:]
}

struct AppSettings: Codable, Hashable {
    var languageCode: String = AppLocaleCatalog.defaultLanguageCode
    var currencySymbol: String = AppLocaleCatalog.defaultCurrencySymbol
    var currencyCode: String = AppLocaleCatalog.defaultCurrencyCode
    var reminderEnabled: Bool = false
    var reminderHour: Int = 21
    var reminderMinute: Int = 30
    var hasSeenOnboarding: Bool = false
    /// Savings goal shown on the assets net-worth card.
    var savingsGoal: Double = 0

    enum CodingKeys: String, CodingKey {
        case languageCode, currencySymbol, currencyCode
        case reminderEnabled, reminderHour, reminderMinute
        case hasSeenOnboarding, savingsGoal
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        languageCode = try c.decodeIfPresent(String.self, forKey: .languageCode) ?? AppLocaleCatalog.defaultLanguageCode
        currencySymbol = try c.decodeIfPresent(String.self, forKey: .currencySymbol) ?? AppLocaleCatalog.defaultCurrencySymbol
        currencyCode = try c.decodeIfPresent(String.self, forKey: .currencyCode) ?? AppLocaleCatalog.defaultCurrencyCode
        reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 21
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 30
        hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        savingsGoal = try c.decodeIfPresent(Double.self, forKey: .savingsGoal) ?? 0
    }
}
