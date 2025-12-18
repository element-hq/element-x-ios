//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
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
    /// An error occurred during login with QR Code.
    case qrCodeError(QRCodeLoginError)
    
    case invalidServer
    case invalidCredentials
    case invalidHomeserverAddress
    case invalidWellKnown(String)
    case slidingSyncNotAvailable
    case loginNotSupported
    case registrationNotSupported
    case elementProRequired(serverName: String)
    case accountDeactivated
    case failedLoggingIn
    case sessionTokenRefreshNotSupported
    case failedUsingWebCredentials
}

protocol AuthenticationServiceProtocol: QRCodeLoginServiceProtocol {
    /// The currently configured homeserver.
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { get }
    /// The type of flow the service is currently configured with.
    var flow: AuthenticationFlow { get }
        
    /// Sets up the service for login on the specified homeserver address.
    func configure(for homeserverAddress: String, flow: AuthenticationFlow) async -> Result<Void, AuthenticationServiceError>
    /// Performs login using OIDC for the current homeserver.
    func urlForOIDCLogin(loginHint: String?) async -> Result<OIDCAuthorizationDataProxy, AuthenticationServiceError>
    /// Asks the SDK to abort an ongoing OIDC login if we didn't get a callback to complete the request with.
    func abortOIDCLogin(data: OIDCAuthorizationDataProxy) async
    /// Completes an OIDC login that was started using ``urlForOIDCLogin``.
    func loginWithOIDCCallback(_ callbackURL: URL) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    /// Performs a password login using the current homeserver.
    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError>
    
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

struct OIDCAuthorizationDataProxy: Hashable {
    let underlyingData: OAuthAuthorizationData
    
    var url: URL {
        guard let url = URL(string: underlyingData.loginUrl()) else {
            fatalError("OIDC login URL hasn't been validated.")
        }
        return url
    }
}

extension OAuthAuthorizationData: @retroactive Hashable {
    public static func == (lhs: MatrixRustSDK.OAuthAuthorizationData, rhs: MatrixRustSDK.OAuthAuthorizationData) -> Bool {
        lhs.loginUrl() == rhs.loginUrl()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(loginUrl())
    }
}

// MARK: - Login with QR code

enum QRCodeLoginError: Error, Equatable {
    case invalidQRCode
    case providerNotAllowed(scannedProvider: String, allowedProviders: [String])
    case cancelled
    case connectionInsecure
    case declined
    case linkingNotSupported
    case expired
    case deviceNotSupported
    case deviceNotSignedIn
    case deviceAlreadySignedIn
    case unknown
}

// sourcery: AutoMockable
protocol QRCodeLoginServiceProtocol {
    typealias QRLoginProgressPublisher = CurrentValuePublisher<QRLoginProgress, AuthenticationServiceError>
    func loginWithQRCode(data: Data) -> QRLoginProgressPublisher
}

enum QRLoginProgress {
    case starting
    case establishingSecureChannel(checkCode: UInt8, checkCodeString: String)
    case waitingForToken(userCode: String)
    case syncingSecrets
    case signedIn(UserSessionProtocol)
    
    init?(rustProgress: QrLoginProgress) {
        switch rustProgress {
        case .starting:
            self = .starting
        case .establishingSecureChannel(let checkCode, let checkCodeString):
            self = .establishingSecureChannel(checkCode: checkCode, checkCodeString: checkCodeString)
        case .waitingForToken(let userCode):
            self = .waitingForToken(userCode: userCode)
        case .syncingSecrets:
            self = .syncingSecrets
        case .done:
            return nil // The SDK is done, but the app still needs to set up the UserSession.
        }
    }
}

extension QRLoginProgress: Equatable, CustomStringConvertible {
    static func == (lhs: QRLoginProgress, rhs: QRLoginProgress) -> Bool {
        switch (lhs, rhs) {
        case (.starting, .starting):
            true
        case let (.establishingSecureChannel(lhsCheckCode, lhsCheckCodeString), .establishingSecureChannel(rhsCheckCode, rhsCheckCodeString)):
            lhsCheckCode == rhsCheckCode && lhsCheckCodeString == rhsCheckCodeString
        case let (.waitingForToken(lhsUserCode), .waitingForToken(rhsUserCode)):
            lhsUserCode == rhsUserCode
        case (.syncingSecrets, .syncingSecrets):
            true
        case (.signedIn, .signedIn):
            true
        default:
            false
        }
    }
    
    var description: String {
        switch self {
        case .starting: "starting"
        case .establishingSecureChannel: "establishingSecureChannel"
        case .waitingForToken: "waitingForToken"
        case .syncingSecrets: "syncingSecrets"
        case .signedIn: "signedIn"
        }
    }
}
