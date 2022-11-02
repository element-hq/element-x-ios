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

import AppAuth
import Foundation

enum AuthenticationServiceError: Error {
    /// An error occurred during OIDC authentication.
    case oidcError(OIDCError)
    case invalidServer
    case invalidCredentials
    case invalidHomeserverAddress
    case accountDeactivated
    case failedLoggingIn
}

protocol AuthenticationServiceProxyProtocol {
    var homeserver: LoginHomeserver { get }
    
    /// Sets up the service for login on the specified homeserver address.
    func configure(for homeserverAddress: String) async -> Result<Void, AuthenticationServiceError>
    /// Performs login using OIDC for the current homeserver.
    func loginWithOIDC(userAgent: OIDExternalUserAgentIOS) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    /// Performs a password login using the current homeserver.
    func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError>
}
