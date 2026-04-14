//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct RoomLiveLocationServiceMockConfiguration {
    var shares: [LiveLocationShare] = []
}

extension RoomLiveLocationServiceMock {
    convenience init(_ configuration: RoomLiveLocationServiceMockConfiguration = .init()) {
        self.init()
        liveLocationsPublisher = CurrentValueSubject(configuration.shares).eraseToAnyPublisher()
    }
}
