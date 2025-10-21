//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension TimelineControllerFactoryMock {
    struct Configuration {
        var timelineController: TimelineControllerProtocol?
        var threadTimelineController: TimelineControllerProtocol?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue = configuration.timelineController ?? {
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            return timelineController
        }()
        
        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure = { threadRootEventID, _, _, _, _ in
            if let threadTimelineController = configuration.threadTimelineController {
                return .success(threadTimelineController)
            } else {
                let timelineController = MockTimelineController(timelineKind: .thread(rootEventID: threadRootEventID))
                timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
                return .success(timelineController)
            }
        }
    }
}
