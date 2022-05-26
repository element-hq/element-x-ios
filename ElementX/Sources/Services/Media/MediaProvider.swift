//
//  MediaProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import MatrixRustSDK
import Kingfisher

struct MediaProvider: MediaProviderProtocol {
    private let client: Client
    private let imageCache: Kingfisher.ImageCache
    private let processingQueue: DispatchQueue
    
    init(client: Client, imageCache: Kingfisher.ImageCache) {
        self.client = client
        self.imageCache = imageCache
        self.processingQueue = DispatchQueue(label: "MediaProviderProcessingQueue", attributes: .concurrent)
    }
    
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        guard let source = source else {
            return nil
        }

        return imageCache.retrieveImageInMemoryCache(forKey: source.underlyingSource.url(), options: nil)
    }
    
    func imageFromURL(_ url: String?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        
        return imageFromSource(MediaSource(source: mediaSourceFromUrl(url: url)))
    }
    
    func loadImageFromURL(_ url: String) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(MediaSource(source: mediaSourceFromUrl(url: url)))
    }
        
    func loadImageFromSource(_ source: MediaSource) async -> Result<UIImage, MediaProviderError> {
        if let image = imageFromSource(source) {
            return .success(image)
        }
        
        let cachedImageLoadResult = await withCheckedContinuation { continuation in
            imageCache.retrieveImage(forKey: source.underlyingSource.url()) { result in
                continuation.resume(returning: result)
            }
        }
        
        if case let .success(cacheResult) = cachedImageLoadResult,
           let image = cacheResult.image {
            return .success(image)
        }
        
        return await Task.detached { () -> Result<UIImage, MediaProviderError> in
            do {
                let imageData = try client.getMediaContent(source: source.underlyingSource)
                
                guard let image = UIImage(data: Data(bytes: imageData, count: imageData.count)) else {
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
