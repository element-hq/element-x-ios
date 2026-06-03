//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

extension TimelineProxyMock {
    struct Configuration {
        var isAutoUpdating = false
        var timelineStartReached = false
        var timelineItemProvider: TimelineItemProviderProtocol?
    }
    
    @MainActor
    convenience init(_ configuration: Configuration) {
        self.init()
        
        sendMessageEventContentReturnValue = .success(())
        sendMessageHtmlInReplyToEventIDIntentionalMentionsReturnValue = .success(())
        editNewContentReturnValue = .success(())
        buildMessageContentForHtmlIntentionalMentionsReturnValue = RoomMessageEventContentWithoutRelationSDKMock()
        paginateBackwardsRequestSizeReturnValue = .success(())
        paginateForwardsRequestSizeReturnValue = .success(())
        sendReadReceiptForTypeReturnValue = .success(())
        createPollQuestionAnswersPollKindReturnValue = .success(())
        editPollOriginalQuestionAnswersPollKindReturnValue = .success(())
        
        if let provider = configuration.timelineItemProvider {
            timelineItemProvider = provider
        } else if configuration.isAutoUpdating {
            timelineItemProvider = AutoUpdatingTimelineItemProviderMock()
        } else {
            let provider = TimelineItemProviderMock()
            provider.paginationState = .init(backward: configuration.timelineStartReached ? .endReached : .idle, forward: .endReached)
            provider.membershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
            timelineItemProvider = provider
        }
    }
}
