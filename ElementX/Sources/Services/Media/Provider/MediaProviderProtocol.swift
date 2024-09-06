//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

enum MediaProviderError: Error {
    case failedRetrievingImage
    case failedRetrievingFile
    case invalidImageData
    case failedRetrievingThumbnail
    case cancelled
}

protocol MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage?
    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError>
    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError>
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, Error>
    
    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError>
    
    func loadFileFromSource(_ source: MediaSourceProxy, body: String?) async -> Result<MediaFileHandleProxy, MediaProviderError>
}

extension MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?) -> UIImage? {
        imageFromSource(source, size: nil)
    }
    
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy) -> Task<UIImage, Error> {
        loadImageRetryingOnReconnection(source, size: nil)
    }
    
    func loadFileFromSource(_ source: MediaSourceProxy) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        await loadFileFromSource(source, body: nil)
    }
}
