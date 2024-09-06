//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct MediaSourceProxy: Hashable {
    /// The media source provided by Rust.
    let underlyingSource: MediaSource
    /// The media's mime type, used when loading the media's file.
    /// This is optional when loading images and thumbnails in memory.
    let mimeType: String?
    
    let url: URL!
    
    init(source: MediaSource, mimeType: String?) {
        underlyingSource = source
        url = URL(string: underlyingSource.url())
        self.mimeType = mimeType
    }
    
    init(url: URL, mimeType: String?) {
        underlyingSource = mediaSourceFromUrl(url: url.absoluteString)
        self.url = URL(string: underlyingSource.url())
        self.mimeType = mimeType
    }
    
    // MARK: - Hashable
    
    static func == (lhs: MediaSourceProxy, rhs: MediaSourceProxy) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
