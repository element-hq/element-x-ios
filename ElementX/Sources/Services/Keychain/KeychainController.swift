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
        Bundle.baseBundleIdentifier + "." + rawValue
    }
}

class KeychainController: KeychainControllerProtocol {
    private let keychain: Keychain
    
    init(service: KeychainControllerService,
         accessGroup: String) {
        keychain = Keychain(service: service.identifier, accessGroup: accessGroup)
    }
 
    func setRestoreToken(_ restoreToken: String, forUsername username: String) {
        do {
            try keychain.set(restoreToken, key: username)
        } catch {
            MXLog.error("Failed storing user restore token with error: \(error)")
        }
    }
    
    func restoreTokenForUsername(_ username: String) -> String? {
        do {
            return try keychain.get(username)
        } catch {
            MXLog.error("Failed retrieving user restore token")
            return nil
        }
    }
    
    func restoreTokens() -> [KeychainCredentials] {
        keychain.allKeys().compactMap { username in
            guard let restoreToken = restoreTokenForUsername(username) else {
                return nil
            }
            
            return KeychainCredentials(userID: username, restoreToken: restoreToken)
        }
    }
    
    func removeRestoreTokenForUsername(_ username: String) {
        do {
            try keychain.remove(username)
        } catch {
            MXLog.error("Failed removing restore token with error: \(error)")
        }
    }
    
    func removeAllRestoreTokens() {
        do {
            try keychain.removeAll()
        } catch {
            MXLog.error("Failed removing all tokens")
        }
    }
}
