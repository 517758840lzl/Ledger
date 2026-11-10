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

    /// CloudKit throws as soon as the container is missing from the signed entitlements.
    /// Skip that call when this build was not given the container.
    static func declaresContainer(bundleID: String) -> Bool {
        let wanted = containerID(bundleID: bundleID)
        guard let url = Bundle.main.executableURL,
              let bytes = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return false
        }
        return containerIdentifiers(inExecutable: bytes).contains(wanted)
    }

    /// Container ids embedded in a Mach-O code signature. Empty when the slice has none.
    static func containerIdentifiers(inExecutable bytes: Data) -> [String] {
        guard let xml = entitlementXML(in: bytes),
              let root = try? PropertyListSerialization.propertyList(from: xml, format: nil),
              let dict = root as? [String: Any],
              let list = dict[containerEntitlement] as? [String] else {
            return []
        }
        return list
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

    private static let containerEntitlement = "com.apple.developer.icloud-container-identifiers"
}

/// Reads the entitlements plist stored in a thin 64-bit executable.
/// App Store builds cannot call the private task symbols that used to do this.
private func entitlementXML(in bytes: Data) -> Data? {
    guard u32LE(bytes, 0) == 0xFEEDFACF, let commandCount = u32LE(bytes, 16), commandCount <= 512 else {
        return nil
    }
    var cursor = 32
    var signatureOffset: Int?
    var signatureSize: Int?
    for _ in 0..<commandCount {
        guard let command = u32LE(bytes, cursor),
              let commandSize = u32LE(bytes, cursor + 4),
              commandSize >= 8,
              let next = advance(cursor, Int(commandSize), limit: bytes.count) else {
            return nil
        }
        if command == 0x1D,
           commandSize >= 16,
           let dataOffset = u32LE(bytes, cursor + 8),
           let dataSize = u32LE(bytes, cursor + 12) {
            signatureOffset = Int(dataOffset)
            signatureSize = Int(dataSize)
        }
        cursor = next
    }
    guard let signatureOffset, let signatureSize,
          let signatureEnd = advance(signatureOffset, signatureSize, limit: bytes.count),
          signatureSize >= 12,
          u32BE(bytes, signatureOffset) == 0xFADE0CC0,
          let blobCount = u32BE(bytes, signatureOffset + 8),
          blobCount <= 32 else {
        return nil
    }
    var index = signatureOffset + 12
    for _ in 0..<blobCount {
        guard let kind = u32BE(bytes, index),
              let relative = u32BE(bytes, index + 4),
              let next = advance(index, 8, limit: signatureEnd) else {
            return nil
        }
        if kind == 5, let xml = entitlementBody(bytes, signatureOffset, relative, signatureEnd) {
            return xml
        }
        index = next
    }
    return nil
}

private func entitlementBody(_ bytes: Data, _ signatureOffset: Int, _ relative: UInt32, _ signatureEnd: Int) -> Data? {
    guard let start = advance(signatureOffset, Int(relative), limit: signatureEnd),
          start + 8 <= signatureEnd,
          u32BE(bytes, start) == 0xFADE7171,
          let length = u32BE(bytes, start + 4),
          length >= 8,
          let end = advance(start, Int(length), limit: signatureEnd) else {
        return nil
    }
    return bytes.subdata(in: (start + 8)..<end)
}

private func advance(_ base: Int, _ delta: Int, limit: Int) -> Int? {
    guard base >= 0, delta >= 0, base <= limit, delta <= limit - base else { return nil }
    return base + delta
}

private func u32LE(_ data: Data, _ offset: Int) -> UInt32? {
    guard advance(offset, 4, limit: data.count) != nil else { return nil }
    return UInt32(data[offset])
        | (UInt32(data[offset + 1]) << 8)
        | (UInt32(data[offset + 2]) << 16)
        | (UInt32(data[offset + 3]) << 24)
}

private func u32BE(_ data: Data, _ offset: Int) -> UInt32? {
    guard advance(offset, 4, limit: data.count) != nil else { return nil }
    return (UInt32(data[offset]) << 24)
        | (UInt32(data[offset + 1]) << 16)
        | (UInt32(data[offset + 2]) << 8)
        | UInt32(data[offset + 3])
}
