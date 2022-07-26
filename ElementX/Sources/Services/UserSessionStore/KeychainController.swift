//
//  KeychainController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainController: KeychainControllerProtocol {
    private let keychain: Keychain
    
    init(identifier: String) {
        keychain = Keychain(service: identifier)
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
