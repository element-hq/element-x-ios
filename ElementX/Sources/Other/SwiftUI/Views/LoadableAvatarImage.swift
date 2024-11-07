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
    private let onTap: ((URL) -> Void)?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(url: URL?, name: String?,
         contentID: String?,
         avatarSize: AvatarSize,
         mediaProvider: MediaProviderProtocol?,
         onTap: ((URL) -> Void)? = nil) {
        self.url = url
        self.name = name
        self.contentID = contentID
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        self.onTap = onTap
        
        _frameSize = ScaledMetric(wrappedValue: avatarSize.value)
    }
    
    var body: some View {
        if let onTap, let url {
            Button {
                onTap(url)
            } label: {
                clippedAvatar
            }
            .buttonStyle(.borderless) // Add a button style to stop the whole row being tappable.
        } else {
            clippedAvatar
        }
    }
    
    private var clippedAvatar: some View {
        avatar
            .frame(width: frameSize, height: frameSize)
            .background(Color.compound.bgCanvasDefault)
            .clipShape(Circle())
            .environment(\.shouldAutomaticallyLoadImages, true) // We always load avatars.
    }
    
    @ViewBuilder
    private var avatar: some View {
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
