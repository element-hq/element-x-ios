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
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        nil
    }
    
    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }
    
    func imageFromURL(_ url: URL?, size: CGSize?) -> UIImage? {
        guard url != nil else {
            return nil
        }
        
        #warning("Fix me. this is stupid!")
        if let size {
            if size == AvatarSize.room(on: .details).scaledSize
                || size == AvatarSize.room(on: .home).scaledSize
                || size == AvatarSize.room(on: .timeline).scaledSize {
                return Asset.Images.appLogo.image
            }
        }
        return UIImage(systemName: "photo")
    }
    
    func loadImageFromURL(_ url: URL, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
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

    func fileFromURL(_ url: URL?, fileExtension: String) -> URL? {
        nil
    }

    @discardableResult func loadFileFromURL(_ url: URL, fileExtension: String) async -> Result<URL, MediaProviderError> {
        .failure(.failedRetrievingFile)
    }
}
