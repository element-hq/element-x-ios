//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@MainActor
protocol RoomTimelineControllerFactoryProtocol {
    func buildRoomTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                     initialFocussedEventID: String?,
                                     timelineItemFactory: RoomTimelineItemFactoryProtocol) -> RoomTimelineControllerProtocol
    func buildRoomPinnedTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                           timelineItemFactory: RoomTimelineItemFactoryProtocol) async -> RoomTimelineControllerProtocol?
}

// sourcery: AutoMockable
extension RoomTimelineControllerFactoryProtocol { }
