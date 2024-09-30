//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Kingfisher

extension ImageCache {
    static var onlyInMemory: ImageCache {
        let result = ImageCache.default
        result.memoryStorage.config.keepWhenEnteringBackground = true
        result.diskStorage.config.sizeLimit = 1
        return result
    }

    static var onlyOnDisk: ImageCache {
        let result = ImageCache.default
        result.memoryStorage.config.totalCostLimit = 1
        return result
    }
}
