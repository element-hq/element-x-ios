//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

// sourcery: AutoMockable
nonisolated protocol ClientFactoryProtocol {
    // MARK: Authentication
    
    #if IS_MAIN_APP
    func makeAuthenticationClient(serverNameOrBaseURL: String,
                                  sessionDirectories: SessionDirectories,
                                  passphrase: String,
                                  clientSessionDelegate: ClientSessionDelegate,
                                  appSettings: AppSettings,
                                  appHooks: AppHooks) async throws -> ClientProtocol
    
    func makeInMemoryClient(serverNameOrBaseURL: String,
                            clientSessionDelegate: ClientSessionDelegate,
                            appSettings: AppSettings,
                            appHooks: AppHooks) async throws -> ClientProtocol
    
    // MARK: Restoration
    
    func makeAppClient(credentials: KeychainCredentials,
                       clientSessionDelegate: ClientSessionDelegate,
                       appSettings: AppSettings,
                       appHooks: AppHooks) async throws -> ClientProtocol
    #endif
    
    func makeNSEClient(credentials: KeychainCredentials,
                       roomID: String,
                       clientSessionDelegate: ClientSessionDelegate,
                       appSettings: CommonSettingsProtocol,
                       appHooks: AppHooks) async throws -> ClientProtocol
}
