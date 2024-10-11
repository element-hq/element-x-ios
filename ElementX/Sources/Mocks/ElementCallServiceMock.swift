//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct ElementCallServiceMockConfiguration {
    var ongoingCallRoomID: String?
}

extension ElementCallServiceMock {
    convenience init(_ configuration: ElementCallServiceMockConfiguration) {
        self.init()
        
        underlyingActions = PassthroughSubject().eraseToAnyPublisher()
        underlyingOngoingCallRoomIDPublisher = .init(.init(configuration.ongoingCallRoomID))
    }
}
