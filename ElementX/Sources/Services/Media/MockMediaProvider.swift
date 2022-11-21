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

struct MockMediaProvider: MediaProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?, avatarSize: AvatarSize?) -> UIImage? {
        nil
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }
    
    func imageFromURLString(_ urlString: String?, avatarSize: AvatarSize?) -> UIImage? {
        guard urlString != nil else {
            return nil
        }

        if let avatarSize {
            switch avatarSize {
            case .room:
                return Asset.Images.appLogo.image
            default:
                return UIImage(systemName: "photo")
            }
        }
        return UIImage(systemName: "photo")
    }
        
    func loadImageFromURLString(_ urlString: String, avatarSize: AvatarSize?) async -> Result<UIImage, MediaProviderError> {
        guard let image = UIImage(systemName: "photo") else {
            fatalError()
        }
        
        return .success(image)
    }

    func fileFromSource(_ source: MediaSourceProxy?, fileExtension: String) -> URL? {
        nil
    }

    @discardableResult func loadFileFromSource(_ source: MediaSourceProxy, fileExtension: String) async -> Result<URL, MediaProviderError> {
        .failure(.failedRetrievingFile)
    }

    func fileFromURLString(_ urlString: String?, fileExtension: String) -> URL? {
        nil
    }

    @discardableResult func loadFileFromURLString(_ urlString: String, fileExtension: String) async -> Result<URL, MediaProviderError> {
        .failure(.failedRetrievingFile)
    }
}
