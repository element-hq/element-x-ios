//
//  KeychainControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct KeychainCredentials {
    let username: String
    let accessToken: String
}

protocol KeychainControllerProtocol {
    func setAccessToken(_ accessToken: String, forUsername username: String)
    func accessTokenForUsername(_ username: String) -> String?
    func accessTokens() -> [KeychainCredentials]
    func removeAccessTokenForUsername(_ username: String)
    func removeAllAccessTokens()
}
