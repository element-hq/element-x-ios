//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct AuthenticationClientBuilderMockConfiguration {
    var builtClient: ClientProtocol
}

extension AuthenticationClientBuilderMock {
    convenience init(configuration: AuthenticationClientBuilderMockConfiguration) {
        self.init()
        
        buildHomeserverAddressReturnValue = configuration.builtClient
        buildWithQRCodeQrCodeDataOidcConfigurationProgressListenerReturnValue = configuration.builtClient
    }
}
