//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension TimelineControllerFactoryMock {
    struct Configuration {
        var timelineController: RoomTimelineControllerProtocol?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue = configuration.timelineController ?? {
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            return timelineController
        }()
    }
}
