//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Used for gallery messages that contain at least one attachment without a thumbnail
/// (typically a document or audio). Renders a vertical list of file rows so each item is
/// individually recognisable — the grid layout doesn't read well for non-visual content.
struct GalleryListView: View {
    let items: [GalleryItem]
    let uniqueID: TimelineItemIdentifier.UniqueID
    let mediaProvider: MediaProviderProtocol?
    let onTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    galleryDivider
                }
                
                GalleryListRow(item: item,
                               uniqueID: uniqueID,
                               mediaProvider: mediaProvider)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(index) }
            }
        }
    }
    
    static var galleryDivider: some View {
        Rectangle()
            .fill(ListRowColor.separatorTint)
            .frame(height: 1 / UIScreen.main.scale)
    }
    
    private var galleryDivider: some View {
        Self.galleryDivider
    }
}

private struct GalleryListRow: View {
    let item: GalleryItem
    let uniqueID: TimelineItemIdentifier.UniqueID
    let mediaProvider: MediaProviderProtocol?
    
    private var fileDescription: String {
        item.filename.validatedFileExtension.uppercased()
    }
    
    private var iconKeyPath: KeyPath<CompoundIcons, Image> {
        item.isAudio ? \.audio : \.attachment
    }
    
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.filename)
                    .foregroundStyle(.compound.textPrimary)
                    .font(.compound.bodyLG)
                Text(fileDescription)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
            }
            .lineLimit(2)
        } icon: {
            leadingAccessory
        }
        .labelStyle(.custom(spacing: 8, alignment: .center))
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var leadingAccessory: some View {
        if item.hasThumbnail, let source = item.thumbnailSource ?? item.mediaSource {
            LoadableImage(mediaSource: source,
                          mediaType: .timelineItem(uniqueID: uniqueID),
                          blurhash: item.blurhash,
                          size: item.size,
                          mediaProvider: mediaProvider) { imageView in
                imageView
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.compound.bgSubtleSecondary
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            CompoundIcon(iconKeyPath, size: .medium, relativeTo: .body)
                .foregroundColor(.compound.iconPrimary)
                .scaledPadding(6)
                .background(.compound.iconOnSolidPrimary,
                            in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
}
