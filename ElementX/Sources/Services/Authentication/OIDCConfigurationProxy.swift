//
// Copyright 2024 New Vector Ltd
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

struct OIDCConfigurationProxy {
    let clientName: String
    let redirectURI: URL
    let clientURI: URL
    let logoURI: URL
    let tosURI: URL
    let policyURI: URL
    let contacts: [String]
    let staticRegistrations: [String: String]
    let dynamicRegistrationsFile: URL
}

#if canImport(MatrixRustSDK)
import MatrixRustSDK

extension OIDCConfigurationProxy {
    var rustValue: OidcConfiguration {
        OidcConfiguration(clientName: clientName,
                          redirectUri: redirectURI.absoluteString,
                          clientUri: clientURI.absoluteString,
                          logoUri: logoURI.absoluteString,
                          tosUri: tosURI.absoluteString,
                          policyUri: policyURI.absoluteString,
                          contacts: contacts,
                          staticRegistrations: staticRegistrations,
                          dynamicRegistrationsFile: dynamicRegistrationsFile.path(percentEncoded: false))
    }
}
#endif
