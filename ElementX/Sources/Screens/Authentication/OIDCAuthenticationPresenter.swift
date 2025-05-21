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
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var activeSession: ASWebAuthenticationSession?
    
    init(authenticationService: AuthenticationServiceProtocol,
         oidcRedirectURL: URL,
         presentationAnchor: UIWindow,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.oidcRedirectURL = oidcRedirectURL
        self.presentationAnchor = presentationAnchor
        self.userIndicatorController = userIndicatorController
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
            session.additionalHeaderFields = [
                "X-Element-User-Agent": UserAgentBuilder.makeASCIIUserAgent()
            ]
            
            activeSession = session
            session.start()
        }
        
        activeSession = nil
        
        guard let url else {
            // Check for user cancellation to avoid showing an alert in that instance.
            if let nsError = error as? NSError,
               nsError.domain == ASWebAuthenticationSessionErrorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue,
               // If there's a failure reason then the cancellation wasn't made by the user.
               nsError.localizedFailureReason == nil {
                // No need to show an error here, just abort and return a failure.
                await authenticationService.abortOIDCLogin(data: oidcData)
                return .failure(.oidcError(.userCancellation))
            }
            
            let errorDescription = error.map(String.init(describing:)) ?? "Unknown error"
            MXLog.error("Missing callback URL from the web authentication session: \(errorDescription)")
            
            userIndicatorController.alertInfo = AlertInfo(id: UUID())
            await authenticationService.abortOIDCLogin(data: oidcData)
            return .failure(.oidcError(.unknown))
        }
        
        // Exchanging the callback with the homeserver can be slow, so show the loading indicator while we wait (the modal has already been dismissed).
        startLoading(delay: .milliseconds(50)) // Small delay to handle a cancellation callback without the indicator showing.
        defer { stopLoading() }
        
        switch await authenticationService.loginWithOIDCCallback(url) {
        case .success(let userSession):
            return .success(userSession)
        case .failure(.oidcError(.userCancellation)):
            // No need to show an error here, just return the failure.
            return .failure(.oidcError(.userCancellation))
        case .failure(let error):
            MXLog.error("Error occurred: \(error)")
            userIndicatorController.alertInfo = AlertInfo(id: UUID())
            return .failure(error)
        }
    }
    
    func cancel() {
        activeSession?.cancel()
    }
    
    private static let loadingIndicatorID = "\(OIDCAuthenticationPresenter.self)-Loading"
    
    private func startLoading(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
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
