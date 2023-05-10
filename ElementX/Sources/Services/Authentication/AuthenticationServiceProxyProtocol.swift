//
// Copyright 2022 New Vector Ltd
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

enum AuthenticationServiceError: Error {
    /// An error occurred during OIDC authentication.
    case oidcError(OIDCError)
    case invalidServer
    case invalidCredentials
    case invalidHomeserverAddress
    case slidingSyncNotAvailable
    case accountDeactivated
    case failedLoggingIn
}

protocol AuthenticationServiceProxyProtocol {
    var homeserver: LoginHomeserver { get }
    
    /// Sets up the service for login on the specified homeserver address.
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError>
    /// Performs login using OIDC for the current homeserver.
    func urlForOIDCLogin() async -> Result<OIDCAuthenticationDataProxy, AuthenticationServiceError>
    /// Add docs.
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthenticationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    /// Performs a password login using the current homeserver.
    func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError>
}

// MARK: - OIDC

enum OIDCError: Error {
    /// Failed to get the URL that should be presented for login.
    case urlFailure
    /// The user cancelled the login.
    case userCancellation
    /// OIDC isn't supported on the currently configured server.
    case notSupported
    /// An unknown error occurred.
    case unknown
}

struct OIDCAuthenticationDataProxy: Equatable {
//    let underlyingData: OidcAuthenticationData
//
//    var url: URL {
//        URL(string: underlyingData.loginUrl())!
//    }
    let url = URL(staticString: "https://theroadtonowhere")
}

// extension OidcAuthenticationData: Equatable {
//    public static func == (lhs: MatrixRustSDK.OidcAuthenticationData, rhs: MatrixRustSDK.OidcAuthenticationData) -> Bool {
//        lhs.loginUrl() == rhs.loginUrl()
//    }
// }
