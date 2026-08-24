//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension SyncServiceBuilderSDKMock {
    struct Configuration {
        var syncService = SyncServiceSDKMock(.init())
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        withOfflineModeClosure = { [unowned self] in self }
        withSharePosEnableClosure = { [unowned self] _ in self }
        withProfilesExtensionClosure = { [unowned self] in self }
        finishReturnValue = configuration.syncService
    }
}
