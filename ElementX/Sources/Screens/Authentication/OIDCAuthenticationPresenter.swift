//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AuthenticationServices

/// Presents a web authentication session for an OIDC request.
@MainActor
class OIDCAuthenticationPresenter: NSObject {
    private let authenticationService: AuthenticationServiceProtocol
    private let oidcRedirectURL: URL
    private let presentationAnchor: UIWindow
    
    /// The data required to complete a request.
    struct Request {
        let session: ASWebAuthenticationSession
        let oidcData: OIDCAuthorizationDataProxy
        let continuation: CheckedContinuation<Result<UserSessionProtocol, AuthenticationServiceError>, Never>
    }
    
    /// The current request in progress. This is a single use value and will be moved on access.
    @Consumable private var request: Request?
    
    init(authenticationService: AuthenticationServiceProtocol, oidcRedirectURL: URL, presentationAnchor: UIWindow) {
        self.authenticationService = authenticationService
        self.oidcRedirectURL = oidcRedirectURL
        self.presentationAnchor = presentationAnchor
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func authenticate(using oidcData: OIDCAuthorizationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: oidcData.url,
                                                     callback: .oidcRedirectURL(oidcRedirectURL)) { [weak self] url, error in
                guard let self else { return }
                
                guard let url else {
                    // Check for user cancellation to avoid showing an alert in that instance.
                    if let nsError = error as? NSError,
                       nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.completeAuthentication(throwing: .oidcError(.userCancellation))
                        return
                    }
                    
                    self.completeAuthentication(throwing: .oidcError(.unknown))
                    return
                }
                
                completeAuthentication(callbackURL: url)
            }
            
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            
            request = Request(session: session, oidcData: oidcData, continuation: continuation)
            
            session.start()
        }
    }
    
    /// Completes the authentication by exchanging the callback URL for a user session.
    private func completeAuthentication(callbackURL: URL) {
        guard let request else {
            MXLog.error("Failed to complete authentication. Missing request.")
            return
        }
        
        if callbackURL.scheme?.starts(with: "http") == true {
            request.session.cancel()
        }
        
        Task {
            switch await authenticationService.loginWithOIDCCallback(callbackURL, data: request.oidcData) {
            case .success(let userSession):
                request.continuation.resume(returning: .success(userSession))
            case .failure(let error):
                request.continuation.resume(returning: .failure(error))
            }
        }
    }
    
    /// Aborts the authentication with the supplied error.
    private func completeAuthentication(throwing error: AuthenticationServiceError) {
        guard let request else {
            MXLog.error("Failed to throw authentication error. Missing request.")
            return
        }
        
        Task {
            await authenticationService.abortOIDCLogin(data: request.oidcData)
            request.continuation.resume(returning: .failure(error))
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
