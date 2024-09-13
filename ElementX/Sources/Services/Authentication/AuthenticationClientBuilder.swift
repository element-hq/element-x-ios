//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A wrapper around `ClientBuilder` to share reusable code between Normal and QR logins.
struct AuthenticationClientBuilder {
    let sessionDirectories: SessionDirectories
    let passphrase: String
    let clientSessionDelegate: ClientSessionDelegate
    
    let appSettings: AppSettings
    let appHooks: AppHooks
    
    /// Builds a Client for login using OIDC or password authentication.
    func build(homeserverAddress: String) async throws -> Client {
        if appSettings.slidingSyncDiscovery == .forceNative {
            return try await makeClientBuilder(slidingSync: .forceNative).serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress).build()
        }
        
        if appSettings.slidingSyncDiscovery == .native {
            do {
                return try await makeClientBuilder(slidingSync: .discoverNative).serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress).build()
            } catch {
                MXLog.warning("Native sliding sync not available: \(error)")
                MXLog.info("Falling back to a sliding sync proxy.")
            }
        }
        
        return try await makeClientBuilder(slidingSync: .discoverProxy).serverNameOrHomeserverUrl(serverNameOrUrl: homeserverAddress).build()
    }
    
    /// Builds a Client, authenticating with the given QR code data.
    func buildWithQRCode(qrCodeData: QrCodeData,
                         oidcConfiguration: OIDCConfigurationProxy,
                         progressListener: QrLoginProgressListenerProxy) async throws -> Client {
        if appSettings.slidingSyncDiscovery == .forceNative {
            return try await makeClientBuilder(slidingSync: .forceNative).buildWithQrCode(qrCodeData: qrCodeData,
                                                                                          oidcConfiguration: oidcConfiguration.rustValue,
                                                                                          progressListener: progressListener)
        }
        
        if appSettings.slidingSyncDiscovery == .native {
            do {
                return try await makeClientBuilder(slidingSync: .discoverNative).buildWithQrCode(qrCodeData: qrCodeData,
                                                                                                 oidcConfiguration: oidcConfiguration.rustValue,
                                                                                                 progressListener: progressListener)
            } catch HumanQrLoginError.SlidingSyncNotAvailable {
                MXLog.warning("Native sliding sync not available")
                MXLog.info("Falling back to a sliding sync proxy.")
            }
        }
        
        return try await makeClientBuilder(slidingSync: .discoverProxy).buildWithQrCode(qrCodeData: qrCodeData,
                                                                                        oidcConfiguration: oidcConfiguration.rustValue,
                                                                                        progressListener: progressListener)
    }
    
    // MARK: - Private
    
    /// The base builder configuration used for authentication within the app.
    private func makeClientBuilder(slidingSync: ClientBuilderSlidingSync) -> ClientBuilder {
        ClientBuilder
            .baseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                         slidingSync: slidingSync,
                         sessionDelegate: clientSessionDelegate,
                         appHooks: appHooks,
                         invisibleCryptoEnabled: appSettings.invisibleCryptoEnabled)
            .sessionPaths(dataPath: sessionDirectories.dataPath,
                          cachePath: sessionDirectories.cachePath)
            .passphrase(passphrase: passphrase)
    }
}
