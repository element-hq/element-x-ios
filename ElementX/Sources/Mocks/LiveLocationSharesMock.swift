//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct LiveLocationSharesServiceMockConfiguration {
    var shares: [LiveLocationShareProxy] = []
}

extension LiveLocationSharesServiceMock {
    convenience init(_ configuration: LiveLocationSharesServiceMockConfiguration = .init()) {
        self.init()
        liveLocationSharesPublisher = CurrentValueSubject(configuration.shares).eraseToAnyPublisher()
    }
}
