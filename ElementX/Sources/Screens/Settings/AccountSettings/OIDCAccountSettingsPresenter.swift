//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    init(accountURL: URL, presentationAnchor: UIWindow) {
        self.accountURL = accountURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = ServiceLocator.shared.settings.oidcRedirectURL
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func start() {
        let session = ASWebAuthenticationSession(url: accountURL, callbackURLScheme: oidcRedirectURL.scheme) { _, _ in }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}
