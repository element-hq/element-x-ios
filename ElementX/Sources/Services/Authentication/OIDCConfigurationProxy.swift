//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
