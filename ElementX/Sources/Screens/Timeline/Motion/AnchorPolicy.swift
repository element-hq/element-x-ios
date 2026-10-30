//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Picks the rows that keep the reader's place when the timeline changes around them.
nonisolated enum AnchorPolicy {
    nonisolated enum Edge {
        case top
        case bottom
    }
    
    nonisolated struct Anchor: Equatable {
        let id: TimelineItemIdentifier.UniqueID
        let visualTop: CGFloat
    }
    
    /// Candidates nearest `edge` first. Rows whose height or identity changes as pages load next to them,
    /// and rows changing in this update, would move what the reader is looking at, so they're skipped.
    static func anchors(in geometry: TimelineGeometry,
                        nearest edge: Edge,
                        excluding changedIDs: Set<TimelineItemIdentifier.UniqueID> = []) -> [Anchor] {
        let rows = edge == .top ? geometry.rows : geometry.rows.reversed()
        return rows
            .filter { isAnchorable($0.kind) && !changedIDs.contains($0.id) }
            .map { Anchor(id: $0.id, visualTop: $0.visualTop) }
    }
    
    /// How far the anchor moved down since it was captured. Moving the rows up by this puts it back.
    static func correction(for anchor: Anchor, newVisualTop: CGFloat) -> CGFloat {
        newVisualTop - anchor.visualTop
    }
    
    static func isAnchorable(_ kind: TimelineGeometry.Row.Kind) -> Bool {
        switch kind {
        case .message, .decoration: true
        case .paginationIndicator, .group, .readMarker: false
        }
    }
}
