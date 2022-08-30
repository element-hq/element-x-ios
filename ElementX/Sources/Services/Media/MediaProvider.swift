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
    private let clientProxy: ClientProxyProtocol
    private let imageCache: Kingfisher.ImageCache
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    init(clientProxy: ClientProxyProtocol,
         imageCache: Kingfisher.ImageCache,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.clientProxy = clientProxy
        self.imageCache = imageCache
        self.backgroundTaskService = backgroundTaskService
    }
    
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        guard let source = source else {
            return nil
        }

        return imageCache.retrieveImageInMemoryCache(forKey: source.underlyingSource.url(), options: nil)
    }
    
    func imageFromURLString(_ urlString: String?) -> UIImage? {
        guard let urlString = urlString else {
            return nil
        }
        
        return imageFromSource(MediaSource(source: clientProxy.mediaSourceForURLString(urlString)))
    }
    
    func loadImageFromURLString(_ urlString: String) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(MediaSource(source: clientProxy.mediaSourceForURLString(urlString)))
    }
    
    func loadImageFromSource(_ source: MediaSource) async -> Result<UIImage, MediaProviderError> {
        if let image = imageFromSource(source) {
            return .success(image)
        }

        let loadImageBgTask = backgroundTaskService.startBackgroundTask(withName: "LoadImage: \(source.underlyingSource.url().hashValue)")
        defer {
            loadImageBgTask?.stop()
        }
        
        return await Task.detached { () -> Result<UIImage, MediaProviderError> in
            if case let .success(cacheResult) = await imageCache.retrieveImage(forKey: source.underlyingSource.url()),
               let image = cacheResult.image {
                return .success(image)
            }
            
            do {
                let imageData = try clientProxy.loadMediaContentForSource(source.underlyingSource)
                
                guard let image = UIImage(data: imageData) else {
                    MXLog.error("Invalid image data")
                    return .failure(.invalidImageData)
                }
                
                imageCache.store(image, forKey: source.underlyingSource.url())
                
                return .success(image)
            } catch {
                MXLog.error("Failed retrieving image with error: \(error)")
                return .failure(.failedRetrievingImage)
            }
        }
        .value
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
