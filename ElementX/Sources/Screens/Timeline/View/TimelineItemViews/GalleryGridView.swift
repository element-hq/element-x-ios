//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct GalleryGridView: View {
    let items: [GalleryItem]
    let mediaProvider: MediaProviderProtocol?
    let contentScannerService: ContentScannerServiceProtocol?
    let onItemTap: (Int) -> Void
    
    static let spacing: CGFloat = 4
    static let groupWidth: CGFloat = 264
    static let maxVisible = 5
    
    private var visibleCount: Int {
        min(items.count, Self.maxVisible)
    }
    
    /// Number shown on the overflow tile when items.count > maxVisible.
    private var overflowCount: Int {
        // Represents the last visible item + the rest.
        items.count > Self.maxVisible ? items.count - Self.maxVisible + 1 : 0
    }
    
    private struct Row {
        let indices: [Int]
        let height: CGFloat
    }
    
    /// Hero-style layout: 1 = full-width, 2 = two full-width stacked rows, 3 = full-width hero
    /// over two squares, 4 = 2×2 squares, 5+ = top row two squares, bottom row three squares.
    private var rows: [Row] {
        switch visibleCount {
        case 1: return [Row(indices: [0], height: 130)]
        case 2: return [Row(indices: [0], height: 130),
                        Row(indices: [1], height: 130)]
        case 3: return [Row(indices: [0], height: 130),
                        Row(indices: [1, 2], height: 130)]
        case 4: return [Row(indices: [0, 1], height: 130),
                        Row(indices: [2, 3], height: 130)]
        case 5: return [Row(indices: [0, 1], height: 130),
                        Row(indices: [2, 3, 4], height: 85)]
        default: return []
        }
    }
    
    var body: some View {
        VStack(spacing: Self.spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                let totalSpacing = CGFloat(row.indices.count - 1) * Self.spacing
                let tileWidth = (Self.groupWidth - totalSpacing) / CGFloat(row.indices.count)
                HStack(spacing: Self.spacing) {
                    ForEach(row.indices, id: \.self) { index in
                        tile(at: index, size: CGSize(width: tileWidth, height: row.height))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    @ViewBuilder
    private func tile(at index: Int, size: CGSize) -> some View {
        if items.indices.contains(index) {
            let isLastVisible = index == visibleCount - 1
            let overflow = (overflowCount > 0 && isLastVisible) ? overflowCount : 0
            
            GalleryItemTileView(item: items[index],
                                mediaProvider: mediaProvider,
                                contentScannerService: contentScannerService,
                                overflowCount: overflow) {
                onItemTap(index)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}
