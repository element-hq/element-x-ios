//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import AuthenticationServices

/// Presents a web authentication session that drives passkey enrollment on the
/// IdP-hosted page returned by identity-service.
///
/// A web authentication session is used (rather than `SFSafariViewController`) so
/// that the existing login session is available and the user doesn't have to sign
/// in again. The session finishes when the page redirects to the app's OIDC
/// redirect URL. Mirrors ``OIDCAccountSettingsPresenter``.
@MainActor
class PasskeyEnrollmentPresenter: NSObject {
    private let enrollURL: URL
    private let presentationAnchor: UIWindow
    private let oidcRedirectURL: URL
    /// Retained for the lifetime of the presentation so the session isn't cancelled early.
    private var session: ASWebAuthenticationSession?

    init(enrollURL: URL, presentationAnchor: UIWindow, appSettings: AppSettings) {
        self.enrollURL = enrollURL
        self.presentationAnchor = presentationAnchor
        oidcRedirectURL = appSettings.oidcRedirectURL
        super.init()
    }

    /// Presents the web authentication session and returns once it is dismissed —
    /// either because the page redirected to the callback URL or because the user
    /// closed the sheet.
    func start() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let session = ASWebAuthenticationSession(url: enrollURL, callback: .oidcRedirectURL(oidcRedirectURL)) { _, _ in
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

extension PasskeyEnrollmentPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}
