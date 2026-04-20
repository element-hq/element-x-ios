//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AuthenticationServices

/// Presents a web authentication session that will display the user's account settings page.
///
/// A web authentication session is used so that the same session used for login is available
/// meaning that the user doesn't need to sign in again. `SFSafariViewController` doesn't
/// have access to this session, and for some reason `prefersEphemeralWebBrowserSession`
/// isn't sharing the session back to Safari.
@MainActor
class OAuthAccountSettingsPresenter: NSObject {
    private let accountURL: URL
    private let redirectURL: URL
    private let presentationAnchor: UIWindow
    private let appMediator: AppMediatorProtocol
    private let appHooks: AppHooks
    
    typealias Continuation = AsyncStream<Result<Void, OAuthError>>.Continuation
    private let continuation: Continuation?
    
    init(accountURL: URL,
         presentationAnchor: UIWindow,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         continuation: Continuation? = nil) {
        self.accountURL = accountURL
        redirectURL = appSettings.oAuthRedirectURL
        self.presentationAnchor = presentationAnchor
        self.appMediator = appMediator
        self.appHooks = appHooks
        self.continuation = continuation
        
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func start() {
        let accountURL = appHooks.oAuthPresenterHook.update(accountURL)
        
        let session = ASWebAuthenticationSession(url: accountURL, callback: .oAuthRedirectURL(redirectURL)) { [continuation] _, error in
            guard let continuation else { return }
            
            if error?.isOAuthUserCancellation == true {
                continuation.yield(.failure(.userCancellation))
            } else {
                let errorDescription = error.map(String.init(describing:)) ?? "Unknown error"
                MXLog.error("A web authentication session error occurred: \(errorDescription)")
                continuation.yield(.failure(.unknown))
            }
            
            continuation.finish()
        }
        
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.additionalHeaderFields = [
            "X-Element-User-Agent": UserAgentBuilder.makeASCIIUserAgent()
        ]
        
        if accountURL.scheme == "https" || accountURL.scheme == "http" {
            session.start()
        } else {
            appMediator.open(accountURL)
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OAuthAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }
}
