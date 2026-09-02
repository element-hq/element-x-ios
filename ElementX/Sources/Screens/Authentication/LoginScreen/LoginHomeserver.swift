//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Information about a homeserver that is ready for display in the authentication flow.
struct LoginHomeserver: Equatable {
    /// The server's name or base URL that will be shown in the UI.
    let serverNameOrBaseURL: String
    /// The types login supported by the homeserver.
    var loginMode: LoginMode
    
    init(serverNameOrBaseURL: String, loginMode: LoginMode) {
        self.serverNameOrBaseURL = Self.sanitize(serverNameOrBaseURL)
        self.loginMode = loginMode
    }
    
    /// Sanitizes an address with the following rules:
    /// - Trim any whitespace.
    /// - Lowercase the address.
    /// - Removes an https scheme (treating it as implicit).
    /// - Remove any trailing slashes.
    static func sanitize(_ serverNameOrBaseURL: String) -> String {
        serverNameOrBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingPrefix("https://") // Intentionally continue to show http:// as an indicator (and for history).
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

// MARK: - Mocks

extension LoginHomeserver {
    /// A mock homeserver that is configured just like matrix.org.
    static var mockMatrixDotOrg: LoginHomeserver {
        LoginHomeserver(serverNameOrBaseURL: "matrix.org", loginMode: .oAuth(supportsCreatePrompt: true))
    }
    
    /// A mock homeserver that supports login and registration via a password but has no OAuth support.
    static var mockBasicServer: LoginHomeserver {
        LoginHomeserver(serverNameOrBaseURL: "example.com", loginMode: .password)
    }
    
    /// A mock homeserver that supports only supports authentication via OAuth.
    static var mockOAuth: LoginHomeserver {
        LoginHomeserver(serverNameOrBaseURL: "company.com", loginMode: .oAuth(supportsCreatePrompt: false))
    }
    
    /// A mock homeserver that only with no supported login flows.
    static var mockUnsupported: LoginHomeserver {
        LoginHomeserver(serverNameOrBaseURL: "server.net", loginMode: .unsupported)
    }
}
