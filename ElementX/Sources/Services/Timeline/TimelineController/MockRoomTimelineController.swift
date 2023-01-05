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
    /// An array of timeline items that will be appended in order when ``simulateIncomingItems()`` is called.
    var incomingItems: [RoomTimelineItemProtocol] = []
    
    let roomId = "MockRoomIdentifier"
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default
    
    private var client: UITestsSignalling.Client?
    private var signalTask: Task<Void, Error>?
    
    init(listenForSignals: Bool = false) {
        if listenForSignals {
            client = .init()
            Task { try await listenForSignal() }
        }
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        .failure(.generic)
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
    
    // MARK: - UI Test signalling
    
    /// Allows the simulation of server responses by listening for signals from UI tests.
    private func listenForSignal() async throws {
        guard let client else { throw UITestsSignalError.disabled }
        
        try await client.connect()
        signalTask = Task {
            switch try await client.receive() {
            case .paginate:
                try await self.simulateBackPagination()
            case .incomingMessage:
                try await self.simulateIncomingItem()
            default:
                break
            }
            
            // Keep listening TODO: Try an async stream here?
            try await self.listenForSignal()
        }
    }
    
    /// Appends the next incoming item to the `timelineItems` array.
    private func simulateIncomingItem() async throws {
        guard !incomingItems.isEmpty else { return }
        
        let incomingItem = incomingItems.removeFirst()
        timelineItems.append(incomingItem)
        callbacks.send(.updatedTimelineItems)
        
        try? await client?.send(.success)
    }
    
    /// Prepends the next chunk of items to the `timelineItems` array.
    private func simulateBackPagination() async throws {
        guard !backPaginationResponses.isEmpty else { return }
        
        let newItems = backPaginationResponses.removeFirst()
        timelineItems.insert(contentsOf: newItems, at: 0)
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.finishedBackPaginating)
        
        try? await client?.send(.success)
    }
}
