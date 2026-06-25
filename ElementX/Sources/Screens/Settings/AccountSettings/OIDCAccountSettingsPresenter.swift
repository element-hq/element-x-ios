//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
    /// Retained for the lifetime of the presentation so the session isn't cancelled early.
    private var session: ASWebAuthenticationSession?

    init(accountURL: URL, presentationAnchor: UIWindow, appSettings: AppSettings) {
        self.accountURL = accountURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = appSettings.oidcRedirectURL
        super.init()
    }

    /// Presents a web authentication session for the supplied data and returns once it
    /// is dismissed — either because the page redirected to the callback URL or because
    /// the user closed the sheet. Callers that need to act on the result of the web flow
    /// (e.g. the identity-reset approval) must `await` this before continuing.
    func start() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let session = ASWebAuthenticationSession(url: accountURL, callback: .oidcRedirectURL(oidcRedirectURL)) { _, _ in
                continuation.resume()
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            session.additionalHeaderFields = [
                "X-Element-User-Agent": UserAgentBuilder.makeASCIIUserAgent()
            ]
            self.session = session
            session.start()
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }
}
