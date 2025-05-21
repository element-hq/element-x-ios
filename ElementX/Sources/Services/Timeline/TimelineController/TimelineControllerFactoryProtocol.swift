//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum TimelineFactoryControllerError: Error {
    case roomProxyError(RoomProxyError)
}

@MainActor
protocol TimelineControllerFactoryProtocol {
    func buildTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                 initialFocussedEventID: String?,
                                 timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                 mediaProvider: MediaProviderProtocol) -> TimelineControllerProtocol
    
    func buildThreadTimelineController(eventID: String,
                                       roomProxy: JoinedRoomProxyProtocol,
                                       timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                       mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>
    
    func buildPinnedEventsTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                             timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                             mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>
    
    func buildMessageFilteredTimelineController(focus: TimelineFocus,
                                                allowedMessageTypes: [TimelineAllowedMessageType],
                                                presentation: TimelineKind.MediaPresentation,
                                                roomProxy: JoinedRoomProxyProtocol,
                                                timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>
}

// sourcery: AutoMockable
extension TimelineControllerFactoryProtocol { }
