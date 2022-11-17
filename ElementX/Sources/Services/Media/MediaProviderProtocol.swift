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
}

protocol MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?, avatarSize: AvatarSize?) -> UIImage?
    
    @discardableResult func loadImageFromSource(_ source: MediaSourceProxy, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError>
    
    func imageFromURLString(_ urlString: String?, avatarSize: AvatarSize?) -> UIImage?
    
    @discardableResult func loadImageFromURLString(_ urlString: String, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError>

    func fileFromSource(_ source: MediaSourceProxy?, fileExtension: String) -> URL?

    @discardableResult func loadFileFromSource(_ source: MediaSourceProxy, fileExtension: String) async -> Result<URL, MediaProviderError>

    func fileFromURLString(_ urlString: String?, fileExtension: String) -> URL?

    @discardableResult func loadFileFromURLString(_ urlString: String, fileExtension: String) async -> Result<URL, MediaProviderError>
}

extension MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?) -> UIImage? {
        imageFromSource(source, avatarSize: nil)
    }
    
    @discardableResult func loadImageFromSource(_ source: MediaSourceProxy) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(source, avatarSize: nil)
    }
    
    func imageFromURLString(_ urlString: String?) -> UIImage? {
        imageFromURLString(urlString, avatarSize: nil)
    }
    
    @discardableResult func loadImageFromURLString(_ urlString: String) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromURLString(urlString, avatarSize: nil)
    }
}
