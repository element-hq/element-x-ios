//
// Copyright 2026 Element Creations Ltd.
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
    let mediaProvider: MediaProviderProtocol?
    let contentScannerService: ContentScannerServiceProtocol?
    let onItemTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    GalleryDivider()
                }
                
                GalleryListRow(item: item,
                               mediaProvider: mediaProvider,
                               contentScannerService: contentScannerService) {
                    onItemTap(index)
                }
            }
        }
    }
}

/// A hairline divider used between gallery file-list rows (and above the caption).
struct GalleryDivider: View {
    @Environment(\.pixelLength) private var pixelLength
    
    var body: some View {
        Rectangle()
            .fill(Color.compound.borderInteractiveSecondary)
            .frame(height: pixelLength)
    }
}

private struct GalleryListRow: View {
    let item: GalleryItem
    let mediaProvider: MediaProviderProtocol?
    let contentScannerService: ContentScannerServiceProtocol?
    let onTap: () -> Void
    
    private var fileDescription: String {
        item.filename.validatedFileExtension.uppercased()
    }
    
    private var iconKeyPath: KeyPath<CompoundIcons, Image> {
        item.isAudio ? \.audio : \.attachment
    }
    
    var body: some View {
        ContentScanningView(contentScannerService: contentScannerService,
                            mediaSource: item.mediaSource,
                            thumbnailSource: item.thumbnailSource,
                            containerShowsFailure: false) {
            row(icon: icon)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
        } scanningContent: {
            row(icon: scanningIcon)
        } unsafeContent: { failure in
            failureRow(failure)
        }
    }
    
    private func row(icon: some View) -> some View {
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
            icon
        }
        .labelStyle(.custom(spacing: 8, alignment: .center))
        .padding(.vertical, 12)
    }
    
    /// The critical row shown when an item fails content scanning. Reuses ``ContentScanningFailureView``
    /// (icon + title + message) inside its own critical container as the surrounding bubble stays regular.
    private func failureRow(_ failure: ContentScanningFailure) -> some View {
        ContentScanningFailureView(failure: failure)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.compound.bgCriticalSubtle, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.compound.borderCriticalSubtle)
            }
            .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var icon: some View {
        if item.hasThumbnail, let source = item.thumbnailSource ?? item.mediaSource {
            LoadableImage(mediaSource: source,
                          mediaType: .timelineItem(uniqueID: item.id.timelineItemUniqueID),
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
            FileTypeIconView(icon: iconKeyPath)
        }
    }
    
    private var scanningIcon: some View {
        FileTypeIconView(icon: iconKeyPath, isScanning: true)
    }
}
