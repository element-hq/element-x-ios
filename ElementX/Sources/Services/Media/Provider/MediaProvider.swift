//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Kingfisher
import UIKit

struct MediaProvider: MediaProviderProtocol {
    private let mediaLoader: MediaLoaderProtocol
    private let imageCache: Kingfisher.ImageCache
    private let networkMonitor: NetworkMonitorProtocol?
    
    init(mediaLoader: MediaLoaderProtocol,
         imageCache: Kingfisher.ImageCache,
         networkMonitor: NetworkMonitorProtocol?) {
        self.mediaLoader = mediaLoader
        self.imageCache = imageCache
        self.networkMonitor = networkMonitor
    }
    
    // MARK: Images
    
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        guard let url = source?.url else {
            return nil
        }
        let cacheKey = cacheKeyForURL(url, size: size)
        return imageCache.retrieveImageInMemoryCache(forKey: cacheKey, options: nil)
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        if let image = imageFromSource(source, size: size) {
            return .success(image)
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
    
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, any Error> {
        guard let networkMonitor else {
            fatalError("This method shouldn't be invoked without a NetworkMonitor set.")
        }
        
        return Task {
            if case let .success(image) = await loadImageFromSource(source, size: size) {
                return image
            }
            
            guard !Task.isCancelled else {
                throw MediaProviderError.cancelled
            }
            
            for await reachability in networkMonitor.reachabilityPublisher.values {
                guard !Task.isCancelled else {
                    throw MediaProviderError.cancelled
                }
                
                guard reachability == .reachable else {
                    continue
                }
                
                switch await loadImageFromSource(source, size: size) {
                case .success(let image):
                    return image
                case .failure:
                    // If it fails after a retry with the network available
                    // then something else must be wrong. Bail out.
                    if reachability == .reachable {
                        throw MediaProviderError.cancelled
                    }
                }
            }
            
            throw MediaProviderError.cancelled
        }
    }
    
    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError> {
        do {
            let imageData = try await mediaLoader.loadMediaContentForSource(source)
            return .success(imageData)
        } catch {
            MXLog.error("Failed retrieving image with error: \(error)")
            return .failure(.failedRetrievingImage)
        }
    }
    
    // MARK: Files
    
    func loadFileFromSource(_ source: MediaSourceProxy, body: String?) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        do {
            let file = try await mediaLoader.loadMediaFileForSource(source, body: body)
            return .success(file)
        } catch {
            MXLog.error("Failed retrieving file with error: \(error)")
            return .failure(.failedRetrievingFile)
        }
    }
    
    // MARK: Thumbnail
    
    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        do {
            let thumbnailData = try await mediaLoader.loadMediaThumbnailForSource(source, width: UInt(size.width), height: UInt(size.height))
            return .success(thumbnailData)
        } catch {
            MXLog.error("Failed retrieving image with error: \(error)")
            return .failure(.failedRetrievingThumbnail)
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
