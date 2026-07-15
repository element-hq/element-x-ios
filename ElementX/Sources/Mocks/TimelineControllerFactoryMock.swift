//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Foundation

extension TimelineControllerFactoryMock {
    struct Configuration {
        var timelineController: TimelineControllerProtocol?
        var threadTimelineController: TimelineControllerProtocol?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderClosure = { _, _, _, _ in
            if let timelineController = configuration.threadTimelineController {
                return timelineController
            } else {
                return TimelineControllerMock(.init(timelineItems: TimelineFixtures.largeChunk))
            }
        }
        
        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure = { threadRootEventID, _, _, _, _ in
            if let timelineController = configuration.threadTimelineController {
                return .success(timelineController)
            } else {
                let timelineController = TimelineControllerMock(.init(timelineKind: .thread(rootEventID: threadRootEventID), timelineItems: TimelineFixtures.largeChunk))
                return .success(timelineController)
            }
        }
    }
}
