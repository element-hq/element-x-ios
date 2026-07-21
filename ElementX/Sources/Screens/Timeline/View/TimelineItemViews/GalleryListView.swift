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
    let contentScannerService: ContentScannerServiceProtocol?
    let onTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    galleryDivider
                }
                
                GalleryListRow(item: item,
                               uniqueID: uniqueID,
                               mediaProvider: mediaProvider,
                               contentScannerService: contentScannerService) {
                    onTap(index)
                }
            }
        }
    }
    
    static var galleryDivider: some View {
        Rectangle()
            .fill(Color.compound.borderInteractiveSecondary)
            .frame(height: 0.5)
    }
    
    private var galleryDivider: some View {
        Self.galleryDivider
    }
}

private struct GalleryListRow: View {
    let item: GalleryItem
    let uniqueID: TimelineItemIdentifier.UniqueID
    let mediaProvider: MediaProviderProtocol?
    let contentScannerService: ContentScannerServiceProtocol?
    let onTap: () -> Void
    
    private var fileDescription: String {
        ".\(item.filename.validatedFileExtension.uppercased())"
    }
    
    private var iconKeyPath: KeyPath<CompoundIcons, Image> {
        item.isAudio ? \.audio : \.attachment
    }
    
    var body: some View {
        // The whole row is gated on its scan state. `containerShowsFailure` is false so an unsafe
        // item only turns its own row critical rather than the whole gallery bubble.
        ContentScanningView(contentScannerService: contentScannerService,
                            mediaSource: item.mediaSource,
                            containerShowsFailure: false) {
            row(accessory: leadingAccessory)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
        } scanningContent: {
            row(accessory: scanningAccessory)
        } unsafeContent: { failure in
            failureRow(failure)
        }
    }
    
    private func row(accessory: some View) -> some View {
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
            accessory
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
    
    private var scanningAccessory: some View {
        ProgressView()
            .scaledFrame(size: CompoundIcon.Size.medium.value, relativeTo: .body)
            .scaledPadding(6)
            .background(.compound.iconOnSolidPrimary,
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
