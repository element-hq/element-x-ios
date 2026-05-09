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

struct RoomTests {
    @Test
    func callIntent() async {
        let room = RoomSDKMock()
        room.hasActiveRoomCallReturnValue = false
        room.isDirectReturnValue = false
        
        var callIntent = await room.joinCallIntent()
        #expect(callIntent == .startCall)
      
        room.isDirectReturnValue = true
        callIntent = await room.joinCallIntent()
        #expect(callIntent == .startCallDm)
        
        callIntent = await room.joinCallIntent(voiceOnly: true)
        #expect(callIntent == .startCallDmVoice)
        
        room.hasActiveRoomCallReturnValue = true
        callIntent = await room.joinCallIntent()
        #expect(callIntent == .joinExistingDm)
        
        callIntent = await room.joinCallIntent(voiceOnly: true)
        #expect(callIntent == .joinExistingDmVoice)
        
        room.isDirectReturnValue = false
        callIntent = await room.joinCallIntent()
        #expect(callIntent == .joinExisting)
    }
}
