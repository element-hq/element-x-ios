//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct OverridableAvatarImage: View {
    private let overrideURL: URL?
    private let url: URL?
    private let name: String?
    private let contentID: String?
    private let avatarSize: AvatarSize
    private let mediaProvider: MediaProviderProtocol?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(overrideURL: URL?, url: URL?, name: String?, contentID: String?, avatarSize: AvatarSize, mediaProvider: MediaProviderProtocol?) {
        self.overrideURL = overrideURL
        self.url = url
        self.name = name
        self.contentID = contentID
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        
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
                                mediaProvider: mediaProvider)
        }
    }
}
