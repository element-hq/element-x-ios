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

struct MediaSource: Equatable {
    let underlyingSource: MatrixRustSDK.MediaSource
    
    init(source: MatrixRustSDK.MediaSource) {
        underlyingSource = source
    }
    
    init(urlString: String) {
        underlyingSource = MatrixRustSDK.mediaSourceFromUrl(url: urlString)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: MediaSource, rhs: MediaSource) -> Bool {
        lhs.underlyingSource.url() == rhs.underlyingSource.url()
    }
}
