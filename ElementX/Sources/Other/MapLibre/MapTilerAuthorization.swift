//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct MapTilerAuthorization {
    private let key: String
    
    init(key: String) {
        self.key = key
    }
    
    func authorizeURL(_ url: URL) -> URL {
        url.appending(queryItems: [URLQueryItem(name: "key", value: key)])
    }
}
