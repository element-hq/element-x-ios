//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import MatrixRustSDK

@MainActor
class AutoUpdatingRoomTimelineProviderMock: RoomTimelineProvider {
    private let innerUpdatePublisher: PassthroughSubject<[TimelineDiff], Never>
    private let innerPaginationStatePublisher: PassthroughSubject<PaginationState, Never>
    private let innerItems: [TimelineItemProxy] = []
    
    init() {
        innerUpdatePublisher = .init()
        innerPaginationStatePublisher = .init()
        
        super.init(currentItems: [],
                   isLive: true,
                   updatePublisher: innerUpdatePublisher.eraseToAnyPublisher(),
                   paginationStatePublisher: innerPaginationStatePublisher.eraseToAnyPublisher())
        
        Task.detached { [weak self] in
            for _ in 0...100 {
                try? await Task.sleep(for: .seconds(1))
                
                let diff = TimelineDiffSDKMock()
                diff.changeReturnValue = .append
                diff.appendReturnValue = [TimelineItemFixtures.messageTimelineItem]
                
                self?.innerUpdatePublisher.send([diff])
            }
        }
    }
}
