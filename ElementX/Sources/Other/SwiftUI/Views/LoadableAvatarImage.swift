//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct LoadableAvatarImage: View {
    private let url: URL?
    private let name: String?
    private let contentID: String?
    private let avatarSize: AvatarSize
    private let mediaProvider: MediaProviderProtocol?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(url: URL?, name: String?, contentID: String?, avatarSize: AvatarSize, mediaProvider: MediaProviderProtocol?) {
        self.url = url
        self.name = name
        self.contentID = contentID
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        
        _frameSize = ScaledMetric(wrappedValue: avatarSize.value)
    }
    
    var body: some View {
        avatar
            .frame(width: frameSize, height: frameSize)
            .background(Color.compound.bgCanvasDefault)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    var avatar: some View {
        if let url {
            LoadableImage(url: url,
                          mediaType: .avatar,
                          size: avatarSize.scaledSize,
                          mediaProvider: mediaProvider) { image in
                image
                    .scaledToFill()
            } placeholder: {
                PlaceholderAvatarImage(name: name, contentID: contentID)
            }
        } else {
            PlaceholderAvatarImage(name: name, contentID: contentID)
        }
    }
}
