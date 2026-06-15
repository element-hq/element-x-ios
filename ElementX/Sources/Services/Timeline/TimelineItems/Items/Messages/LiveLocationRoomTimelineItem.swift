//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated struct LiveLocationRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
    let id: TimelineItemIdentifier
    /// Always empty just here for protocol conformance
    var body: String {
        ""
    }
    
    let timestamp: Date
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    
    let sender: TimelineItemSender
    let content: LiveLocationRoomTimelineItemContent
    var properties = RoomTimelineItemProperties()
}

nonisolated struct LiveLocationRoomTimelineItemContent: Equatable {
    let isLive: Bool
    let timeoutDate: Date
    
    let lastGeoURI: GeoURI?
}

nonisolated extension LiveLocationRoomTimelineItemContent {
    init(from content: MatrixRustSDK.LiveLocationContent, timestamp: Date) {
        isLive = content.isLive
        timeoutDate = timestamp.addingTimeInterval(Double(content.timeoutMs) / 1000)
        lastGeoURI = content.locations.last.flatMap { GeoURI(string: $0.geoUri) }
    }
}
