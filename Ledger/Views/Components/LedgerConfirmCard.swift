//
//  LedgerConfirmCard.swift
//  Ledger
//
//  Created by Ketty on 2026/11/04.
//

import SwiftUI

/// Centered confirm card. Cancel sits on the left, the action on the right.
struct LedgerConfirmCard: View {
    let title: String
    let message: String
    let confirmTitle: String
    var destructive: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 12) {
                    cardButton(L10n.cancel, filled: Color(white: 0.96), ink: AppTheme.textPrimary, action: onCancel)
                    cardButton(
                        confirmTitle,
                        filled: destructive ? Color(red: 1.0, green: 0.86, blue: 0.84) : AppTheme.greenSoft,
                        ink: destructive ? Color(red: 0.86, green: 0.22, blue: 0.22) : AppTheme.greenDark,
                        action: onConfirm
                    )
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.card))
            .padding(.horizontal, 28)
        }
    }

    private func cardButton(_ title: String, filled: Color, ink: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(filled))
        }
        .buttonStyle(.plain)
    }
}
