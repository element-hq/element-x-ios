//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import KeychainAccess

enum KeychainControllerService: String {
    case sessions
    case tests

    var identifier: String {
        InfoPlistReader.target.baseBundleIdentifier + "." + rawValue
    }
}

class KeychainController: KeychainControllerProtocol {
    private let keychain: Keychain

    init(service: KeychainControllerService,
         accessGroup: String) {
        keychain = Keychain(service: service.identifier,
                            accessGroup: accessGroup)
    }

    func setRestorationToken(_ restorationToken: RestorationToken, forUsername username: String) {
        do {
            let tokenData = try JSONEncoder().encode(restorationToken)
            try keychain.set(tokenData, key: username)
        } catch {
            MXLog.error("Failed storing user restore token with error: \(error)")
        }
    }

    func restorationTokenForUsername(_ username: String) -> RestorationToken? {
        do {
            guard let tokenData = try keychain.getData(username) else {
                return nil
            }

            // Handle the previous restoration token format as we don't want users to have to log in again
            // It will automatically be updated to the new version after login
            if let legacyRestorationToken = try? JSONDecoder().decode(LegacyRestorationToken.self, from: tokenData) {
                return .init(session: .init(accessToken: legacyRestorationToken.session.accessToken,
                                            refreshToken: nil,
                                            userId: legacyRestorationToken.session.userId,
                                            deviceId: legacyRestorationToken.session.deviceId,
                                            homeserverUrl: legacyRestorationToken.homeURL,
                                            isSoftLogout: legacyRestorationToken.isSoftLogout ?? false))
            }

            return try JSONDecoder().decode(RestorationToken.self, from: tokenData)
        } catch {
            MXLog.error("Failed retrieving user restore token")
            return nil
        }
    }

    func restorationTokens() -> [KeychainCredentials] {
        keychain.allKeys().compactMap { username in
            guard let restorationToken = restorationTokenForUsername(username) else {
                return nil
            }

            return KeychainCredentials(userID: username, restorationToken: restorationToken)
        }
    }

    func removeRestorationTokenForUsername(_ username: String) {
        do {
            try keychain.remove(username)
        } catch {
            MXLog.error("Failed removing restore token with error: \(error)")
        }
    }

    func removeAllRestorationTokens() {
        do {
            try keychain.removeAll()
        } catch {
            MXLog.error("Failed removing all tokens")
        }
    }
}
