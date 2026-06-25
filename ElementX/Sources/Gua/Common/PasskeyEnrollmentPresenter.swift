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
    ///
    /// Throws if the IDP redirects back with an OIDC `error` parameter, or if
    /// `ASWebAuthenticationSession` fails for a reason other than user cancellation.
    /// User cancellation is treated as success (no error thrown).
    func start() async throws {
        // Pass the device locale so the IDP renders in the user's language (e.g. French).
        var urlToOpen = enrollURL
        if let languageCode = Locale.current.language.languageCode?.identifier,
           var components = URLComponents(url: enrollURL, resolvingAgainstBaseURL: true) {
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: "ui_locales", value: languageCode))
            components.queryItems = queryItems
            urlToOpen = components.url ?? enrollURL
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(url: urlToOpen, callback: .oidcRedirectURL(oidcRedirectURL)) { callbackURL, error in
                if let error {
                    // Treat user-initiated cancellation as a normal dismissal (no error to surface).
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let callbackURL,
                          let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let errorCode = components.queryItems?.first(where: { $0.name == "error" })?.value {
                    // IDP redirected back with an OIDC error (e.g. access_denied).
                    let description = components.queryItems?.first(where: { $0.name == "error_description" })?.value
                    let message = description ?? errorCode
                    continuation.resume(throwing: NSError(domain: "PasskeyEnrollment",
                                                          code: -1,
                                                          userInfo: [NSLocalizedDescriptionKey: message]))
                } else {
                    continuation.resume()
                }
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
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }
}
