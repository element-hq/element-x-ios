//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Combine
import Foundation
import MatrixRustSDK

class MockTimelineController: TimelineControllerProtocol {
    /// An array of timeline item arrays that will be inserted in order for each back pagination request.
    var backPaginationResponses: [[RoomTimelineItemProtocol]] = []
    /// An array of timeline items that will be appended in order when ``simulateIncomingItems()`` is called.
    var incomingItems: [RoomTimelineItemProtocol] = []
    
    var roomProxy: JoinedRoomProxyProtocol?
    var roomID: String { roomProxy?.id ?? "MockRoomIdentifier" }
    var timelineKind: TimelineKind
    
    let callbacks = PassthroughSubject<TimelineControllerCallback, Never>()
    
    var paginationState: PaginationState = .initial {
        didSet {
            callbacks.send(.paginationState(paginationState))
        }
    }
    
    var timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default
    var timelineItemsTimestamp: [TimelineItemIdentifier: Date] = [:]
    
    private var client: UITestsSignalling.Client?
    
    static var mediaGallery: MockTimelineController {
        MockTimelineController(timelineKind: .media(.mediaFilesScreen), timelineItems: (0..<5).reduce([]) { partialResult, _ in
            partialResult + [RoomTimelineItemFixtures.separator] + RoomTimelineItemFixtures.mediaChunk
        })
    }
    
    static var emptyMediaGallery: MockTimelineController {
        let mock = MockTimelineController(timelineKind: .media(.mediaFilesScreen))
        mock.paginationState = PaginationState(backward: .timelineEndReached, forward: .timelineEndReached)
        return mock
    }
    
    init(timelineKind: TimelineKind = .live, listenForSignals: Bool = false, timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default) {
        self.timelineKind = timelineKind
        self.timelineItems = timelineItems
        
        callbacks.send(.paginationState(paginationState))
        callbacks.send(.isLive(true))
        
        guard listenForSignals else { return }
        
        do {
            try startListening()
        } catch {
            fatalError("Failure setting up signalling: \(error)")
        }
    }
    
    private(set) var focusOnEventCallCount = 0
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, TimelineControllerError> {
        focusOnEventCallCount += 1
        callbacks.send(.isLive(false))
        return .success(())
    }
    
    private(set) var focusLiveCallCount = 0
    func focusLive() {
        focusLiveCallCount += 1
        callbacks.send(.isLive(true))
    }
    
    private(set) var paginateBackwardsCallCount = 0
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateBackwardsCallCount += 1
        
        paginationState = PaginationState(backward: .paginating, forward: .timelineEndReached)
        
        if client == nil {
            try? await simulateBackPagination()
        }
        
        return .success(())
    }
    
    private(set) var paginateForwardsCallCount = 0
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateForwardsCallCount += 1
        return .success(())
    }
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async {
        guard let roomProxy, let eventID = itemID.eventID else { return }
        _ = await roomProxy.timeline.sendReadReceipt(for: eventID, type: .read)
    }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async { }
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async { }
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyToEventID: String?,
                     intentionalMentions: IntentionalMentions) async { }
        
    func toggleReaction(_ reaction: String, to eventID: TimelineItemIdentifier.EventOrTransactionID) async { }
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async { }
    
    func editCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
                     message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async { }
    
    func removeCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async { }
    
    private(set) var redactCalled = false
    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        redactCalled = true
    }
    
    func pin(eventID: String) async { }
    
    func unpin(eventID: String) async { }
    
    func messageEventContent(for itemID: TimelineItemIdentifier) -> RoomMessageEventContentWithoutRelation? {
        .init(noPointer: .init())
    }
    
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        .init(model: "Mock debug description", originalJSON: nil, latestEditJSON: nil)
    }
    
    func sendHandle(for itemID: TimelineItemIdentifier) -> SendHandleProxy? {
        nil
    }
        
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date? {
        timelineItemsTimestamp[itemID] ?? .now
    }
    
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
        case .timeline(.paginate):
            try await simulateBackPagination()
        case .timeline(.incomingMessage):
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
        callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
        
        try client?.send(.success)
    }
    
    /// Prepends the next chunk of items to the `timelineItems` array.
    private func simulateBackPagination() async throws {
        defer {
            paginationState = PaginationState(backward: backPaginationResponses.isEmpty ? .timelineEndReached : .idle,
                                              forward: .timelineEndReached)
        }
        
        guard !backPaginationResponses.isEmpty else { return }
        
        let newItems = backPaginationResponses.removeFirst()
        timelineItems.insert(contentsOf: newItems, at: 0)
        callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
        
        try client?.send(.success)
    }
}
