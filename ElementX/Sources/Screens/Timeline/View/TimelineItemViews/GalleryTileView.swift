//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryTileView: View {
    let item: GalleryItem
    let uniqueID: TimelineItemIdentifier.UniqueID
    let mediaProvider: MediaProviderProtocol?
    let overflowCount: Int

    var body: some View {
        ZStack {
            content
            if item.isVideo {
                videoOverlay
            }
            if overflowCount > 0 {
                overflowOverlay
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let source = item.thumbnailSource ?? item.mediaSource {
            LoadableImage(mediaSource: source,
                          mediaType: .timelineItem(uniqueID: uniqueID),
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
            CompoundIcon(item.isAudio ? \.audio : \.attachment,
                         size: .medium,
                         relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconPrimary)
        }
    }

    private var videoOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            LinearGradient(colors: [.clear, .compound.bgCanvasDefault],
                           startPoint: .top,
                           endPoint: .bottom)
                .frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

            HStack {
                CompoundIcon(\.playSolid,
                             size: .custom(16),
                             relativeTo: .compound.bodySM)
                    .foregroundStyle(.compound.iconPrimary)
                Spacer()
                if let duration = item.duration {
                    Text(formatted(duration: duration))
                        .font(.compound.bodySMSemibold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(8)
        }
    }

    private var overflowOverlay: some View {
        ZStack {
            Color.compound.bgSubtleSecondary.opacity(0.7)
            Text("+\(overflowCount)")
                .font(.compound.headingSM)
                .foregroundStyle(.white)
        }
    }

    private func formatted(duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }
}
