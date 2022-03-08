//
//  KeychainControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation

protocol KeychainControllerProtocol {
    func setRestoreToken(_ token: String, forUsername username: String)
    func restoreTokenForUsername(_ username: String) -> String?
    func restoreTokens() -> [(username: String, token: String)]
    func removeAllTokens()
}
