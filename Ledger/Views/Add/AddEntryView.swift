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
                    // 对标 Android：类型切换在金额上方
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

            // 对标 Android：白底圆角键盘条钉在底部
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
                    Label(L10n.t("common.back"), systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
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
        // 选账户：对标 Android 底部 sheet；列表用自定义选中 cell
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
        .confirmationDialog(L10n.discardTitle, isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button(L10n.keepEditing, role: .cancel) {}
            Button(L10n.discard, role: .destructive) { router.popFlow() }
        } message: {
            Text(L10n.discardMessage)
        }
        .confirmationDialog(L10n.t("add.delete_confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.t("common.delete"), role: .destructive) {
                if let id = editing?.id {
                    store.deleteTransaction(id)
                }
                router.popFlow()
            }
        }
    }

    var dirty: Bool {
        amountValue > 0 || !note.isEmpty || editing != nil
    }

    var amountValue: Double { Double(amountText) ?? 0 }
}
