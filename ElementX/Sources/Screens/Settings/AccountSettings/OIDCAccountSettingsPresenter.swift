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
class OIDCAccountSettingsPresenter: NSObject {
    private let accountURL: URL
    private let presentationAnchor: UIWindow
    private let oidcRedirectURL: URL
    
    typealias Continuation = AsyncStream<Result<Void, OIDCError>>.Continuation
    private let continuation: Continuation?
    
    init(accountURL: URL, presentationAnchor: UIWindow, appSettings: AppSettings, continuation: Continuation? = nil) {
        self.accountURL = accountURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = appSettings.oidcRedirectURL
        self.continuation = continuation
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func start() {
        let session = ASWebAuthenticationSession(url: accountURL, callback: .oidcRedirectURL(oidcRedirectURL)) { [continuation] _, error in
            guard let continuation else { return }
            
            if error?.isOIDCUserCancellation == true {
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
        
        session.start()
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}
