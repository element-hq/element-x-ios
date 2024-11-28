//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RoomTimelineFactoryControllerError: Error {
    case roomProxyError(RoomProxyError)
}

@MainActor
protocol RoomTimelineControllerFactoryProtocol {
    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                     initialFocussedEventID: String?,
                                     timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                     mediaProvider: MediaProviderProtocol) -> RoomTimelineControllerProtocol
    
    #warning("buildPinnedRoomTimelineController")
    func buildRoomPinnedTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                           timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                           mediaProvider: MediaProviderProtocol) async -> RoomTimelineControllerProtocol?
    
    func buildMediaRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                          timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                          mediaProvider: MediaProviderProtocol) async -> Result<RoomTimelineControllerProtocol, RoomTimelineFactoryControllerError>
}

// sourcery: AutoMockable
extension RoomTimelineControllerFactoryProtocol { }
