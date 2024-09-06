//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//
@testable import ElementX
import Kingfisher
import UIKit

class MockImageCache: ImageCache {
    var retrievedImagesInMemory = [String: UIImage]()
    var retrievedImages = [String: UIImage]()
    var storedImages = [String: UIImage]()

    override func retrieveImageInMemoryCache(forKey key: String, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        retrievedImagesInMemory[key]
    }
    
    override func retrieveImage(forKey key: String, options: KingfisherOptionsInfo? = nil, callbackQueue: CallbackQueue = .mainCurrentOrAsync, completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?) {
        if let image = retrievedImages[key] {
            completionHandler?(.success(ImageCacheResult.disk(image)))
        } else {
            let error = KingfisherError.cacheError(reason: .imageNotExisting(key: key))
            completionHandler?(.failure(error))
        }
    }
    
    override func store(_ image: KFCrossPlatformImage,
                        original: Data? = nil,
                        forKey key: String,
                        processorIdentifier identifier: String = "",
                        cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                        toDisk: Bool = true,
                        callbackQueue: CallbackQueue = .untouch,
                        completionHandler: ((CacheStoreResult) -> Void)? = nil) {
        storedImages[key] = image
    }
}
