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
    /// The account provider who operates the homeserver.
    let accountProvider: AccountProvider
    /// The types login supported by the homeserver.
    var loginMode: LoginMode
}

// MARK: - Mocks

extension LoginHomeserver {
    /// A mock homeserver that is configured just like matrix.org.
    static var mockMatrixDotOrg: LoginHomeserver {
        LoginHomeserver(accountProvider: .generic("matrix.org"), loginMode: .oAuth(supportsCreatePrompt: true))
    }
    
    /// A mock homeserver that supports login and registration via a password but has no OAuth support.
    static var mockBasicServer: LoginHomeserver {
        LoginHomeserver(accountProvider: .generic("example.com"), loginMode: .password)
    }
    
    /// A mock homeserver that supports only supports authentication via OAuth.
    static var mockOAuth: LoginHomeserver {
        LoginHomeserver(accountProvider: .generic("company.com"), loginMode: .oAuth(supportsCreatePrompt: false))
    }
    
    /// A mock homeserver that only with no supported login flows.
    static var mockUnsupported: LoginHomeserver {
        LoginHomeserver(accountProvider: .generic("server.net"), loginMode: .unsupported)
    }
}
