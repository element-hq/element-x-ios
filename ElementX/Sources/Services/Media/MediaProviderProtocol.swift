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
    case invalidImageData
}

@MainActor
protocol MediaProviderProtocol {
    func imageFromSource(_ source: MediaSource?, size: AvatarSize?) -> UIImage?
    
    @discardableResult func loadImageFromSource(_ source: MediaSource, size: AvatarSize?) async -> Result<UIImage, MediaProviderError>
    
    func imageFromURLString(_ urlString: String?, size: AvatarSize?) -> UIImage?
    
    @discardableResult func loadImageFromURLString(_ urlString: String, size: AvatarSize?) async -> Result<UIImage, MediaProviderError>
}

extension MediaProviderProtocol {
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        imageFromSource(source, size: nil)
    }
    
    @discardableResult func loadImageFromSource(_ source: MediaSource) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(source, size: nil)
    }
    
    func imageFromURLString(_ urlString: String?) -> UIImage? {
        imageFromURLString(urlString, size: nil)
    }
    
    @discardableResult func loadImageFromURLString(_ urlString: String) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromURLString(urlString, size: nil)
    }
}
