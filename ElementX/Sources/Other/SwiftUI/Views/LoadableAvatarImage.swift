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

struct LoadableAvatarImage: View {
    private let imageProvider: ImageProviderProtocol?
    private let url: URL?
    private let avatarSize: AvatarSize?
    private let text: String
    private let contentID: String?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(imageProvider: ImageProviderProtocol?, url: URL?, avatarSize: AvatarSize, text: String, contentID: String?) {
        self.imageProvider = imageProvider
        self.url = url
        self.avatarSize = avatarSize
        self.text = text
        self.contentID = contentID
        
        _frameSize = ScaledMetric(wrappedValue: avatarSize.value)
    }
    
    var body: some View {
        LoadableImage(imageProvider: imageProvider,
                      url: url,
                      avatarSize: avatarSize) { image in
            image
                .scaledToFill()
                .frame(width: frameSize, height: frameSize)
                .clipShape(Circle())
        } placeholder: {
            PlaceholderAvatarImage(text: text, contentId: contentID)
                .frame(width: frameSize, height: frameSize)
                .clipShape(Circle())
        }
    }
}
