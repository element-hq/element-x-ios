//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension RoomListServiceSDKMock {
    struct Configuration {
        var roomList = RoomListSDKMock(.init())
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        allRoomsReturnValue = configuration.roomList
        stateListenerReturnValue = TaskHandleSDKMock()
        syncIndicatorDelayBeforeShowingInMsDelayBeforeHidingInMsListenerReturnValue = TaskHandleSDKMock()
    }
}
