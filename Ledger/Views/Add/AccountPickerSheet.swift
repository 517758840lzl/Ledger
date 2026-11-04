import SwiftUI

struct AccountPickerSheet: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var router: AppRouter
    let accounts: [Account]
    let title: String
    let onPick: (Account) -> Void
    var selectedId: UUID? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(accounts) { acc in
                        LedgerSelectCell(title: acc.name, selected: acc.id == selectedId) {
                            onPick(acc)
                            dismiss()
                        }
                    }
                    Button {
                        dismiss()
                        router.tab = .settings
                        router.settingsPath.append(SettingsRoute.accountNew)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text(L10n.t("settings.add_account"))
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.greenDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.greenMuted.opacity(0.45))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
