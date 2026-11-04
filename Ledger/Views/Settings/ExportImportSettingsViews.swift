import SwiftUI
import UniformTypeIdentifiers

struct ExportSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.20, green: 0.40, blue: 0.85))
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.20, green: 0.40, blue: 0.85).opacity(0.14)))
                    Text(L10n.t("settings.export_body"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.card))

                Button {
                    message = shareExport() ? L10n.exportStarted : L10n.exportFailed
                } label: {
                    Text(L10n.exportCSV)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.greenDark))
                        .foregroundStyle(.white)
                }
                Button {
                    message = L10n.exportExcelNote
                    _ = shareExport()
                } label: {
                    Text(L10n.exportExcel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.greenDark))
                        .foregroundStyle(.white)
                }
                if !message.isEmpty {
                    Text(message).font(.footnote).foregroundStyle(AppTheme.greenDark)
                }
            }
            .padding(16)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.export)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }

    private func shareExport() -> Bool {
        guard let url = store.exportFullCSV() else { return false }
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController {
            root.present(av, animated: true)
            return true
        }
        return false
    }
}

struct ImportSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var pendingConfirm = false
    @State private var showPicker = false
    @State private var importMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "arrow.up.to.line")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.greenDark)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.greenSoft))
                    Text(L10n.t("settings.import_hint"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.card))

                Button { pendingConfirm = true } label: {
                    Text(L10n.t("settings.load_sample"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.greenDark))
                        .foregroundStyle(.white)
                }
                Button { showPicker = true } label: {
                    Text(L10n.t("settings.choose_export_file"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.12))
                        )
                        .foregroundStyle(AppTheme.greenDark)
                }
                if !importMessage.isEmpty {
                    Text(importMessage).font(.footnote).foregroundStyle(AppTheme.greenDark)
                }
            }
            .padding(16)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.t("settings.import"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
        .confirmationDialog(L10n.importConfirm, isPresented: $pendingConfirm, titleVisibility: .visible) {
            Button(L10n.confirm) { store.loadSampleBills() }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.t("settings.import_sample_detail"))
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.commaSeparatedText, .plainText, .html]) { result in
            switch result {
            case .success(let url):
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    let n = store.importCSV(text: text)
                    importMessage = String(format: L10n.t("settings.import_result"), n)
                } else {
                    importMessage = L10n.t("settings.import_failed")
                }
            case .failure:
                importMessage = L10n.t("settings.import_failed")
            }
        }
    }
}
