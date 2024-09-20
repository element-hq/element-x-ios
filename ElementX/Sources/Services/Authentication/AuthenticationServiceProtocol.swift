//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// Represents a particular authentication flow.
enum AuthenticationFlow {
    /// The flow for signing in to an existing account.
    case login
    /// The flow for creating a new account.
    case register
}

enum AuthenticationServiceError: Error, Equatable {
    /// An error occurred during OIDC authentication.
    case oidcError(OIDCError)
    case invalidServer
    case invalidCredentials
    case invalidHomeserverAddress
    case invalidWellKnown(String)
    case slidingSyncNotAvailable
    case registrationNotSupported
    case accountDeactivated
    case failedLoggingIn
    case sessionTokenRefreshNotSupported
    case failedUsingWebCredentials
}

protocol AuthenticationServiceProtocol {
    /// The currently configured homeserver.
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { get }
    /// The type of flow the service is currently configured with.
    var flow: AuthenticationFlow { get }
        
    /// Sets up the service for login on the specified homeserver address.
    func configure(for homeserverAddress: String, flow: AuthenticationFlow) async -> Result<Void, AuthenticationServiceError>
    /// Performs login using OIDC for the current homeserver.
    func urlForOIDCLogin() async -> Result<OIDCAuthorizationDataProxy, AuthenticationServiceError>
    /// Asks the SDK to abort an ongoing OIDC login if we didn't get a callback to complete the request with.
    func abortOIDCLogin(data: OIDCAuthorizationDataProxy) async
    /// Completes an OIDC login that was started using ``urlForOIDCLogin``.
    func loginWithOIDCCallback(_ callbackURL: URL, data: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    /// Performs a password login using the current homeserver.
    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    /// Completes registration using the credentials obtained via the helper URL.
    func completeWebRegistration(using credentials: WebRegistrationCredentials) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    
    /// Resets the current configuration requiring `configure(for:flow:)` to be called again.
    func reset()
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

struct OIDCAuthorizationDataProxy: Equatable {
    let underlyingData: OidcAuthorizationData
    
    var url: URL {
        guard let url = URL(string: underlyingData.loginUrl()) else {
            fatalError("OIDC login URL hasn't been validated.")
        }
        return url
    }
}

extension OidcAuthorizationData: Equatable {
    public static func == (lhs: MatrixRustSDK.OidcAuthorizationData, rhs: MatrixRustSDK.OidcAuthorizationData) -> Bool {
        lhs.loginUrl() == rhs.loginUrl()
    }
}
