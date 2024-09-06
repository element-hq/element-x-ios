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
                                                     callbackURLScheme: oidcRedirectURL.scheme) { [weak self] url, error in
                // This closure won't be called if the scheme is https, see handleUniversalLinkCallback for more info.
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
    
    /// This method will be used if the `appSettings.oidcRedirectURL`'s scheme is `https`.
    /// When using a custom scheme, the redirect will be handled by the web auth session's closure.
    func handleUniversalLinkCallback(_ url: URL) {
        completeAuthentication(callbackURL: url)
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
