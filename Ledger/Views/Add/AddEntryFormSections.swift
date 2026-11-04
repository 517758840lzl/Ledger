//
//  AddEntryFormSections.swift
//  Ledger
//
//  Created by Ketty on 2026/10/09.
//

import SwiftUI

extension AddEntryView {
    var typePicker: some View {
        HStack(spacing: 0) {
            ForEach(TxType.allCases) { t in
                Text(t.localizedName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(type == t ? AppTheme.greenDark : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Capsule().fill(type == t ? Color.white : Color.clear))
                    .contentShape(Rectangle())
                    .onTapGesture { applyType(t) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(t.localizedName)
                    .accessibilityIdentifier("add.type.\(t.rawValue)")
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.06)))
    }

    func applyType(_ t: TxType) {
        type = t
        subcategory = nil
        if t == .transfer {
            categoryId = nil
            toAccountId = store.enabledAccounts().dropFirst().first?.id ?? accountId
        } else {
            categoryId = store.categories(for: t).first?.id
        }
    }

    var amountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.settings.currencySymbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(type == .income ? AppTheme.incomeAmount : AppTheme.textSecondary)
                Text(amountText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(type == .income ? AppTheme.incomeAmount : AppTheme.textPrimary)
                Spacer()
            }
            if amountValue <= 0 {
                Text(L10n.t("add.amount_hint")).font(.caption).foregroundStyle(.red)
            }
            if type == .transfer, accountId != nil, accountId == toAccountId {
                Text(L10n.t("add.transfer_same_account")).font(.caption).foregroundStyle(.red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
    }

    var detailsCard: some View {
        VStack(spacing: 14) {
            if type == .transfer {
                HStack(spacing: 10) {
                    transferPick(
                        title: L10n.fromAccount,
                        value: store.account(id: accountId ?? UUID())?.name.ledgerText ?? L10n.cash
                    ) { pickingTo = false; showAccountPicker = true }
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(AppTheme.greenDark)
                    transferPick(
                        title: L10n.toAccount,
                        value: store.account(id: toAccountId ?? UUID())?.name.ledgerText ?? L10n.select
                    ) { pickingTo = true; showAccountPicker = true }
                }
            } else {
                LedgerOutlinedField(
                    label: type == .expense ? L10n.payAccount : L10n.receiveAccount,
                    value: store.account(id: accountId ?? UUID())?.name.ledgerText ?? L10n.cash
                ) {
                    pickingTo = false
                    showAccountPicker = true
                }
            }
            LedgerOutlinedField(
                label: L10n.date,
                value: Calendar.current.isDateInToday(date) ? L10n.today : mediumDate(date),
                trailingSystemImage: "calendar"
            ) {
                showDate = true
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L10n.noteOptional)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .background(AppTheme.card)
                        .offset(x: 10, y: 8)
                        .zIndex(1)
                    Spacer()
                    Text("\(note.count)/80")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.trailing, 12)
                        .offset(y: 8)
                }
                TextField(type == .income ? L10n.noteHintIncome : L10n.noteHintExpense, text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.14), lineWidth: 1)
                    )
                    .onChange(of: note) { _, v in if v.count > 80 { note = String(v.prefix(80)) } }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
    }

    var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.category).font(.headline)
            let cats = store.categories(for: type)
            // Horizontal circular icons; selected gets dark green stroke
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(cats) { cat in
                        let on = categoryId == cat.id
                        let visual = CategoryVisual.style(categoryName: cat.name, type: type)
                        Button {
                            categoryId = cat.id
                            subcategory = nil
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: visual.systemImage)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(on ? AppTheme.greenDark : visual.foreground)
                                    .frame(width: 52, height: 52)
                                    .background(Circle().fill(on ? AppTheme.greenSoft : visual.background))
                                    .overlay(
                                        Circle()
                                            .stroke(on ? AppTheme.greenDark : Color.clear, lineWidth: 2.5)
                                    )
                                Text(cat.name.ledgerText)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(on ? AppTheme.greenDark : AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 64)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            if let cat = store.category(id: categoryId) {
                let tags = cat.activeChildren()
                if !tags.isEmpty || type == .expense {
                    Text(L10n.subcategoryHint)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    subcategory = (subcategory == tag) ? nil : tag
                                } label: {
                                    Text(tag.ledgerText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(subcategory == tag ? AppTheme.greenDark : AppTheme.card)
                                                .overlay(
                                                    Capsule().stroke(
                                                        subcategory == tag ? Color.clear : Color.black.opacity(0.12),
                                                        lineWidth: 1
                                                    )
                                                )
                                        )
                                        .foregroundStyle(subcategory == tag ? Color.white : AppTheme.textPrimary)
                                }
                            }
                            Button {
                                newSubName = ""
                                showAddSub = true
                            } label: {
                                Text(L10n.t("add.add_subtag"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().stroke(AppTheme.greenMuted.opacity(0.55)))
                            }
                            .foregroundStyle(AppTheme.greenDark)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSub) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        LedgerCard {
                            LedgerUnderlineField(label: L10n.childPlaceholder, text: $newSubName)
                        }
                        LedgerPrimaryButton(title: L10n.confirm) {
                            let trimmed = newSubName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty, let cid = categoryId else { return }
                            store.addSubcategory(to: cid, name: trimmed)
                            subcategory = trimmed
                            showAddSub = false
                        }
                        .opacity(newSubName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                        .disabled(newSubName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                }
                .background(AppTheme.page.ignoresSafeArea())
                .navigationTitle(L10n.addSubcategory)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.cancel) { showAddSub = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    var keypad: some View {
        VStack(spacing: 8) {
            ForEach([["1","2","3","⌫"],["4","5","6","."],["7","8","9","00"]], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
            HStack(spacing: 8) {
                keyButton("0")
                Button(L10n.t("add.add_another")) { save(keepOpen: true) }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.greenMuted))
                    .foregroundStyle(AppTheme.greenDark)
                Button(L10n.save) { save(keepOpen: false) }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.greenDark))
                    .foregroundStyle(.white)
            }
        }
        .padding(.bottom, 8)
    }

    func keyButton(_ key: String) -> some View {
        let soft = (key == "⌫" || key == "00")
        return Button {
            press(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.title3.weight(.semibold))
                } else {
                    Text(key).font(.title3.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(soft ? AppTheme.greenSoft : AppTheme.card)
            )
            .foregroundStyle(AppTheme.textPrimary)
        }
    }

    func press(_ key: String) {
        if key == "⌫" {
            if amountText.count <= 1 { amountText = "0" } else { amountText.removeLast() }
            return
        }
        if key == "." {
            if !amountText.contains(".") { amountText += "." }
            return
        }
        if amountText == "0" && key != "00" { amountText = key; return }
        if key == "00" {
            if amountText == "0" { return }
            amountText += "00"
            return
        }
        let parts = amountText.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 2, parts[1].count >= 2 { return }
        amountText += key
    }

    func bootstrap() {
        if let editing {
            type = editing.type
            amountText = String(format: "%g", editing.amount)
            note = editing.note
            accountId = editing.accountId
            toAccountId = editing.toAccountId
            categoryId = editing.categoryId
            subcategory = editing.subcategory
            date = editing.date
        } else {
            accountId = store.enabledAccounts().first?.id
            toAccountId = store.enabledAccounts().dropFirst().first?.id ?? store.enabledAccounts().first?.id
            categoryId = store.categories(for: .expense).first?.id
            if let presetDate { date = presetDate }
        }
    }

    func save(keepOpen: Bool) {
        guard amountValue > 0, let accountId else { return }
        if type == .transfer, toAccountId == nil || toAccountId == accountId { return }
        var tx = editing ?? Transaction(type: type, amount: amountValue, accountId: accountId)
        tx.type = type
        tx.amount = amountValue
        tx.accountId = accountId
        tx.toAccountId = type == .transfer ? toAccountId : nil
        tx.categoryId = type == .transfer ? nil : categoryId
        tx.subcategory = subcategory
        tx.note = note
        tx.date = date
        if editing == nil { store.addTransaction(tx) } else { store.updateTransaction(tx) }
        if keepOpen {
            amountText = "0"; note = ""; subcategory = nil
        } else {
            // Path-driven stack must pop path; dismiss() often leaves Add visible
            router.popFlow()
        }
    }

    func row(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(value).foregroundStyle(AppTheme.textPrimary)
                Image(systemName: "chevron.down").font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    func transferPick(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary)
                HStack {
                    Text(value).foregroundStyle(AppTheme.textPrimary).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func mediumDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = AppLocaleCatalog.locale(for: store.settings.languageCode)
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f.string(from: d)
    }
}
