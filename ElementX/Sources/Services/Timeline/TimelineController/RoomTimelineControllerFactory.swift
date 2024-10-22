//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol {
    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                     initialFocussedEventID: String?,
                                     timelineItemFactory: RoomTimelineItemFactoryProtocol) -> RoomTimelineControllerProtocol {
        RoomTimelineController(roomProxy: roomProxy,
                               timelineProxy: roomProxy.timeline,
                               initialFocussedEventID: initialFocussedEventID,
                               timelineItemFactory: timelineItemFactory,
                               appSettings: ServiceLocator.shared.settings)
    }
    
    func buildRoomPinnedTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                           timelineItemFactory: RoomTimelineItemFactoryProtocol) async -> RoomTimelineControllerProtocol? {
        guard let pinnedEventsTimeline = await roomProxy.pinnedEventsTimeline else {
            return nil
        }
        return RoomTimelineController(roomProxy: roomProxy,
                                      timelineProxy: pinnedEventsTimeline,
                                      initialFocussedEventID: nil,
                                      timelineItemFactory: timelineItemFactory,
                                      appSettings: ServiceLocator.shared.settings)
    }
}
