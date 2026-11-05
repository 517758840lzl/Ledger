//
//  AddEntryView.swift
//  Ledger
//
//  Created by Ketty on 2026/11/03.
//

import SwiftUI
import UIKit

struct AddEntryView: View {
    @EnvironmentObject var store: LedgerStore
    @EnvironmentObject var router: AppRouter

    var editing: Transaction? = nil
    var presetDate: Date? = nil

    @State var type: TxType = .expense
    @State var amountText = "0"
    @State var note = ""
    @State var accountId: UUID?
    @State var toAccountId: UUID?
    @State var categoryId: UUID?
    @State var subcategory: String?
    @State var date = Date()
    @State var showAccountPicker = false
    @State var pickingTo = false
    @State var showDate = false
    @State var confirmDiscard = false
    @State var showAddSub = false
    @State var newSubName = ""
    @State var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // Type switch sits above the amount
                    typePicker
                    amountCard
                    detailsCard
                    if type != .transfer {
                        categorySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            // White rounded keypad bar pinned to the bottom
            keypad
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.card)
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .background(AppTheme.page)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(editing == nil ? L10n.addTitle : L10n.txDetail)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .tint(AppTheme.greenDark)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    if dirty { confirmDiscard = true } else { router.popFlow() }
                } label: {
                    LedgerMark(symbol: "MarkChevronLeft", point: 17)
                        .accessibilityLabel(L10n.t("common.back"))
                }
            }
            if editing != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("common.delete"), role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
        }
        .onAppear(perform: bootstrap)
        // Account picker as bottom sheet with custom selected cells
            .sheet(isPresented: $showAccountPicker) {
            AccountPickerSheet(
                accounts: store.enabledAccounts(),
                title: pickingTo ? L10n.toAccount : (type == .expense ? L10n.payAccount : L10n.receiveAccount),
                selectedId: pickingTo ? toAccountId : accountId
            ) { acc in
                if pickingTo { toAccountId = acc.id } else { accountId = acc.id }
            }
            .environmentObject(store)
            .environmentObject(router)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDate) {
            NavigationStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle(L10n.date)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.done) { showDate = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: confirmDiscard) { _, show in
            guard show else { return }
            confirmDiscard = false
            router.pendingConfirm = PendingConfirm(
                title: L10n.discardTitle,
                message: L10n.discardMessage,
                confirmTitle: L10n.discard,
                run: { router.popFlow() }
            )
        }
        .onChange(of: confirmDelete) { _, show in
            guard show else { return }
            confirmDelete = false
            router.pendingConfirm = PendingConfirm(
                title: L10n.t("add.delete_confirm"),
                confirmTitle: L10n.t("common.delete"),
                run: {
                    if let id = editing?.id {
                        store.deleteTransaction(id)
                    }
                    router.popFlow()
                }
            )
        }
    }

    var dirty: Bool {
        guard let editing else {
            return amountValue > 0 || !note.isEmpty
        }
        return type != editing.type
            || amountValue != editing.amount
            || note != editing.note
            || accountId != editing.accountId
            || toAccountId != editing.toAccountId
            || categoryId != editing.categoryId
            || subcategory != editing.subcategory
            || !Calendar.current.isDate(date, inSameDayAs: editing.date)
    }

    var amountValue: Double { Double(amountText) ?? 0 }
}
