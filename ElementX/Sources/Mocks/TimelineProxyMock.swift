//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        createPollQuestionAnswersPollKindReturnValue = .success(())
        editPollOriginalQuestionAnswersPollKindReturnValue = .success(())
        
        if configuration.isAutoUpdating {
            underlyingTimelineItemProvider = AutoUpdatingTimelineItemProviderMock()
        } else {
            let timelineItemProvider = TimelineItemProviderMock()
            timelineItemProvider.paginationState = .init(backward: configuration.timelineStartReached ? .endReached : .idle, forward: .endReached)
            timelineItemProvider.underlyingMembershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
            underlyingTimelineItemProvider = timelineItemProvider
        }
    }
}
