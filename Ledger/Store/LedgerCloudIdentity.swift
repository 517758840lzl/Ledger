//
//  LedgerCloudIdentity.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import Foundation
import Security

private typealias TaskRef = OpaquePointer

@_silgen_name("SecTaskCreateFromSelf")
private func taskFromSelf(_ allocator: CFAllocator?) -> TaskRef?

@_silgen_name("SecTaskCopyValueForEntitlement")
private func taskCopyValue(
    _ task: TaskRef,
    _ entitlement: CFString,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFTypeRef>?

/// iCloud container, zone, and new local keys follow the app id.
/// Changing PRODUCT_BUNDLE_IDENTIFIER changes these without a code edit.
enum LedgerCloudIdentity {
    static func containerID(bundleID: String) -> String {
        "iCloud.\(bundleID)"
    }

    /// CloudKit throws as soon as the container is missing from the signed entitlements.
    /// Skip that call when this build was not given the container.
    static func declaresContainer(bundleID: String) -> Bool {
        let wanted = containerID(bundleID: bundleID)
        guard let task = taskFromSelf(nil) else { return false }
        defer { Unmanaged<CFTypeRef>.fromOpaque(UnsafeRawPointer(task)).release() }
        guard let owned = taskCopyValue(task, "com.apple.developer.icloud-container-identifiers" as CFString, nil) else {
            return false
        }
        let value = owned.takeRetainedValue()
        guard CFGetTypeID(value) == CFArrayGetTypeID() else { return false }
        let list = value as! CFArray
        for index in 0..<CFArrayGetCount(list) {
            guard let raw = CFArrayGetValueAtIndex(list, index) else { continue }
            let item = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
            if item == wanted { return true }
        }
        return false
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
