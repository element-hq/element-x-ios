//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LoadableAvatarImage: View {
    enum Shape {
        case circle
        case roundedRect
    }
    
    private let url: URL?
    private let name: String?
    private let contentID: String
    private let shape: Shape
    private let avatarSize: Avatars.Size
    private let mediaProvider: MediaProviderProtocol?
    private let onTap: ((URL) -> Void)?
    
    @ScaledMetric private var frameSize: CGFloat
    
    init(url: URL?,
         name: String?,
         contentID: String,
         shape: LoadableAvatarImage.Shape = .circle,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol?,
         onTap: ((URL) -> Void)? = nil) {
        self.url = url
        self.name = name
        self.contentID = contentID
        self.shape = shape
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
            .avatarShape(shape, scaledSize: _frameSize)
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
    func avatarShape(_ shape: LoadableAvatarImage.Shape, size: CGFloat) -> some View {
        modifier(AvatarShapeModifier(shape: shape, size: size))
    }
    
    func avatarShape(_ shape: LoadableAvatarImage.Shape, scaledSize: ScaledMetric<CGFloat>) -> some View {
        modifier(AvatarShapeModifier(shape: shape, scaledSize: scaledSize))
    }
}

private struct AvatarShapeModifier: ViewModifier {
    private let shape: LoadableAvatarImage.Shape
    @ScaledMetric private var scaledSize: CGFloat
    
    init(shape: LoadableAvatarImage.Shape, size: CGFloat) {
        self.shape = shape
        _scaledSize = ScaledMetric(wrappedValue: size)
    }
    
    init(shape: LoadableAvatarImage.Shape, scaledSize: ScaledMetric<CGFloat>) {
        self.shape = shape
        _scaledSize = scaledSize
    }
    
    func body(content: Content) -> some View {
        switch shape {
        case .circle:
            content.clipShape(Circle())
        case .roundedRect:
            let shape = RoundedRectangle(cornerRadius: scaledSize / 4)
            content
                .clipShape(shape)
                .overlay(shape.stroke(.compound.iconQuaternaryAlpha, lineWidth: 1))
        }
    }
}
