//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

extension ElementCallServiceMock {
    struct Configuration {
        var userID = "@alice:matrix.org"
        var ongoingCallRoomID: String?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        userID = configuration.userID
        actionsPublisher = PassthroughSubject().eraseToAnyPublisher()
        nativeCallEventsPublisher = PassthroughSubject().eraseToAnyPublisher()
        
        let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(configuration.ongoingCallRoomID)
        ongoingCallRoomIDPublisher = ongoingCallRoomIDSubject.asCurrentValuePublisher()
        ongoingCallChangedRoomIDClosure = { roomID in
            ongoingCallRoomIDSubject.send(roomID)
        }
        
        handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReturnValue = false
    }
}

extension ElementCallServiceAction.RoomCall {
    static func mock(roomID: String = "!room:example.com", isVoiceCall: Bool = false) -> Self {
        .init(roomProxy: JoinedRoomProxyMock(.init(id: roomID)), isVoiceCall: isVoiceCall)
    }
}
