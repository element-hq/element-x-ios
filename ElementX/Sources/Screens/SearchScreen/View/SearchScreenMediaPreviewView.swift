//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The media-preview row shared by the global search Messages tab and the room message search screen.
struct SearchScreenMediaPreviewView: View {
    let preview: SearchScreenMediaPreview
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(spacing: 8) {
            media
                .scaledFrame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(preview.title)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                    .lineLimit(1)
                Text(preview.details)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var media: some View {
        switch preview.kind {
        case .file:
            icon(\.attachment)
        case .audio:
            icon(\.audio)
        case .image(let thumbnail, let blurhash):
            thumbnailView(thumbnail, blurhash: blurhash, isVideo: false)
        case .video(let thumbnail, let blurhash):
            thumbnailView(thumbnail, blurhash: blurhash, isVideo: true)
        }
    }
    
    private func icon(_ icon: KeyPath<CompoundIcons, Image>) -> some View {
        CompoundIcon(icon)
            .foregroundStyle(.compound.iconPrimary)
            .scaledFrame(width: 36, height: 36)
            .background(.compound.iconOnSolidPrimary,
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
    
    private func thumbnailView(_ thumbnail: ImageInfoProxy?, blurhash: String?, isVideo: Bool) -> some View {
        Color.compound.bgSubtlePrimary // Let the image aspect fill in place
            .overlay {
                if let thumbnail {
                    LoadableImage(mediaSource: thumbnail.source,
                                  blurhash: blurhash,
                                  size: thumbnail.size,
                                  mediaProvider: mediaProvider) {
                        Color.compound.bgSubtlePrimary
                    }
                    .mediaGalleryTimelineAspectRatio(imageInfo: thumbnail)
                }
            }
            .overlay {
                if isVideo {
                    CompoundIcon(\.playSolid, size: .small, relativeTo: .body)
                        .foregroundStyle(.compound.iconOnSolidPrimary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
