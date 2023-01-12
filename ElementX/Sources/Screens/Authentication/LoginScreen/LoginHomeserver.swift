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
        LoginHomeserver(address: "matrix.org", loginMode: .password)
    }
    
    /// A mock homeserver that supports login and registration via a password but has no SSO providers.
    static var mockBasicServer: LoginHomeserver {
        LoginHomeserver(address: "example.com", loginMode: .password)
    }
    
    /// A mock homeserver that supports only supports authentication via a single SSO provider.
    static var mockOIDC: LoginHomeserver {
        let issuerURL = URL(staticString: "https://auth.company.com")
        return LoginHomeserver(address: "company.com", loginMode: .oidc(issuerURL))
    }
    
    /// A mock homeserver that only with no supported login flows.
    static var mockUnsupported: LoginHomeserver {
        LoginHomeserver(address: "server.net", loginMode: .unsupported)
    }
}
