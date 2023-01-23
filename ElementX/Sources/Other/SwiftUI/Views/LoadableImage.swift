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

import SwiftUI

struct LoadableImage<ContainerView: View, PlaceholderView: View>: View {
    private let imageProvider: ImageProviderProtocol?
    private let mediaSource: MediaSourceProxy?
    private let blurhash: String?
    private let avatarSize: AvatarSize?
    
    private var container: (Image) -> ContainerView
    private let placeholder: () -> PlaceholderView
    
    @State private var image: UIImage?
    
    /// A SwiftUI view that automatically fetches images
    /// It will try fetching the image from in-memory cache and if that's not available
    /// it will fire a task to load it through the image provider
    /// - Parameters:
    ///   - mediaSource: the source of the image
    ///   - blurhash: an optional blurhash
    ///   - container: entry point for configuring the resulting image view
    ///   - placeholder: a view to show while the image or blurhash are not available
    init(imageProvider: ImageProviderProtocol?,
         mediaSource: MediaSourceProxy?,
         blurhash: String?,
         avatarSize: AvatarSize? = nil,
         container: @escaping (Image) -> ContainerView = { $0 },
         placeholder: @escaping () -> PlaceholderView) {
        self.imageProvider = imageProvider
        self.mediaSource = mediaSource
        self.blurhash = blurhash
        self.avatarSize = avatarSize
        
        self.container = container
        self.placeholder = placeholder
        
        _image = State(initialValue: imageProvider?.imageFromSource(mediaSource, avatarSize: avatarSize))
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                container(
                    Image(uiImage: image)
                        .resizable()
                )
            } else if let blurhash = blurhash,
                      // Build a small blurhash image so that it's fast
                      let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
                container(
                    Image(uiImage: image)
                        .resizable()
                )
            } else {
                placeholder()
            }
        }
        .animation(.elementDefault, value: image)
        .task {
            guard image == nil, let mediaSource else { return }
            
            if case let .success(image) = await imageProvider?.loadImageFromSource(mediaSource, avatarSize: avatarSize) {
                self.image = image
            }
        }
    }
}
