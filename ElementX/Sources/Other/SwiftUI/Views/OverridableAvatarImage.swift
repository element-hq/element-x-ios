//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct OverridableAvatarImage: View {
    let overrideURL: URL?
    let url: URL?
    let name: String?
    let contentID: String
    let isSpace: Bool
    let avatarSize: Avatars.Size
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        if let overrideURL {
            AsyncImage(url: overrideURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .scaledFrame(size: avatarSize.value)
            .clipAvatar(isSpace: isSpace, size: avatarSize.value)
        } else {
            LoadableAvatarImage(url: url,
                                name: name,
                                contentID: contentID,
                                isSpace: isSpace,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider)
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
