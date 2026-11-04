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

    private var pages: [(title: String, body: String)] {
        [
            (L10n.onboard3Title, L10n.onboard3Body),
            (L10n.onboard2Title, L10n.onboard2Body),
            (L10n.onboard1Title, L10n.onboard1Body)
        ]
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(L10n.onboardSkip) { onFinish() }
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
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
            Text(pages[page].title)
                .font(.title2.bold())
            Text(pages[page].body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 28)
            Spacer()
            Button(page == pages.count - 1 ? L10n.onboardStart : L10n.onboardNext) {
                if page < pages.count - 1 { page += 1 } else { onFinish() }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.greenDark))
            .foregroundStyle(.white)
        }
        .padding(20)
        .background(AppTheme.page.ignoresSafeArea())
    }
}
