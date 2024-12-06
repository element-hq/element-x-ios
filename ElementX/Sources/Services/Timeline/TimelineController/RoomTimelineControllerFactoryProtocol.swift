//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RoomTimelineFactoryControllerError: Error {
    case roomProxyError(RoomProxyError)
}

@MainActor
protocol RoomTimelineControllerFactoryProtocol {
    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                     initialFocussedEventID: String?,
                                     timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                     mediaProvider: MediaProviderProtocol) -> RoomTimelineControllerProtocol
    
    func buildPinnedEventsRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                                 timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                 mediaProvider: MediaProviderProtocol) async -> RoomTimelineControllerProtocol?
    
    func buildMessageFilteredRoomTimelineController(allowedMessageTypes: [RoomMessageEventMessageType],
                                                    roomProxy: JoinedRoomProxyProtocol,
                                                    timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                    mediaProvider: MediaProviderProtocol) async -> Result<RoomTimelineControllerProtocol, RoomTimelineFactoryControllerError>
}

// sourcery: AutoMockable
extension RoomTimelineControllerFactoryProtocol { }
