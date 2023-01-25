//
// Copyright 2023 New Vector Ltd
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

import UIKit

protocol ImageProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage?
    
    @discardableResult func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError>
    
    func imageFromURL(_ url: URL?, size: CGSize?) -> UIImage?
    
    @discardableResult func loadImageFromURL(_ url: URL, size: CGSize?) async -> Result<UIImage, MediaProviderError>
}

extension ImageProviderProtocol {
    func imageFromSource(_ source: MediaSourceProxy?) -> UIImage? {
        imageFromSource(source, size: nil)
    }
    
    @discardableResult func loadImageFromSource(_ source: MediaSourceProxy) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromSource(source, size: nil)
    }
    
    func imageFromURL(_ url: URL?) -> UIImage? {
        imageFromURL(url, size: nil)
    }
    
    @discardableResult func loadImageFromURL(_ url: URL) async -> Result<UIImage, MediaProviderError> {
        await loadImageFromURL(url, size: nil)
    }
}
