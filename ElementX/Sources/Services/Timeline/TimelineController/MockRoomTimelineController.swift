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
    
    var roomProxy: RoomProxyProtocol?
    var roomID: String { roomProxy?.id ?? "MockRoomIdentifier" }
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default
    
    private var client: UITestsSignalling.Client?
    
    init(listenForSignals: Bool = false) {
        guard listenForSignals else { return }
        
        do {
            try startListening()
        } catch {
            fatalError("Failure setting up signalling: \(error)")
        }
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError> {
        callbacks.send(.canBackPaginate(false))
        return .success(())
    }
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async -> Result<Void, RoomTimelineControllerError> {
        guard let roomProxy, let eventID = itemID.eventID else { return .failure(.generic) }
        switch await roomProxy.sendReadReceipt(for: eventID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.generic)
        }
    }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async { }
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async { }

    func processItemTap(_ itemID: TimelineItemIdentifier) async -> RoomTimelineControllerAction { .none }
    
    func sendMessage(_ message: String, html: String?, inReplyTo itemID: TimelineItemIdentifier?) async { }
    
    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async { }

    func editMessage(_ newMessage: String, html: String?, original itemID: TimelineItemIdentifier) async { }
    
    func redact(_ itemID: TimelineItemIdentifier) async { }

    func cancelSend(_ itemID: TimelineItemIdentifier) async { }
    
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        .init(model: "Mock debug description", originalJSON: nil, latestEditJSON: nil)
    }
        
    func retryDecryption(for sessionID: String) async { }
    
    func audioPlayerState(for itemID: TimelineItemIdentifier) -> AudioPlayerState? {
        AudioPlayerState(duration: 10.0,
                         waveform: nil,
                         progress: 0.0)
    }
    
    func playPauseAudio(for itemID: TimelineItemIdentifier) async { }
    
    func seekAudio(for itemID: TimelineItemIdentifier, progress: Double) async { }
    
    // MARK: - UI Test signalling
    
    /// The cancellable used for UI Tests signalling.
    private var signalCancellable: AnyCancellable?
    
    /// Allows the simulation of server responses by listening for signals from UI tests.
    private func startListening() throws {
        let client = try UITestsSignalling.Client(mode: .app)
        
        signalCancellable = client.signals.sink { [weak self] signal in
            Task {
                do {
                    try await self?.handleSignal(signal)
                } catch {
                    MXLog.error(error.localizedDescription)
                }
            }
        }
        
        self.client = client
    }
    
    /// Handles a UI test signal as necessary.
    private func handleSignal(_ signal: UITestsSignal) async throws {
        switch signal {
        case .paginate:
            try await simulateBackPagination()
        case .incomingMessage:
            try await simulateIncomingItem()
        default:
            break
        }
    }
    
    /// Appends the next incoming item to the `timelineItems` array.
    private func simulateIncomingItem() async throws {
        guard !incomingItems.isEmpty else { return }
        
        let incomingItem = incomingItems.removeFirst()
        timelineItems.append(incomingItem)
        callbacks.send(.updatedTimelineItems)
        
        try client?.send(.success)
    }
    
    /// Prepends the next chunk of items to the `timelineItems` array.
    private func simulateBackPagination() async throws {
        guard !backPaginationResponses.isEmpty else { return }
        callbacks.send(.isBackPaginating(true))
        
        let newItems = backPaginationResponses.removeFirst()
        timelineItems.insert(contentsOf: newItems, at: 0)
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.isBackPaginating(false))
        
        try client?.send(.success)
    }
}
