//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import KeychainAccess
import MatrixRustSDK

protocol AppMigrationManagerProtocol { }

final class AppMigrationManager: AppMigrationManagerProtocol {
    private enum KeychainKeys: String {
        case cryptoSDKStoreKey
    }
    
    private let userID: String
    private let classicAppAccessGroup: String
    private let keychain: Keychain
    
    init(userID: String, classicAppKeychainServiceName: String, classicAppAccessGroup: String) {
        self.userID = userID
        self.classicAppAccessGroup = classicAppAccessGroup
        keychain = Keychain(service: classicAppKeychainServiceName, accessGroup: classicAppAccessGroup)
    }
    
    func test() {
        let storePassphrase = try? keychain.getData("cryptoSDKStoreKey")
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.vector") else {
            return
        }
        let test = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        MXLog.info("WIP TEST: \(test ?? [])")
        let testMatrixKit = test?.first(where: { $0.lastPathComponent == "MatrixKit" })
        MXLog.info("WIP TEST: \(testMatrixKit ?? "")")
        guard let testMatrixKit else {
            return
        }
        let test2 = try? FileManager.default.contentsOfDirectory(at: testMatrixKit, includingPropertiesForKeys: nil)
        MXLog.info("WIP TEST: \(test2)")
        // let machine = OlmMachin
    }
}
