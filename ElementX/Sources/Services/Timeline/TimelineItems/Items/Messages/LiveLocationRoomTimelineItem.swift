//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct LiveLocationRoomTimelineItem: EventBasedTimelineItemProtocol, Equatable {
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

struct LiveLocationRoomTimelineItemContent: Equatable {
    let isLive: Bool
    let timeoutDate: Date
    
    let lastLocation: BeaconInfo?
}

extension LiveLocationRoomTimelineItemContent {
    init(from content: MatrixRustSDK.LiveLocationContent, timestamp: Date) {
        isLive = content.isLive
        timeoutDate = timestamp.addingTimeInterval(Double(content.timeoutMs) / 1000)
        lastLocation = content.locations.last.map { BeaconInfo(from: $0) }
    }
}

struct BeaconInfo: Equatable {
    let timestamp: Date
    let geoURI: GeoURI?
}

extension BeaconInfo {
    init(from beaconInfo: MatrixRustSDK.BeaconInfo) {
        timestamp = Date(timeIntervalSince1970: Double(beaconInfo.ts) / 1000)
        geoURI = GeoURI(string: beaconInfo.geoUri)
    }
}
