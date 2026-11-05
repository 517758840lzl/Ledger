//
//  LedgerCloudIdentity.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation

/// iCloud container, zone, and new local keys follow the app id.
/// Changing PRODUCT_BUNDLE_IDENTIFIER changes these without a code edit.
enum LedgerCloudIdentity {
    static func containerID(bundleID: String) -> String {
        "iCloud.\(bundleID)"
    }

    static func zoneName(bundleID: String) -> String {
        bundleID
    }

    static func localKey(_ name: String, bundleID: String) -> String {
        "\(bundleID).\(name)"
    }

    static var currentBundleID: String {
        Bundle.main.bundleIdentifier ?? "app"
    }
}
