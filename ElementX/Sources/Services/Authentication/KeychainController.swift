//
//  KeychainController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation
import KeychainAccess

class KeychainController: KeychainControllerProtocol {
    
    struct Constants {
        static let restoreTokenGroupKey = "restoreTokens"
    }
    
    private let keychain: Keychain
    
    init(identifier: String) {
        keychain = Keychain(service: identifier)
    }
 
    func setRestoreToken(_ token: String, forUsername username: String) {
        do {
            try keychain.set(token, key: username)
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
    
    func restoreTokens() -> [(username: String, token: String)] {
        keychain.allKeys().compactMap { username in
            guard let token = restoreTokenForUsername(username) else {
                return nil
            }
            
            return (username, token)
        }
    }
    
    func removeAllTokens() {
        do {
            try keychain.removeAll()
        } catch {
            MXLog.error("Failed removing all tokens")
        }
    }
}
