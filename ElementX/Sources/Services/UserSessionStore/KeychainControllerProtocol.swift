//
//  KeychainControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct KeychainCredentials {
    let userID: String
    let restoreToken: String
}

protocol KeychainControllerProtocol {
    func setRestoreToken(_ accessToken: String, forUsername username: String)
    func restoreTokenForUsername(_ username: String) -> String?
    func restoreTokens() -> [KeychainCredentials]
    func removeRestoreTokenForUsername(_ username: String)
    func removeAllRestoreTokens()
}
