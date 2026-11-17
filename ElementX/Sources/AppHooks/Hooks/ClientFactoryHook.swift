//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated enum ClientFactoryError: Error {
    case elementProRequired(serverName: String)
}

nonisolated protocol ClientFactoryHookProtocol: Sendable {
    func configure(_ builder: ClientBuilder, toRestore session: Session?) -> ClientBuilder
    
    #if IS_MAIN_APP
    func validateAuthenticationHomeserver(for client: ClientProtocol) async throws(ClientFactoryError)
    func updateAuthenticationClient(_ client: ClientProtocol) async -> ClientProtocol
    #endif
    func updateRestoredClient(_ client: ClientProtocol) async -> ClientProtocol
}

nonisolated struct DefaultClientFactoryHook: ClientFactoryHookProtocol {
    func configure(_ builder: ClientBuilder, toRestore session: Session?) -> ClientBuilder {
        builder
    }
    
    #if IS_MAIN_APP
    /// A best effort implementation to let Element X advertise to users when they should be using
    /// Element Pro. In an ideal world the backend would be able to validate the client's requests
    /// instead of relying on it to check a well-known file for this.
    func validateAuthenticationHomeserver(for client: ClientProtocol) async throws(ClientFactoryError) {
        guard case let .success(wellKnownData) = await client.elementWellKnown() else {
            // Nothing to check, carry on as normal.
            return
        }
        
        if let wellKnown = try? JSONDecoder().decode(ElementWellKnown.self, from: wellKnownData) {
            if wellKnown.enforceElementPro == true {
                let serverName = client.server() ?? client.homeserver()
                let displayableServerName = AccountProvider.generic(serverName).serverNameOrBaseURL
                throw .elementProRequired(serverName: displayableServerName)
            } else {
                return
            }
        } else {
            // If it doesn't decode we have to assume it's a 404 page or similar.
            return
        }
    }
    
    func updateAuthenticationClient(_ client: ClientProtocol) async -> ClientProtocol {
        client
    }
    #endif
    
    func updateRestoredClient(_ client: ClientProtocol) async -> ClientProtocol {
        client
    }
}

private nonisolated struct ElementWellKnown: Decodable {
    var enforceElementPro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case enforceElementPro = "enforce_element_pro"
    }
}
