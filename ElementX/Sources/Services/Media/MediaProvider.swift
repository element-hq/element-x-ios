//
//  MediaProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Kingfisher
import UIKit

struct MediaProvider: MediaProviderProtocol {
    private let clientProxy: ClientProxyProtocol
    private let imageCache: Kingfisher.ImageCache
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let processingQueue: DispatchQueue
    
    init(clientProxy: ClientProxyProtocol,
         imageCache: Kingfisher.ImageCache,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.clientProxy = clientProxy
        self.imageCache = imageCache
        self.backgroundTaskService = backgroundTaskService
        processingQueue = DispatchQueue(label: "MediaProviderProcessingQueue", attributes: .concurrent)
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
            let cachedImageLoadResult = await withCheckedContinuation { continuation in
                imageCache.retrieveImage(forKey: source.underlyingSource.url()) { result in
                    continuation.resume(returning: result)
                }
            }
            
            if case let .success(cacheResult) = cachedImageLoadResult,
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
