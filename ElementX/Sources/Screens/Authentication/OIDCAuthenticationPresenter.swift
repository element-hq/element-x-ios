//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AuthenticationServices

/// Presents a web authentication session for an OIDC request.
@MainActor
class OIDCAuthenticationPresenter: NSObject {
    private let authenticationService: AuthenticationServiceProtocol
    private let oidcRedirectURL: URL
    private let presentationAnchor: UIWindow
    
    init(authenticationService: AuthenticationServiceProtocol, oidcRedirectURL: URL, presentationAnchor: UIWindow) {
        self.authenticationService = authenticationService
        self.oidcRedirectURL = oidcRedirectURL
        self.presentationAnchor = presentationAnchor
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func authenticate(using oidcData: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        let (url, error) = await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: oidcData.url, callback: .oidcRedirectURL(oidcRedirectURL)) { url, error in
                continuation.resume(returning: (url, error))
            }
            
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            
            session.start()
        }
        
        guard let url else {
            // Check for user cancellation to avoid showing an alert in that instance.
            if let nsError = error as? NSError,
               nsError.domain == ASWebAuthenticationSessionErrorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                await authenticationService.abortOIDCLogin(data: oidcData)
                return .failure(.oidcError(.userCancellation))
            }
            
            await authenticationService.abortOIDCLogin(data: oidcData)
            return .failure(.oidcError(.unknown))
        }
        
        switch await authenticationService.loginWithOIDCCallback(url, data: oidcData) {
        case .success(let userSession):
            return .success(userSession)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAuthenticationPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}

extension ASWebAuthenticationSession.Callback {
    static func oidcRedirectURL(_ url: URL) -> Self {
        if url.scheme == "https", let host = url.host() {
            .https(host: host, path: url.path())
        } else if let scheme = url.scheme {
            .customScheme(scheme)
        } else {
            fatalError("Invalid OIDC redirect URL: \(url)")
        }
    }
}
