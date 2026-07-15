//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RemoteSettingsError: Error {
    case elementProRequired(serverName: String)
}

protocol RemoteSettingsHookProtocol: Sendable {
    #if IS_MAIN_APP
    // periphery:ignore:parameters appSettings - part of the hook signature
    @MainActor func initializeCache(using client: ClientProtocol, applyingTo appSettings: CommonSettingsProtocol) async -> Result<Void, RemoteSettingsError>
    // periphery:ignore:parameters client - part of the hook signature
    func updateCache(using client: ClientProtocol) async
    // periphery:ignore:parameters appSettings - part of the hook signature
    @MainActor func reset(_ appSettings: CommonSettingsProtocol)
    #endif
    // periphery:ignore:parameters homeserver,appSettings - part of the hook signature
    @MainActor func loadCache(forHomeserver homeserver: String, applyingTo appSettings: CommonSettingsProtocol)
}

struct DefaultRemoteSettingsHook: RemoteSettingsHookProtocol {
    #if IS_MAIN_APP
    /// A best effort implementation to let Element X advertise to users when they should be using
    /// Element Pro. In an ideal world the backend would be able to validate the client's requests
    /// instead of relying on it to check a well-known file for this.
    // periphery:ignore:parameters appSettings - part of the hook signature
    func initializeCache(using client: ClientProtocol, applyingTo appSettings: CommonSettingsProtocol) async -> Result<Void, RemoteSettingsError> {
        guard case let .success(wellKnownData) = await client.elementWellKnown() else {
            // Nothing to check, carry on as normal.
            return .success(())
        }
        
        do {
            let wellKnown = try JSONDecoder().decode(ElementWellKnown.self, from: wellKnownData)
            if wellKnown.enforceElementPro == true {
                let serverName = client.server() ?? client.homeserver()
                let displayableServerName = LoginHomeserver(address: serverName, loginMode: .unknown).address
                return .failure(.elementProRequired(serverName: displayableServerName))
            } else {
                return .success(())
            }
        } catch {
            // If it doesn't decode we have to assume it's a 404 page or similar.
            return .success(())
        }
    }
    
    // periphery:ignore:parameters client - part of the hook signature
    func updateCache(using client: ClientProtocol) async { }
    // periphery:ignore:parameters appSettings - part of the hook signature
    func reset(_ appSettings: any CommonSettingsProtocol) { }
    #endif
    
    // periphery:ignore:parameters homeserver,appSettings - part of the hook signature
    func loadCache(forHomeserver homeserver: String, applyingTo appSettings: CommonSettingsProtocol) { }
}

private struct ElementWellKnown: Decodable {
    // periphery:ignore - documents the schema, parsed but not consumed yet
    var version: Int?
    var enforceElementPro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case version
        case enforceElementPro = "enforce_element_pro"
    }
}
