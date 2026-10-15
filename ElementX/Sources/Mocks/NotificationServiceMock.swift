//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct NotificationServiceMockConfiguration {
    var userID = "@alice:matrix.org"
    var isEnabled = true
    var badgeCount = 0
}

extension NotificationServiceMock {
    convenience init(_ configuration: NotificationServiceMockConfiguration) {
        self.init()
        
        userID = configuration.userID
        isEnabled = configuration.isEnabled
        actionsPublisher = PassthroughSubject<NotificationServiceAction, Never>().eraseToAnyPublisher()
        badgeCountPublisher = CurrentValueSubject(configuration.badgeCount).asCurrentValuePublisher()
    }
}
