//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// The supported forms of login that a homeserver allows.
enum LoginMode: Equatable {
    /// The login mode hasn't been determined yet.
    case unknown
    /// The homeserver supports login via OpenID Connect at the associated URL.
    case oidc(URL)
    /// The homeserver supports login with a password.
    case password
    /// The homeserver only allows login with unsupported mechanisms. Use fallback instead.
    case unsupported
    
    var supportsOIDCFlow: Bool {
        switch self {
        case .oidc:
            return true
        default:
            return false
        }
    }
    
    var supportsPasswordFlow: Bool {
        switch self {
        case .password:
            return true
        default:
            return false
        }
    }

    var isUnsupported: Bool {
        switch self {
        case .unsupported:
            return true
        default:
            return false
        }
    }
}
