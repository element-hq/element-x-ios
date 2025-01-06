//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct PaginationIndicatorRoomTimelineItem: DecorationTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    
    enum Position {
        case start, end
        
        var id: String {
            switch self {
            case .start: "backwardPaginationIndicatorTimelineItemIdentifier"
            case .end: "forwardPaginationIndicatorTimelineItemIdentifier"
            }
        }
    }
    
    init(position: Position) {
        id = .virtual(uniqueID: .init(id: position.id))
    }
}
