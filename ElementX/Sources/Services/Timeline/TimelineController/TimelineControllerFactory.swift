//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct TimelineControllerFactory: TimelineControllerFactoryProtocol {
    func buildTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                 initialFocussedEventID: String?,
                                 timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                 mediaProvider: MediaProviderProtocol) -> TimelineControllerProtocol {
        TimelineController(roomProxy: roomProxy,
                           timelineProxy: roomProxy.timeline,
                           initialFocussedEventID: initialFocussedEventID,
                           timelineItemFactory: timelineItemFactory,
                           mediaProvider: mediaProvider,
                           appSettings: ServiceLocator.shared.settings)
    }
    
    func buildThreadTimelineController(threadRootEventID: String,
                                       initialFocussedEventID: String?,
                                       roomProxy: JoinedRoomProxyProtocol,
                                       timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                       mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        switch await roomProxy.threadTimeline(eventID: threadRootEventID) {
        case .success(let timelineProxy):
            return .success(TimelineController(roomProxy: roomProxy,
                                               timelineProxy: timelineProxy,
                                               initialFocussedEventID: initialFocussedEventID,
                                               timelineItemFactory: timelineItemFactory,
                                               mediaProvider: mediaProvider,
                                               appSettings: ServiceLocator.shared.settings))
        case .failure(let error):
            return .failure(.roomProxyError(error))
        }
    }
    
    func buildPinnedEventsTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                             timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                             mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        switch await roomProxy.pinnedEventsTimeline() {
        case .success(let timelineProxy):
            return .success(TimelineController(roomProxy: roomProxy,
                                               timelineProxy: timelineProxy,
                                               initialFocussedEventID: nil,
                                               timelineItemFactory: timelineItemFactory,
                                               mediaProvider: mediaProvider,
                                               appSettings: ServiceLocator.shared.settings))
        case .failure(let error):
            return .failure(.roomProxyError(error))
        }
    }
    
    func buildMessageFilteredTimelineController(focus: TimelineFocus,
                                                allowedMessageTypes: [TimelineAllowedMessageType],
                                                presentation: TimelineKind.MediaPresentation,
                                                roomProxy: JoinedRoomProxyProtocol,
                                                timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        switch await roomProxy.messageFilteredTimeline(focus: focus, allowedMessageTypes: allowedMessageTypes, presentation: presentation) {
        case .success(let timelineProxy):
            return .success(TimelineController(roomProxy: roomProxy,
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
