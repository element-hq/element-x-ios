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
import Foundation

class MockRoomTimelineController: RoomTimelineControllerProtocol {
    /// An array of timeline item arrays that will be inserted in order for each back pagination request.
    var backPaginationResponses: [[RoomTimelineItemProtocol]] = []
    /// The time delay added to each back pagination request.
    var backPaginationDelay: Duration = .milliseconds(500)
    
    /// An array of timeline items that will be appended in order when ``simulateIncomingItems()`` is called.
    var incomingItems: [RoomTimelineItemProtocol] = []
    /// The time delay between each incoming item.
    var incomingDelay: Duration = .milliseconds(750)
    
    let roomId = "MockRoomIdentifier"
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default
    
    func simulateIncomingItems() {
        guard !incomingItems.isEmpty else { return }
        
        let incomingItem = incomingItems.removeFirst()
        
        Task {
            try await Task.sleep(for: incomingDelay)
            timelineItems.append(incomingItem)
            callbacks.send(.updatedTimelineItems)
            
            if !self.incomingItems.isEmpty {
                simulateIncomingItems()
            }
        }
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError> {
        callbacks.send(.startedBackPaginating)
        
        guard !backPaginationResponses.isEmpty else {
            callbacks.send(.finishedBackPaginating)
            return .failure(.generic)
        }
        
        let newItems = backPaginationResponses.removeFirst()
        
        try? await Task.sleep(for: backPaginationDelay)
        timelineItems.insert(contentsOf: newItems, at: 0)
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.finishedBackPaginating)
        
        return .success(())
    }
    
    func processItemAppearance(_ itemId: String) async { }
    
    func processItemDisappearance(_ itemId: String) async { }

    func processItemTap(_ itemId: String) async -> RoomTimelineControllerAction { .none }
    
    func sendMessage(_ message: String) async { }
    
    func sendReply(_ message: String, to itemId: String) async { }
    
    func sendReaction(_ reaction: String, for itemId: String) async { }

    func editMessage(_ newMessage: String, of itemId: String) async { }
    
    func redact(_ eventID: String) async { }
    
    func debugDescriptionFor(_ itemId: String) -> String {
        "Mock debug description"
    }
    
    func retryDecryption(forSessionId sessionId: String) async { }
}
