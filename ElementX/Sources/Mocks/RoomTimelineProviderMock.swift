//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

@MainActor
class AutoUpdatingRoomTimelineProviderMock: RoomTimelineProvider {
    static var timelineListener: TimelineListener?
    
    private let innerPaginationStatePublisher: PassthroughSubject<PaginationState, Never>
    
    init() {
        innerPaginationStatePublisher = .init()
        
        let timelineMock = TimelineSDKMock()
        
        timelineMock.addListenerListenerClosure = { listener in
            Self.timelineListener = listener
            return TaskHandleSDKMock()
        }
        
        super.init(timeline: timelineMock,
                   kind: .live,
                   paginationStatePublisher: innerPaginationStatePublisher.eraseToAnyPublisher())
        
        Task.detached {
            for _ in 0...100 {
                try? await Task.sleep(for: .seconds(1))
                
                let diff = TimelineDiffSDKMock()
                diff.changeReturnValue = .append
                diff.appendReturnValue = [TimelineItemFixtures.messageTimelineItem]
                
                await Self.timelineListener?.onUpdate(diff: [diff])
            }
        }
    }
}
