//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct RoomTimelineControllerFactoryMockConfiguration {
    var timelineController: RoomTimelineControllerProtocol?
}

extension RoomTimelineControllerFactoryMock {
    convenience init(configuration: RoomTimelineControllerFactoryMockConfiguration) {
        self.init()
        
        buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReturnValue = configuration.timelineController ?? {
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            return timelineController
        }()
    }
}
