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
    /// The homeserver string to be shown to the user.
    let address: String
    /// The types login supported by the homeserver.
    var loginMode: LoginMode
    
    /// Creates a new homeserver value.
    init(address: String, loginMode: LoginMode) {
        let address = Self.sanitized(address).components(separatedBy: "://").last ?? address
        
        self.address = address
        self.loginMode = loginMode
    }
    
    /// Sanitizes a user entered homeserver address with the following rules
    /// - Trim any whitespace.
    /// - Lowercase the address.
    /// - Ensure the address contains a scheme, otherwise make it `https`.
    /// - Remove any trailing slashes.
    static func sanitized(_ address: String) -> String {
        var address = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if !address.contains("://") {
            address = "https://\(address)"
        }
        
        address = address.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return address
    }
}

// MARK: - Mocks

extension LoginHomeserver {
    /// A mock homeserver that is configured just like matrix.org.
    static var mockMatrixDotOrg: LoginHomeserver {
        LoginHomeserver(address: "matrix.org", loginMode: .oidc(supportsCreatePrompt: true))
    }
    
    /// A mock homeserver that supports login and registration via a password but has no SSO providers.
    static var mockBasicServer: LoginHomeserver {
        LoginHomeserver(address: "example.com", loginMode: .password)
    }
    
    /// A mock homeserver that supports only supports authentication via a single SSO provider.
    static var mockOIDC: LoginHomeserver {
        LoginHomeserver(address: "company.com", loginMode: .oidc(supportsCreatePrompt: false))
    }
    
    /// A mock homeserver that only with no supported login flows.
    static var mockUnsupported: LoginHomeserver {
        LoginHomeserver(address: "server.net", loginMode: .unsupported)
    }
}
