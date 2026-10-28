//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct NativeCallSystemTests {
    private let service = ElementCallServiceMock(.init())
    
    @Test
    func startingACallSetsUpANativeSession() async {
        let system = NativeCallSystem(service: service)
        
        await system.startCall(roomID: "!room:example.com", displayName: "welcome", isVideo: true)
        
        #expect(service.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.kind == .native)
    }
}
