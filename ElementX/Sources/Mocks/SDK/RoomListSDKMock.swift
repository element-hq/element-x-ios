//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension RoomListSDKMock {
    struct Configuration {
        var loadingState: RoomListLoadingState = .notLoaded
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        let dynamicAdapters = RoomListEntriesWithDynamicAdaptersResultSDKMock()
        let entriesController = RoomListDynamicEntriesControllerSDKMock()
        entriesController.setFilterKindReturnValue = true
        dynamicAdapters.controllerReturnValue = entriesController
        
        entriesWithDynamicAdaptersPageSizeListenerReturnValue = dynamicAdapters
        loadingStateListenerReturnValue = .init(state: configuration.loadingState, stateStream: TaskHandleSDKMock())
    }
}
