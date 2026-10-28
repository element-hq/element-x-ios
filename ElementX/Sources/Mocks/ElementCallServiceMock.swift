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
        var ongoingCallRoomID: String?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        actionsPublisher = PassthroughSubject().eraseToAnyPublisher()
        nativeCallEventsPublisher = PassthroughSubject().eraseToAnyPublisher()
        nativeCallPresentationPublisher = PassthroughSubject().eraseToAnyPublisher()
        
        let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(configuration.ongoingCallRoomID)
        ongoingCallRoomIDPublisher = ongoingCallRoomIDSubject.asCurrentValuePublisher()
        ongoingCallChangedRoomIDClosure = { roomID in
            ongoingCallRoomIDSubject.send(roomID)
        }
        
        handleNativeCallRequestRoomProxyIsVoiceCallReturnValue = false
    }
}
