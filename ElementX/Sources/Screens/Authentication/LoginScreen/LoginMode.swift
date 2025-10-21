//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The supported forms of login that a homeserver allows.
enum LoginMode: Equatable {
    /// The login mode hasn't been determined yet.
    case unknown
    /// The homeserver supports login via OpenID Connect.
    case oidc(supportsCreatePrompt: Bool)
    /// The homeserver supports login with a password.
    case password
    /// The homeserver only allows login with unsupported mechanisms. Use fallback instead.
    case unsupported
    
    var supportsOIDCFlow: Bool {
        switch self {
        case .oidc: true
        default: false
        }
    }
}
