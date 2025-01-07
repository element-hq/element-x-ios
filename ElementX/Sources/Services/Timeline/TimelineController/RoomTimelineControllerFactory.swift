//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

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
    
    func buildPinnedEventsRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
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
    
    func buildMessageFilteredRoomTimelineController(allowedMessageTypes: [RoomMessageEventMessageType],
                                                    roomProxy: JoinedRoomProxyProtocol,
                                                    timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                    mediaProvider: MediaProviderProtocol) async -> Result<RoomTimelineControllerProtocol, RoomTimelineFactoryControllerError> {
        switch await roomProxy.messageFilteredTimeline(allowedMessageTypes: allowedMessageTypes) {
        case .success(let timelineProxy):
            return .success(RoomTimelineController(roomProxy: roomProxy,
                                                   timelineProxy: timelineProxy,
                                                   initialFocussedEventID: nil,
                                                   timelineItemFactory: timelineItemFactory,
                                                   mediaProvider: mediaProvider,
                                                   appSettings: ServiceLocator.shared.settings))
        case .failure(let error):
            return .failure(.roomProxyError(error))
        }
    }
}
