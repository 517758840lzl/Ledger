//
//  OnboardingView.swift
//  Ledger
//
//  Created by Ketty on 2026/10/07.
//

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    private var pages: [GuidePage] {
        [
            GuidePage(id: 0, title: L10n.onboard3Title, body: L10n.onboard3Body),
            GuidePage(id: 1, title: L10n.onboard2Title, body: L10n.onboard2Body),
            GuidePage(id: 2, title: L10n.onboard1Title, body: L10n.onboard1Body)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onFinish) {
                    Text(L10n.onboardSkip)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboard.skip")
            }
            .padding(.top, 4)
            .padding(.trailing, 8)

            TabView(selection: $page) {
                ForEach(pages) { item in
                    guidePage(item)
                        .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: page)

            Button(action: goForward) {
                Text(page == pages.count - 1 ? L10n.onboardStart : L10n.onboardNext)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.greenDark))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("onboard.next")
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(AppTheme.page.ignoresSafeArea())
    }

    private func goForward() {
        guard page < pages.count - 1 else {
            onFinish()
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            page += 1
        }
    }

    private func guidePage(_ item: GuidePage) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.greenDark)
                    .frame(width: 88, height: 88)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppTheme.greenSoft)
            }
            Text("Ledger")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.greenDark)
            Text(item.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("onboard.title.\(item.id)")
            Text(item.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
    }
}

private struct GuidePage: Identifiable {
    let id: Int
    let title: String
    let body: String
}
