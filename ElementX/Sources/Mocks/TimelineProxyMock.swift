//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

extension TimelineProxyMock {
    struct Configuration {
        var isAutoUpdating = false
        var timelineStartReached = false
    }
    
    @MainActor
    convenience init(_ configuration: Configuration) {
        self.init()
        
        sendMessageEventContentReturnValue = .success(())
        paginateBackwardsRequestSizeReturnValue = .success(())
        paginateForwardsRequestSizeReturnValue = .success(())
        sendReadReceiptForTypeReturnValue = .success(())
        
        if configuration.isAutoUpdating {
            underlyingTimelineItemProvider = AutoUpdatingTimelineItemProviderMock()
        } else {
            let timelineItemProvider = TimelineItemProviderMock()
            timelineItemProvider.paginationState = .init(backward: configuration.timelineStartReached ? .timelineEndReached : .idle, forward: .timelineEndReached)
            timelineItemProvider.underlyingMembershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
            underlyingTimelineItemProvider = timelineItemProvider
        }
    }
}
