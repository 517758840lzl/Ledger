//
//  LedgerCloudMirror.swift
//  Ledger
//
//  Created by Ketty on 2026/11/05.
//

import CloudKit
import Foundation

enum LedgerCloudFetch {
    case unavailable
    case synced(payload: LedgerCloudPayload, token: Data, hasChanges: Bool)
}

/// Private CloudKit book. If the account has no iCloud, calls return `.unavailable` and the local database stays as it is.
final class LedgerCloudMirror {
    private let container: CKContainer
    private let zoneID: CKRecordZone.ID

    init?(bundleID: String) {
        guard LedgerCloudIdentity.declaresContainer(bundleID: bundleID) else { return nil }
        container = CKContainer(identifier: LedgerCloudIdentity.containerID(bundleID: bundleID))
        zoneID = CKRecordZone.ID(zoneName: LedgerCloudIdentity.zoneName(bundleID: bundleID), ownerName: CKCurrentUserDefaultName)
    }

    func fetch(since tokenData: Data?) async -> LedgerCloudFetch {
        guard await accountIsAvailable() else { return .unavailable }
        let database = container.privateCloudDatabase
        guard await ensureZone(database) else { return .unavailable }
        var token = Self.token(from: tokenData)
        var payload = LedgerCloudPayload()
        var more = true
        var guardPages = 0
        while more && guardPages < 20 {
            guardPages += 1
            do {
                let page = try await database.recordZoneChanges(inZoneWith: zoneID, since: token)
                for (_, result) in page.modificationResultsByID {
                    if case .success(let modification) = result {
                        Self.absorb(modification.record, into: &payload)
                    }
                }
                for deletion in page.deletions {
                    payload.removed[deletion.recordID.recordName] = Date().timeIntervalSince1970
                }
                token = page.changeToken
                more = page.moreComing
            } catch {
                if Self.isExpiredToken(error), tokenData != nil {
                    return await fetch(since: nil)
                }
                if Self.isMissingZone(error) {
                    return .synced(payload: LedgerCloudPayload(), token: Data(), hasChanges: false)
                }
                return .unavailable
            }
        }
        let data = token.flatMap(Self.data(from:)) ?? Data()
        return .synced(payload: payload, token: data, hasChanges: payload.hasChanges)
    }

    func push(_ payload: LedgerCloudPayload) async {
        guard await accountIsAvailable() else { return }
        let database = container.privateCloudDatabase
        guard await ensureZone(database) else { return }
        let records = Self.records(from: payload, zoneID: zoneID)
        let deletions = payload.removed.keys.map { CKRecord.ID(recordName: $0, zoneID: zoneID) }
        for chunk in stride(from: 0, to: records.count, by: 200).map({ Array(records[$0..<min($0 + 200, records.count)]) }) {
            _ = try? await database.modifyRecords(saving: chunk, deleting: [], savePolicy: .allKeys, atomically: false)
        }
        if !deletions.isEmpty {
            _ = try? await database.modifyRecords(saving: [], deleting: deletions, savePolicy: .allKeys, atomically: false)
        }
    }

    private func accountIsAvailable() async -> Bool {
        do {
            return try await container.accountStatus() == .available
        } catch {
            return false
        }
    }

    private func ensureZone(_ database: CKDatabase) async -> Bool {
        let saved = try? await database.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
        guard let saved else { return false }
        if case .failure = saved.saveResults[zoneID] { return false }
        return true
    }

    private static func isMissingZone(_ error: Error) -> Bool {
        guard let ck = error as? CKError else { return false }
        return ck.code == .zoneNotFound || ck.code == .userDeletedZone
    }

    private static func isExpiredToken(_ error: Error) -> Bool {
        (error as? CKError)?.code == .changeTokenExpired
    }

    private static func data(from token: CKServerChangeToken) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    private static func token(from data: Data?) -> CKServerChangeToken? {
        guard let data, !data.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }
}
