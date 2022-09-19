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
    func imageFromSource(_ source: MediaSource?, size: CGSize?) -> UIImage? {
        nil
    }
    
    func loadImageFromSource(_ source: MediaSource, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }
    
    func imageFromURLString(_ urlString: String?, size: CGSize?) -> UIImage? {
        if urlString != nil {
            return UIImage(systemName: "photo")
        }
        
        return nil
    }
        
    func loadImageFromURLString(_ urlString: String, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }
}
