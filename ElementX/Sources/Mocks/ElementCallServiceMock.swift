//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension ElementCallServiceMock {
    struct Configuration {
        var userID = "@alice:matrix.org"
        var ongoingCallRoomID: String?
    }
    
    /// The ongoing call room it's told about is published back, as the real service does.
    convenience init(_ configuration: Configuration) {
        self.init()
        
        userID = configuration.userID
        actionsPublisher = PassthroughSubject<ElementCallServiceAction, Never>().eraseToAnyPublisher()
        
        let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(configuration.ongoingCallRoomID)
        ongoingCallRoomIDPublisher = ongoingCallRoomIDSubject.asCurrentValuePublisher()
        ongoingCallChangedRoomIDClosure = { ongoingCallRoomIDSubject.send($0) }
    }
}
