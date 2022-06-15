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
 
    func setAccessToken(_ accessToken: String, forUsername username: String) {
        do {
            try keychain.set(accessToken, key: username)
        } catch {
            MXLog.error("Failed storing user access token with error: \(error)")
        }
    }
    
    func accessTokenForUsername(_ username: String) -> String? {
        do {
            return try keychain.get(username)
        } catch {
            MXLog.error("Failed retrieving user access token")
            return nil
        }
    }
    
    func accessTokens() -> [(username: String, accessToken: String)] {
        keychain.allKeys().compactMap { username in
            guard let accessToken = accessTokenForUsername(username) else {
                return nil
            }
            
            return (username, accessToken)
        }
    }
    
    func removeAccessTokenForUsername(_ username: String) {
        do {
            try keychain.remove(username)
        } catch {
            MXLog.error("Failed removing access token with error: \(error)")
        }
    }
    
    func removeAllAccessTokens() {
        do {
            try keychain.removeAll()
        } catch {
            MXLog.error("Failed removing all tokens")
        }
    }
}
