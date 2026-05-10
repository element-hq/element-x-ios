//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryGridView: View {
    let items: [GalleryItem]
    let uniqueID: TimelineItemIdentifier.UniqueID
    let mediaProvider: MediaProviderProtocol?
    let onTap: () -> Void

    static let spacing: CGFloat = 4
    static let groupWidth: CGFloat = 264
    static let maxVisible = 5

    private var visibleCount: Int {
        min(items.count, Self.maxVisible)
    }

    /// Number to show on the overflow tile when items.count > maxVisible.
    /// The last visible tile becomes the overflow indicator, so it represents
    /// itself + every hidden item.
    private var overflowCount: Int {
        items.count > Self.maxVisible ? items.count - Self.maxVisible + 1 : 0
    }

    private struct Row {
        let indices: [Int]
    }

    private var rows: [Row] {
        switch visibleCount {
        case 1: return [Row(indices: [0])]
        case 2: return [Row(indices: [0, 1])]
        case 3: return [Row(indices: [0, 1, 2])]
        case 4: return [Row(indices: [0, 1]), Row(indices: [2, 3])]
        case 5: return [Row(indices: [0, 1]), Row(indices: [2, 3, 4])]
        default: return []
        }
    }

    private func tileSize(forColumnCount count: Int) -> CGSize {
        switch count {
        case 1: return CGSize(width: Self.groupWidth, height: 130)
        case 2: return CGSize(width: 130, height: 130)
        case 3: return CGSize(width: 85, height: 85)
        default: return .zero
        }
    }

    var body: some View {
        VStack(spacing: Self.spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Self.spacing) {
                    let size = tileSize(forColumnCount: row.indices.count)
                    ForEach(row.indices, id: \.self) { index in
                        tile(at: index, size: size)
                    }
                }
            }
        }
        .frame(width: Self.groupWidth)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private func tile(at index: Int, size: CGSize) -> some View {
        if items.indices.contains(index) {
            let isLastVisible = index == visibleCount - 1
            let overflow = (overflowCount > 0 && isLastVisible) ? overflowCount : 0

            GalleryTileView(item: items[index],
                            uniqueID: uniqueID,
                            mediaProvider: mediaProvider,
                            overflowCount: overflow)
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }
}
