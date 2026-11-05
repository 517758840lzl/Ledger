//
//  LedgerMark.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import SwiftUI

/// Picture for one symbol, shown at the same point size the system symbol used.
struct LedgerMark: View {
    var symbol: String
    var point: CGFloat = 17
    var weight: Font.Weight = .semibold

    /// Width and height of the semibold symbol at 17pt.
    private static let semibold17: [String: (CGFloat, CGFloat)] = [
        "MarkDown": (18, 21),
        "MarkUp": (18, 21),
        "MarkBag": (20, 21),
        "MarkCash": (26, 17),
        "MarkBasket": (24, 22),
        "MarkBell": (20, 21),
        "MarkBookClosed": (19, 22),
        "MarkBook": (24, 19),
        "MarkTakeout": (30, 22),
        "MarkTransit": (24, 24),
        "MarkCalendar": (22, 19),
        "MarkLetters": (19, 22),
        "MarkTrend": (23, 20),
        "MarkChart": (23, 20),
        "MarkCheck": (19, 18),
        "MarkCard": (24, 18),
        "MarkCross": (24, 20),
        "MarkErase": (22, 19),
        "MarkPage": (19, 22),
        "MarkCoin": (21, 21),
        "MarkEnvelope": (25, 18),
        "MarkDining": (17, 23),
        "MarkPlay": (29, 19),
        "MarkGear": (22, 22),
        "MarkGift": (21, 21),
        "MarkHouse": (25, 22),
        "MarkInfo": (21, 21),
        "MarkHandset": (18, 22),
        "MarkLock": (19, 20),
        "MarkSearch": (21, 20),
        "MarkBubble": (23, 20),
        "MarkPeople": (28, 20),
        "MarkPhone": (20, 19),
        "MarkPlus": (19, 18),
        "MarkPlusCircle": (21, 21),
        "MarkShield": (18, 20),
        "MarkGrid": (22, 20),
        "MarkTag": (23, 23),
        "MarkTrash": (20, 22),
        "MarkTray": (24, 18),
        "MarkWallet": (19, 22),
        "MarkYen": (21, 21),
    ]

    /// Width and height of the regular symbol at 17pt.
    private static let regular17: [String: (CGFloat, CGFloat)] = [
        "MarkDown": (17, 20),
        "MarkUp": (17, 20),
        "MarkBag": (19, 19),
        "MarkCash": (26, 16),
        "MarkBasket": (24, 20),
        "MarkBell": (20, 20),
        "MarkBookClosed": (18, 20),
        "MarkBook": (24, 18),
        "MarkTakeout": (29, 20),
        "MarkTransit": (23, 22),
        "MarkCalendar": (21, 18),
        "MarkLetters": (18, 20),
        "MarkTrend": (22, 18),
        "MarkChart": (22, 18),
        "MarkCheck": (19, 17),
        "MarkCard": (24, 17),
        "MarkCross": (24, 19),
        "MarkErase": (22, 18),
        "MarkPage": (18, 20),
        "MarkCoin": (20, 19),
        "MarkEnvelope": (25, 17),
        "MarkDining": (16, 22),
        "MarkPlay": (28, 18),
        "MarkGear": (21, 20),
        "MarkGift": (20, 20),
        "MarkHouse": (24, 20),
        "MarkInfo": (20, 19),
        "MarkHandset": (17, 20),
        "MarkLock": (18, 19),
        "MarkSearch": (21, 19),
        "MarkBubble": (23, 18),
        "MarkPeople": (27, 19),
        "MarkPhone": (20, 18),
        "MarkPlus": (18, 16),
        "MarkPlusCircle": (20, 19),
        "MarkShield": (18, 19),
        "MarkGrid": (21, 18),
        "MarkTag": (23, 21),
        "MarkTrash": (20, 21),
        "MarkTray": (24, 17),
        "MarkWallet": (18, 20),
        "MarkYen": (20, 19),
    ]

    /// Width and height of the medium symbol at 17pt.
    private static let medium17: [String: (CGFloat, CGFloat)] = [
        "MarkDown": (17, 21),
        "MarkUp": (17, 21),
        "MarkBag": (19, 21),
        "MarkCash": (26, 17),
        "MarkBasket": (24, 22),
        "MarkBell": (19, 21),
        "MarkBookClosed": (19, 21),
        "MarkBook": (24, 19),
        "MarkTakeout": (29, 21),
        "MarkTransit": (23, 23),
        "MarkCalendar": (21, 19),
        "MarkLetters": (19, 21),
        "MarkTrend": (23, 19),
        "MarkChart": (23, 19),
        "MarkCheck": (19, 18),
        "MarkCard": (24, 18),
        "MarkCross": (24, 20),
        "MarkErase": (22, 19),
        "MarkPage": (19, 21),
        "MarkCoin": (21, 21),
        "MarkEnvelope": (25, 18),
        "MarkDining": (16, 23),
        "MarkPlay": (29, 19),
        "MarkGear": (22, 21),
        "MarkGift": (21, 21),
        "MarkHouse": (25, 21),
        "MarkInfo": (21, 21),
        "MarkHandset": (18, 22),
        "MarkLock": (19, 20),
        "MarkSearch": (21, 20),
        "MarkBubble": (23, 20),
        "MarkPeople": (27, 20),
        "MarkPhone": (20, 19),
        "MarkPlus": (18, 17),
        "MarkPlusCircle": (21, 21),
        "MarkShield": (18, 20),
        "MarkGrid": (21, 20),
        "MarkTag": (23, 23),
        "MarkTrash": (20, 22),
        "MarkTray": (24, 18),
        "MarkWallet": (19, 21),
        "MarkYen": (21, 21),
    ]

    /// These five stay as system glyphs. Call sites use the Mark name.
    private static let symbolByMark: [String: String] = [
        "MarkColumns": "building.columns.fill",
        "MarkChevronLeft": "chevron.left",
        "MarkChevronRight": "chevron.right",
        "MarkChevronDown": "chevron.down",
        "MarkSwap": "arrow.left.arrow.right",
    ]

    var body: some View {
        if let glyph = Self.symbolByMark[symbol] {
            Image(systemName: glyph)
                .font(.system(size: point, weight: weight))
        } else {
            let box = laidOutSize
            Image(symbol)
                .renderingMode(.template)
                .resizable()
                .frame(width: box.width, height: box.height)
        }
    }

    /// Symbol bounds at this point size, scaled from the 17pt measurement.
    private var laidOutSize: CGSize {
        if symbol == "MarkPlusBold" {
            let scale = point / 22
            return CGSize(width: 24 * scale, height: 23 * scale)
        }
        let table: [String: (CGFloat, CGFloat)]
        if weight == .regular {
            table = Self.regular17
        } else if weight == .medium {
            table = Self.medium17
        } else {
            table = Self.semibold17
        }
        let pair = table[symbol] ?? (17, 17)
        let scale = point / 17
        return CGSize(width: pair.0 * scale, height: pair.1 * scale)
    }
}
