//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol AuthenticationClientBuilderProtocol {
    func build(homeserverAddress: String) async throws -> ClientProtocol
    func buildWithQRCode(qrCodeData: QrCodeData,
                         oidcConfiguration: OIDCConfigurationProxy,
                         progressListener: SDKListener<QrLoginProgress>) async throws -> ClientProtocol
}

/// A wrapper around `ClientBuilder` to share reusable code between Normal and QR logins.
struct AuthenticationClientBuilder: AuthenticationClientBuilderProtocol {
    let sessionDirectories: SessionDirectories
    let passphrase: String
    let clientSessionDelegate: ClientSessionDelegate
    
    let appSettings: AppSettings
    let appHooks: AppHooks
    
    /// Builds a Client for login using OIDC or password authentication.
    func build(homeserverAddress: String) async throws -> ClientProtocol {
        try await makeClientBuilder().serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress).build()
    }
    
    /// Builds a Client, authenticating with the given QR code data.
    func buildWithQRCode(qrCodeData: QrCodeData,
                         oidcConfiguration: OIDCConfigurationProxy,
                         progressListener: SDKListener<QrLoginProgress>) async throws -> ClientProtocol {
        try await makeClientBuilder().buildWithQrCode(qrCodeData: qrCodeData,
                                                      oidcConfiguration: oidcConfiguration.rustValue,
                                                      progressListener: progressListener)
    }
    
    // MARK: - Private
    
    /// The base builder configuration used for authentication within the app.
    private func makeClientBuilder() -> ClientBuilder {
        ClientBuilder
            .baseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                         slidingSync: .discover,
                         sessionDelegate: clientSessionDelegate,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         enableKeyShareOnInvite: appSettings.enableKeyShareOnInvite)
            .sessionPaths(dataPath: sessionDirectories.dataPath,
                          cachePath: sessionDirectories.cachePath)
            .sessionPassphrase(passphrase: passphrase)
    }
}
