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
    private let mediaLoader: MediaLoaderProtocol
    private let imageCache: Kingfisher.ImageCache
    private let fileCache: FileCacheProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol?
    
    init(mediaLoader: MediaLoaderProtocol,
         imageCache: Kingfisher.ImageCache,
         fileCache: FileCacheProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol?) {
        self.mediaLoader = mediaLoader
        self.imageCache = imageCache
        self.fileCache = fileCache
        self.backgroundTaskService = backgroundTaskService
    }
    
    // MARK: Images
    
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        guard let url = source?.url else {
            return nil
        }
        let cacheKey = cacheKeyForURL(url, size: size)
        return imageCache.retrieveImageInMemoryCache(forKey: cacheKey, options: nil)
    }
    
    func imageFromURL(_ url: URL?, size: CGSize?) -> UIImage? {
        guard let url else {
            return nil
        }
        
        return imageFromSource(.init(url: url), size: size)
    }
    
    func loadImageFromURL(_ url: URL, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(.init(url: url), size: size)
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        if let image = imageFromSource(source, size: size) {
            return .success(image)
        }
        
        let loadImageBgTask = await backgroundTaskService?.startBackgroundTask(withName: "LoadImage: \(source.url.hashValue)")
        defer {
            loadImageBgTask?.stop()
        }
        
        let cacheKey = cacheKeyForURL(source.url, size: size)

        if case let .success(cacheResult) = await imageCache.retrieveImage(forKey: cacheKey),
           let image = cacheResult.image {
            return .success(image)
        }

        do {
            let imageData: Data
            if let size {
                imageData = try await mediaLoader.loadMediaThumbnailForSource(source, width: UInt(size.width), height: UInt(size.height))
            } else {
                imageData = try await mediaLoader.loadMediaContentForSource(source)
            }

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
    
    // MARK: Files

    func fileFromSource(_ source: MediaSourceProxy?, fileExtension: String) -> URL? {
        guard let source else {
            return nil
        }
        let cacheKey = fileCacheKeyForURL(source.url)
        return fileCache.file(forKey: cacheKey, fileExtension: fileExtension)
    }
    
    func fileFromURL(_ url: URL?, fileExtension: String) -> URL? {
        guard let url else {
            return nil
        }
        
        return fileFromSource(MediaSourceProxy(url: url), fileExtension: fileExtension)
    }
    
    func loadFileFromURL(_ url: URL, fileExtension: String) async -> Result<URL, MediaProviderError> {
        await loadFileFromSource(MediaSourceProxy(url: url), fileExtension: fileExtension)
    }

    @discardableResult func loadFileFromSource(_ source: MediaSourceProxy, fileExtension: String) async -> Result<URL, MediaProviderError> {
        if let url = fileFromSource(source, fileExtension: fileExtension) {
            return .success(url)
        }

        let loadFileBgTask = await backgroundTaskService?.startBackgroundTask(withName: "LoadFile: \(source.url.hashValue)")
        defer {
            loadFileBgTask?.stop()
        }

        let cacheKey = fileCacheKeyForURL(source.url)
        
        do {
            let data = try await mediaLoader.loadMediaContentForSource(source)
            
            let url = try fileCache.store(data, with: fileExtension, forKey: cacheKey)
            return .success(url)
        } catch {
            MXLog.error("Failed retrieving file with error: \(error)")
            return .failure(.failedRetrievingImage)
        }
    }
    
    // MARK: - Private
    
    private func cacheKeyForURL(_ url: URL, size: CGSize?) -> String {
        if let size {
            return "\(url.absoluteString){\(size.width),\(size.height)}"
        } else {
            return url.absoluteString
        }
    }

    private func fileCacheKeyForURL(_ url: URL) -> String {
        let component = url.lastPathComponent
        guard !component.isEmpty else {
            return url.absoluteString
        }
        return String(component)
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
