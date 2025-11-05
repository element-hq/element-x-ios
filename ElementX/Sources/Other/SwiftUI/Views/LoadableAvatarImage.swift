//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LoadableAvatarImage: View {
    private let url: URL?
    private let name: String?
    private let contentID: String
    private let isSpace: Bool
    private let avatarSize: Avatars.Size
    private let mediaProvider: MediaProviderProtocol?
    private let onTap: ((URL) -> Void)?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(url: URL?,
         name: String?,
         contentID: String,
         isSpace: Bool = false,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol?,
         onTap: ((URL) -> Void)? = nil) {
        self.url = url
        self.name = name
        self.contentID = contentID
        self.isSpace = isSpace
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
            .clipAvatar(isSpace: isSpace, scaledSize: _frameSize)
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

extension View {
    func clipAvatar(isSpace: Bool, size: CGFloat) -> some View {
        modifier(ClipAvatarModifier(isSpace: isSpace, size: size))
    }
    
    func clipAvatar(isSpace: Bool, scaledSize: ScaledMetric<CGFloat>) -> some View {
        modifier(ClipAvatarModifier(isSpace: isSpace, scaledSize: scaledSize))
    }
}

struct ClipAvatarModifier: ViewModifier {
    private let isSpace: Bool
    @ScaledMetric private var scaledSize: CGFloat
    
    init(isSpace: Bool, size: CGFloat) {
        self.isSpace = isSpace
        _scaledSize = ScaledMetric(wrappedValue: size)
    }
    
    init(isSpace: Bool, scaledSize: ScaledMetric<CGFloat>) {
        self.isSpace = isSpace
        _scaledSize = scaledSize
    }
    
    func body(content: Content) -> some View {
        content
            .clipShape(avatarShape)
    }
    
    private var avatarShape: some Shape {
        isSpace ? AnyShape(RoundedRectangle(cornerRadius: scaledSize / 4)) : AnyShape(Circle())
    }
}
