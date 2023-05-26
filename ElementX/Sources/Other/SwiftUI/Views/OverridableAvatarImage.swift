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

struct OverridableAvatarImage: View {
    private let overrideURL: URL?
    private let url: URL?
    private let name: String?
    private let contentID: String?
    private let avatarSize: AvatarSize
    private let imageProvider: ImageProviderProtocol?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(overrideURL: URL?, url: URL?, name: String?, contentID: String?, avatarSize: AvatarSize, imageProvider: ImageProviderProtocol?) {
        self.overrideURL = overrideURL
        self.url = url
        self.name = name
        self.contentID = contentID
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        
        _frameSize = ScaledMetric(wrappedValue: avatarSize.value)
    }
    
    var body: some View {
        if let overrideURL {
            AsyncImage(url: overrideURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: frameSize, height: frameSize)
            .clipShape(Circle())
        } else {
            LoadableAvatarImage(url: url,
                                name: name,
                                contentID: contentID,
                                avatarSize: avatarSize,
                                imageProvider: imageProvider)
        }
    }
}
