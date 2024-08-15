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
