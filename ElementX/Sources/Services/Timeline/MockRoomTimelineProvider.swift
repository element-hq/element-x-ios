//
// Copyright 2022 New Vector Ltd
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

struct MockRoomTimelineProvider: RoomTimelineProviderProtocol {
    var itemsPublisher = CurrentValueSubject<[TimelineItemProxy], Never>([])
    
    private var itemProxies = [TimelineItemProxy]()
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineProviderError> {
        .failure(.failedPaginatingBackwards)
    }
    
    func sendMessage(_ message: String, inReplyToItemId: String?) async -> Result<Void, RoomTimelineProviderError> {
        .failure(.failedSendingMessage)
    }

    func sendReaction(_ reaction: String, for itemId: String) async -> Result<Void, RoomTimelineProviderError> {
        .failure(.failedSendingReaction)
    }
    
    func editMessage(_ newMessage: String, originalItemId: String) async -> Result<Void, RoomTimelineProviderError> {
        .failure(.failedSendingMessage)
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomTimelineProviderError> {
        .failure(.failedRedactingItem)
    }
    
    func retryDecryption(forSessionId sessionId: String) async { }
}
