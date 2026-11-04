//
//  LedgerCells.swift
//  Ledger
//
//  Created by Ketty on 2026/10/30.
//

import SwiftUI

/// White rounded card container
struct LedgerCard<Content: View>: View {
    var padding: CGFloat = 14
    var radius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(AppTheme.card))
    }
}

/// Outlined field: border + embedded top label
struct LedgerOutlinedField: View {
    let label: String
    let value: String
    var trailingSystemImage: String = "chevron.down"
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(value.isEmpty ? " " : value)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: trailingSystemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .background(AppTheme.card)
                    .offset(x: 10, y: -8)
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

/// Account list cell: avatar + title/subtitle + amount + Edit divider
struct LedgerAccountCell: View {
    let title: String
    let subtitle: String
    let amount: String
    var onTap: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap?()
            } label: {
                HStack(spacing: 12) {
                    Text(String(title.prefix(1)))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.greenDark)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppTheme.greenSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline).foregroundStyle(AppTheme.textPrimary)
                        Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Text(amount)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(white: 0.75))
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if onEdit != nil {
                Divider().padding(.leading, 14)
                Button {
                    onEdit?()
                } label: {
                    Text(L10n.edit)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.black.opacity(0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(14)
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }
}

/// Selectable cell: light green fill + checkmark when selected
struct LedgerSelectCell: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.greenDark)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AppTheme.greenSoft : AppTheme.card)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Flow cell: colored icon + title/subtitle + amount
struct LedgerTxnCell: View {
    let title: String
    let subtitle: String
    let amount: String
    var amountColor: Color = AppTheme.textPrimary
    var iconSystemImage: String? = nil
    var iconForeground: Color = AppTheme.greenDark
    var iconBackground: Color = AppTheme.greenSoft
    var showsChevron: Bool = false
    /// When embedded in a day card, skip own rounded background
    var embedded: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                if let iconSystemImage {
                    Image(systemName: iconSystemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconForeground)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(iconBackground))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Text(amount)
                    .font(.headline)
                    .foregroundStyle(amountColor)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(white: 0.75))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, embedded ? 12 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                if !embedded {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

/// Multiple txs for one day share one white card with inset dividers
struct LedgerTxnDayCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.card))
    }
}

/// Underline text field used in account editor forms
struct LedgerUnderlineField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("", text: $text)
                .keyboardType(keyboard)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
        }
    }
}

struct LedgerPrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(AppTheme.greenDark))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}
