//
//  CategoriesSettingsViews.swift
//  Ledger
//
//  Created by Ketty on 2026/10/20.
//

import SwiftUI

struct CategoriesSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    @State private var segment: TxType = .expense

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                Text(L10n.expense).tag(TxType.expense)
                Text(L10n.income).tag(TxType.income)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.categoriesForSettings(type: segment)) { cat in
                        categoryCard(cat)
                    }
                    Button {
                        router.settingsPath.append(SettingsRoute.categoryAddTop(segment))
                    } label: {
                        Text(L10n.t("settings.add_top_category"))
                            .font(.headline)
                            .foregroundStyle(AppTheme.greenDark)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.greenMuted.opacity(0.55))
                            )
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.categories)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func categoryCard(_ cat: Category) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cat.name.ledgerText)
                .font(.title3.weight(.bold))
                .foregroundStyle(cat.enabled ? AppTheme.textPrimary : AppTheme.textSecondary)

            if segment == .expense {
                HStack(spacing: 8) {
                    flagPill(L10n.essential, on: cat.isEssential) {
                        store.setCategoryEssential(cat.id, value: !cat.isEssential)
                    }
                    flagPill(L10n.canReduce, on: cat.canReduce) {
                        store.setCategoryCanReduce(cat.id, value: !cat.canReduce)
                    }
                    flagPill(cat.enabled ? L10n.t("settings.disable") : L10n.t("settings.enable"), on: !cat.enabled) {
                        store.setCategoryEnabled(cat.id, value: !cat.enabled)
                    }
                }
            } else {
                HStack {
                    flagPill(cat.enabled ? L10n.t("settings.disable") : L10n.t("settings.enable"), on: !cat.enabled) {
                        store.setCategoryEnabled(cat.id, value: !cat.enabled)
                    }
                }
            }

            Button {
                router.settingsPath.append(SettingsRoute.categoryAddChild(cat.id))
            } label: {
                Text(L10n.addSubcategory)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.greenDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().stroke(AppTheme.greenMuted.opacity(0.5)))
            }

            if !cat.children.isEmpty {
                Divider()
                ForEach(cat.children, id: \.self) { child in
                    let childOn = !cat.disabledChildren.contains(child)
                    HStack {
                        Text(child.ledgerText)
                            .foregroundStyle(childOn ? AppTheme.textPrimary : AppTheme.textSecondary)
                        Spacer()
                        Button(childOn ? L10n.t("settings.disable") : L10n.t("settings.enable")) {
                            store.setChildEnabled(categoryId: cat.id, child: child, enabled: !childOn)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.greenDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(AppTheme.greenMuted.opacity(0.45)))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
        .opacity(cat.enabled ? 1 : 0.72)
    }

    private func flagPill(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(on ? AppTheme.greenSoft : AppTheme.card))
                .overlay(Capsule().stroke(on ? AppTheme.greenMuted.opacity(0.2) : Color.black.opacity(0.12)))
                .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textPrimary)
        }
    }
}

enum CategoryNameEditorMode {
    case top(TxType)
    case child(Category)
}

struct CategoryNameEditorView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let mode: CategoryNameEditorMode
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if case .child(let cat) = mode {
                    LedgerCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.parentCategory)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(cat.name.ledgerText)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                LedgerCard {
                    LedgerUnderlineField(
                        label: {
                            switch mode {
                            case .top: return L10n.t("settings.category_name")
                            case .child: return L10n.childName
                            }
                        }(),
                        text: $name
                    )
                }
                LedgerPrimaryButton(title: L10n.confirm) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    switch mode {
                    case .top(let type):
                        store.addTopCategory(name: LedgerText.canonical(trimmed), type: type)
                    case .child(let cat):
                        store.addSubcategory(to: cat.id, name: LedgerText.canonical(trimmed))
                    }
                    dismiss()
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle({
            switch mode {
            case .top: return L10n.t("settings.add_top_category")
            case .child: return L10n.addSubcategory
            }
        }())
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}
