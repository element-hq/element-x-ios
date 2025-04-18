//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension AuthenticationClientBuilderFactoryMock {
    struct Configuration {
        var builderConfiguration: AuthenticationClientBuilderMock.Configuration = .init()
    }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        let clientBuilder = AuthenticationClientBuilderMock(configuration: configuration.builderConfiguration)
        makeBuilderSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReturnValue = clientBuilder
    }
}
