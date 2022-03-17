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
    
    init(client: Client, imageCache: Kingfisher.ImageCache) {
        self.client = client
        self.imageCache = imageCache
    }
    
    func loadCurrentUserAvatar(_ completion: @escaping (Result<UIImage?, MediaProviderError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let imageData = try self.client.avatar()
                DispatchQueue.main.async {
                    completion(.success(UIImage(data: Data(bytes: imageData, count: imageData.count))))
                }
            } catch {
                MXLog.error("Failed retrieving image with error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.failedRetrievingImage))
                }
            }
        }
    }
    
    func hasImageCachedForURL(_ url: String) -> Bool {
        self.imageCache.imageCachedType(forKey: url) == .memory
    }
    
    func loadImageFromURL(_ url: String, _ completion: @escaping (Result<UIImage, MediaProviderError>) -> Void) {
        self.imageCache.retrieveImage(forKey: url) { result in
            if case let .success(cacheResult) = result,
               let image = cacheResult.image {
                completion(.success(image))
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                let imageData = try self.client.loadImage(url: url)
                
                guard let image = UIImage(data: Data(bytes: imageData, count: imageData.count)) else {
                    MXLog.error("Invalid image data")
                    DispatchQueue.main.async {
                        completion(.failure(.invalidImageData))
                    }
                    return
                }
                
                self.imageCache.store(image, forKey: url)
                
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            } catch {
                MXLog.error("Failed retrieving image with error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.failedRetrievingImage))
                }
            }
        }
    }
}
