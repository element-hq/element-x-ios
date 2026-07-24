//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryItemTileView: View {
    let item: GalleryItem
    let mediaProvider: MediaProviderProtocol?
    let contentScannerService: ContentScannerServiceProtocol?
    let overflowCount: Int
    let onTap: () -> Void
    
    var body: some View {
        // Each tile is gated on its own scan state. `containerShowsFailure` is false so that an
        // unsafe item only turns its own tile critical rather than the whole gallery bubble.
        ContentScanningView(contentScannerService: contentScannerService,
                            mediaSource: item.mediaSource,
                            thumbnailSource: item.thumbnailSource,
                            containerShowsFailure: false) {
            // Clear base so the image fills/clips to the grid's tile size, not its own.
            Color.clear
                .overlay { content }
                .clipped()
                .overlay(alignment: .bottom) {
                    if item.isVideo {
                        videoOverlay
                    }
                }
                .overlay {
                    if overflowCount > 0 {
                        overflowOverlay
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.filename)
        } scanningContent: {
            ScanningMediaEventsTimelineView()
        } unsafeContent: { failure in
            UnsafeMediaEventsTimelineView(failure: failure)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let source = item.thumbnailSource ?? item.mediaSource {
            LoadableImage(mediaSource: source,
                          mediaType: .timelineItem(uniqueID: item.id.timelineItemUniqueID),
                          blurhash: item.blurhash,
                          size: item.size,
                          mediaProvider: mediaProvider) { imageView in
                imageView
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholder
            }
        } else {
            iconFallback
        }
    }
    
    private var placeholder: some View {
        Color.compound.bgSubtleSecondary.opacity(0.9)
    }
    
    private var iconFallback: some View {
        ZStack {
            Color.compound.bgSubtleSecondary
            CompoundIcon(item.isAudio ? \.audio : \.attachment)
                .foregroundStyle(.compound.iconPrimary)
        }
    }
    
    private var videoOverlay: some View {
        HStack(spacing: 0) {
            CompoundIcon(\.videoCallSolid,
                         size: .xSmall,
                         relativeTo: .compound.bodyXSSemibold)
            Spacer(minLength: 0)
            if let duration = item.duration {
                Text(formatted(duration: duration))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .font(.compound.bodyXSSemibold)
        .foregroundStyle(.compound.textPrimary)
        .background {
            LinearGradient(colors: [.clear, .compound.bgCanvasDefault],
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }
    
    private var overflowOverlay: some View {
        ZStack {
            Color.compound.bgCanvasDefault.opacity(0.7)
            Text("+\(overflowCount)")
                .font(.compound.headingSMSemibold)
                .foregroundStyle(.compound.textPrimary)
        }
    }
    
    private func formatted(duration: TimeInterval) -> String {
        let duration = Duration.seconds(duration)
        let pattern: Duration.TimeFormatStyle.Pattern = duration >= .seconds(3600) ? .hourMinuteSecond : .minuteSecond
        return duration.formatted(.time(pattern: pattern))
    }
}
