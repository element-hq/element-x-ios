//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct RoomDirectorySearchProxyMockConfiguration {
    let results: [RoomDirectorySearchResult]
}

extension RoomDirectorySearchProxyMock {
    convenience init(configuration: RoomDirectorySearchProxyMockConfiguration) {
        self.init()
        resultsPublisher = CurrentValueSubject(configuration.results).asCurrentValuePublisher()
        searchQueryReturnValue = .success(())
        nextPageReturnValue = .success(())
    }
}
