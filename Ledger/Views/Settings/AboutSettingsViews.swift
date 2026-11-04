//
//  AboutSettingsViews.swift
//  Ledger
//
//  Created by Ketty on 2026/10/20.
//

import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject private var store: LedgerStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.18)))
                    Text("Ledger")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.greenMuted)
                    Text(L10n.t("settings.about_local_title"))
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    HStack {
                        Text(L10n.t("settings.about_version_label"))
                        Spacer()
                        Text(L10n.t("settings.about_version_value"))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(
                        LinearGradient(colors: [AppTheme.greenDark, AppTheme.green], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )

                Text(L10n.aboutBody)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(Color(red: 0.15, green: 0.55, blue: 0.55))
                            .frame(width: 36, height: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.15, green: 0.55, blue: 0.55).opacity(0.14)))
                        Text(L10n.privacy)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(white: 0.75))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card))
                }

                Button {
                    store.settings.hasSeenOnboarding = false
                    store.save()
                } label: {
                    Text(L10n.t("settings.replay_onboarding"))
                        .font(.headline)
                        .foregroundStyle(AppTheme.greenDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.12))
                        )
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.about)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}

/// Privacy policy: section titles + body, scroll to effective date
struct PrivacyPolicyView: View {
    private let sections: [(titleKey: String, bodyKey: String)] = [
        ("settings.privacy_intro_title", "settings.privacy_intro_body"),
        ("settings.privacy_collect_title", "settings.privacy_collect_body"),
        ("settings.privacy_use_title", "settings.privacy_use_body"),
        ("settings.privacy_third_title", "settings.privacy_third_body"),
        ("settings.privacy_rights_title", "settings.privacy_rights_body")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(sections, id: \.titleKey) { sec in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.t(sec.titleKey))
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(L10n.t(sec.bodyKey))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text(L10n.t("settings.privacy_footer"))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.85))
                    .padding(.top, 8)
            }
            .padding(16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.page.ignoresSafeArea())
        .navigationTitle(L10n.privacy)
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.greenDark)
    }
}
