//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@Suite
struct RoomTests {
    @Test
    func callIntent() async {
        let room = RoomSDKMock()
        room.hasActiveRoomCallReturnValue = false
        room.isDirectReturnValue = false
        
        var callIntent = await room.joinCallIntent
        #expect(callIntent == .startCall)
        
        room.isDirectReturnValue = true
        callIntent = await room.joinCallIntent
        #expect(callIntent == .startCallDm)
        
        room.hasActiveRoomCallReturnValue = true
        callIntent = await room.joinCallIntent
        #expect(callIntent == .joinExistingDm)
        
        room.isDirectReturnValue = false
        callIntent = await room.joinCallIntent
        #expect(callIntent == .joinExisting)
    }
}
