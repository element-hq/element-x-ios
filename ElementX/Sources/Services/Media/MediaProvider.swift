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

import Kingfisher
import UIKit

struct MediaProvider: MediaProviderProtocol {
    private let mediaProxy: MediaProxyProtocol
    private let imageCache: Kingfisher.ImageCache
    private let backgroundTaskService: BackgroundTaskServiceProtocol?
    
    init(mediaProxy: MediaProxyProtocol,
         imageCache: Kingfisher.ImageCache,
         backgroundTaskService: BackgroundTaskServiceProtocol?) {
        self.mediaProxy = mediaProxy
        self.imageCache = imageCache
        self.backgroundTaskService = backgroundTaskService
    }
    
    func imageFromSource(_ source: MediaSourceProxy?, avatarSize: AvatarSize?) -> UIImage? {
        guard let source else {
            return nil
        }
        let cacheKey = cacheKeyForURLString(source.url, avatarSize: avatarSize)
        return imageCache.retrieveImageInMemoryCache(forKey: cacheKey, options: nil)
    }
    
    func imageFromURLString(_ urlString: String?, avatarSize: AvatarSize?) -> UIImage? {
        guard let urlString else {
            return nil
        }
        
        return imageFromSource(.init(urlString: urlString), avatarSize: avatarSize)
    }
    
    func loadImageFromURLString(_ urlString: String, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(.init(urlString: urlString), avatarSize: avatarSize)
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError> {
        if let image = imageFromSource(source, avatarSize: avatarSize) {
            return .success(image)
        }

        let loadImageBgTask = backgroundTaskService?.startBackgroundTask(withName: "LoadImage: \(source.url.hashValue)")
        defer {
            loadImageBgTask?.stop()
        }
        
        let cacheKey = cacheKeyForURLString(source.url, avatarSize: avatarSize)
        
        return await Task.detached { () -> Result<UIImage, MediaProviderError> in
            if case let .success(cacheResult) = await imageCache.retrieveImage(forKey: cacheKey),
               let image = cacheResult.image {
                return .success(image)
            }
            
            do {
                let imageData = try await Task.detached { () -> Data in
                    if let avatarSize {
                        return try await mediaProxy.loadMediaThumbnailForSource(source, width: UInt(avatarSize.scaledValue), height: UInt(avatarSize.scaledValue))
                    } else {
                        return try await mediaProxy.loadMediaContentForSource(source)
                    }
                    
                }.value
                
                guard let image = UIImage(data: imageData) else {
                    MXLog.error("Invalid image data")
                    return .failure(.invalidImageData)
                }
                
                imageCache.store(image, forKey: cacheKey)
                
                return .success(image)
            } catch {
                MXLog.error("Failed retrieving image with error: \(error)")
                return .failure(.failedRetrievingImage)
            }
        }
        .value
    }
    
    // MARK: - Private
    
    private func cacheKeyForURLString(_ urlString: String, avatarSize: AvatarSize?) -> String {
        if let avatarSize {
            return "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        } else {
            return urlString
        }
    }
}

private extension ImageCache {
    func retrieveImage(forKey key: String) async -> Result<ImageCacheResult, KingfisherError> {
        await withCheckedContinuation { continuation in
            retrieveImage(forKey: key) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
