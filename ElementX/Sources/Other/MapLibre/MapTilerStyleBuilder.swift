//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct MapTilerStyleBuilder: MapTilerStyleBuilderProtocol {
    private let baseURL: URL
    private let key: String
    
    init(baseURL: URL, key: String) {
        self.baseURL = baseURL
        self.key = key
    }
    
    func dynamicMapURL(for style: MapTilerStyle) -> URL? {
        var url: URL = baseURL
        url.appendPathComponent(style.rawValue, conformingTo: .item)
        url.appendPathComponent("style.json", conformingTo: .json)
        let authorization = MapTilerAuthorization(key: key)
        return authorization.authorizeURL(url)
    }
}
