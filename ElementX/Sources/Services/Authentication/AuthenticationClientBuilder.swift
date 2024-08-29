//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
                         appHooks: appHooks)
            .sessionPaths(dataPath: sessionDirectories.dataPath,
                          cachePath: sessionDirectories.cachePath)
            .passphrase(passphrase: passphrase)
    }
}
