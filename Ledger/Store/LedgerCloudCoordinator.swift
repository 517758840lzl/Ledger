//
//  LedgerCloudCoordinator.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation
import UIKit

/// Pulls the private book when iCloud is reachable, then pushes local edits.
/// A missing iCloud account leaves the database untouched.
final class LedgerCloudCoordinator {
    private let book: LedgerBookDatabase
    private let bundleID: String
    private let onChange: () -> Void
    private var syncing = false
    private var queued = false
    private var observer: NSObjectProtocol?

    init(book: LedgerBookDatabase, bundleID: String, onChange: @escaping () -> Void) {
        self.book = book
        self.bundleID = bundleID
        self.onChange = onChange
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.requestSync()
            }
        }
        requestSync()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func requestSync() {
        if syncing {
            queued = true
            return
        }
        syncing = true
        Task { await self.performSync() }
    }

    private func performSync() async {
        guard let mirror = LedgerCloudMirror(bundleID: bundleID) else {
            finishSync()
            return
        }
        let fetched = await mirror.fetch(since: book.changeTokenData())
        if case .synced(let payload, let token, let hasChanges) = fetched {
            var changed = false
            if hasChanges && book.origin == "seed" {
                book.replace(with: payload)
                book.setOrigin("cloud")
                changed = true
            } else if hasChanges && book.merge(payload) {
                changed = true
            }
            if !token.isEmpty {
                book.setChangeTokenData(token)
            }
            if changed { onChange() }
            if book.origin != "seed" {
                await mirror.push(book.makePayload())
            }
        }
        finishSync()
    }

    private func finishSync() {
        syncing = false
        if queued {
            queued = false
            requestSync()
        }
    }
}
