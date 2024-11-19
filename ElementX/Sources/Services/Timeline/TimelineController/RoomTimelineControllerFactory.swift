//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct RoomTimelineControllerFactory: RoomTimelineControllerFactoryProtocol {
    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                     initialFocussedEventID: String?,
                                     timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                     mediaProvider: MediaProviderProtocol) -> RoomTimelineControllerProtocol {
        RoomTimelineController(roomProxy: roomProxy,
                               timelineProxy: roomProxy.timeline,
                               initialFocussedEventID: initialFocussedEventID,
                               timelineItemFactory: timelineItemFactory,
                               mediaProvider: mediaProvider,
                               appSettings: ServiceLocator.shared.settings)
    }
    
    func buildRoomPinnedTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                           timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                           mediaProvider: MediaProviderProtocol) async -> RoomTimelineControllerProtocol? {
        guard let pinnedEventsTimeline = await roomProxy.pinnedEventsTimeline else {
            return nil
        }
        return RoomTimelineController(roomProxy: roomProxy,
                                      timelineProxy: pinnedEventsTimeline,
                                      initialFocussedEventID: nil,
                                      timelineItemFactory: timelineItemFactory,
                                      mediaProvider: mediaProvider,
                                      appSettings: ServiceLocator.shared.settings)
    }
}
