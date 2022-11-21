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
import Kingfisher

extension ImageCache {
    static var onlyInMemory: ImageCache {
        let result = ImageCache.default
        result.diskStorage.config.sizeLimit = 1
        return result
    }

    static var onlyOnDisk: ImageCache {
        let result = ImageCache.default
        result.memoryStorage.config.totalCostLimit = 1
        return result
    }
}
