//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Kingfisher
import VideoPlayer

class FeedMediaPreLoader {
    
    static let shared = FeedMediaPreLoader()
    
    private init() {
        VideoPlayer.preloadByteCount = 1024 * 1024 // = 1M
    }
    
    func preloadImageMedia(_ url: URL, mediaId: String) {
        Task.detached {
            let options: KingfisherOptionsInfo = [
                    .preloadAllAnimationData,
                    .diskCacheExpiration(.days(3)),
                    .cacheOriginalImage
                ]
            KingfisherManager.shared.retrieveImage(with: KF.ImageResource(downloadURL: url, cacheKey: mediaId), options: options) { result in
                switch result {
                case .success(let value):
                    print("KingFisher: ✅ Preloaded image from \(value.cacheType == .none ? "network" : value.cacheType == .memory ? "memory" : "disk")")
                case .failure(let error):
                    print("KingFisher: ❌ Failed to preload image: \(error)")
                }
            }
        }
    }
    
    func preloadVideoMedia(_ url: URL, mediaId: String) {
//        VideoPlayer.preload(urls: [url])
    }
}
