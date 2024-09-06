//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

struct MockMediaProvider: MediaProviderProtocol {
    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        fatalError("Not implemented")
    }
    
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        guard source != nil else {
            return nil
        }
        
        if source?.url == .picturesDirectory {
            return Asset.Images.appLogo.image
        }
        
        return UIImage(systemName: "photo")
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        guard let image = UIImage(systemName: "photo") else {
            fatalError()
        }
        
        return .success(image)
    }
    
    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError> {
        guard let image = UIImage(systemName: "photo"),
              let data = image.pngData() else {
            fatalError()
        }
        
        return .success(data)
    }
    
    var loadFileFromSourceReturnValue: MediaFileHandleProxy?
    func loadFileFromSource(_ source: MediaSourceProxy, body: String?) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        if let loadFileFromSourceReturnValue {
            return .success(loadFileFromSourceReturnValue)
        }
        return .failure(.failedRetrievingFile)
    }
    
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, any Error> {
        Task {
            guard let image = UIImage(systemName: "photo") else {
                fatalError()
            }
            
            return image
        }
    }
}
