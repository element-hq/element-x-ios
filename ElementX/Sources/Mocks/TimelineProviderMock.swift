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

@MainActor
class AutoUpdatingTimelineItemProviderMock: TimelineItemProvider {
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
                
                let timelineItem = TimelineItemSDKMock()
                timelineItem.asEventReturnValue = EventTimelineItem.mockMessage
                timelineItem.uniqueIdReturnValue = .init(id: UUID().uuidString)
                
                let diff = TimelineDiff.append(values: [timelineItem])
                
                await Self.timelineListener?.onUpdate(diff: [diff])
            }
        }
    }
}
