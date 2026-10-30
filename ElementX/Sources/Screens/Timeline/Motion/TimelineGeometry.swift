//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// What the timeline shows on screen. Positions are window coordinates, because the table's own frame
/// moves with the composer and the keyboard, and they are visual, so rules don't care that the table is flipped.
nonisolated struct TimelineGeometry: Equatable {
    nonisolated struct Row: Equatable {
        nonisolated enum Kind: Equatable {
            case message
            case decoration
            case paginationIndicator
            case group
            case readMarker
        }
        
        let id: TimelineItemIdentifier.UniqueID
        let kind: Kind
        let visualTop: CGFloat
        let visualBottom: CGFloat
    }
    
    /// The visible rows from the top of the screen down.
    let rows: [Row]
    /// The window y of the table's visual bottom edge.
    let viewportBottom: CGFloat
    let viewportHeight: CGFloat
}

extension TimelineGeometry.Row.Kind {
    nonisolated init(_ type: RoomTimelineItemType) {
        switch type {
        case .paginationIndicator: self = .paginationIndicator
        case .group: self = .group
        case .readMarker: self = .readMarker
        case .separator, .timelineStart: self = .decoration
        default: self = .message
        }
    }
}
