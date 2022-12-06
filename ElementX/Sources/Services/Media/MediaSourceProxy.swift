//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixRustSDK

struct MediaSourceProxy: Hashable {
    let underlyingSource: MediaSource
    
    init(source: MediaSource) {
        underlyingSource = source
    }
    
    init(urlString: String) {
        underlyingSource = mediaSourceFromUrl(url: urlString)
    }

    var url: String {
        underlyingSource.url()
    }
    
}

// MARK: - Hashable

extension MediaSource: Hashable {
    public static func == (lhs: MediaSource, rhs: MediaSource) -> Bool {
        lhs.url() == rhs.url()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url())
    }
}
