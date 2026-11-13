//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import Testing

@MainActor
struct TimelineControllerTests {
    private let roomProxy = JoinedRoomProxyMock(.init())
    
    @Test("Focusing on an event the live timeline has already loaded keeps the live timeline")
    func initialFocusOnLoadedEvent() async throws {
        let controller = makeController(liveTimeline: makeTimeline(eventIDs: ["$event"]), initialFocussedEventID: "$event")
        try await waitForTimelineItems(controller)
        
        #expect(!roomProxy.timelineFocusedOnEventEventIDNumberOfEventsCalled)
        #expect(controller.timelineKind == .live)
    }
    
    @Test("Focusing on an event the live timeline hasn't loaded loads a detached timeline")
    func initialFocusOnUnloadedEvent() async throws {
        let controller = makeController(liveTimeline: makeTimeline(eventIDs: ["$other"]), initialFocussedEventID: "$event")
        try await waitForTimelineItems(controller)
        
        #expect(roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments?.eventID == "$event")
    }
    
    @Test("A thread whose focused event can't be found reports its live timeline as live")
    func initialFocusFailureInThread() async throws {
        let controller = makeController(liveTimeline: makeTimeline(kind: .thread(rootEventID: "$root"), eventIDs: ["$other"]),
                                        initialFocussedEventID: "$event")
        let deferred = deferFulfillment(isLivePublisher(of: controller)) { _ in true }
        
        #expect(try await deferred.fulfill())
    }
    
    @Test("Messages sent after returning to the live thread timeline go to the thread")
    func sendAfterFocusLiveInThread() async throws {
        let threadTimeline = makeTimeline(kind: .thread(rootEventID: "$root"), eventIDs: ["$other"])
        let controller = makeController(liveTimeline: threadTimeline,
                                        initialFocussedEventID: "$event",
                                        focussedTimeline: makeTimeline(kind: .detached, eventIDs: ["$event"]))
        try await waitForTimelineItems(controller)
        
        controller.focusLive()
        await controller.sendMessage("Hello", html: nil, inReplyToEventID: nil, intentionalMentions: .empty)
        
        let roomTimeline = try #require(roomProxy.timeline as? TimelineProxyMock)
        #expect(threadTimeline.sendMessageHtmlInReplyToEventIDIntentionalMentionsCalled)
        #expect(!roomTimeline.sendMessageHtmlInReplyToEventIDIntentionalMentionsCalled)
    }
    
    @Test("Returning to the live thread timeline reports it as live")
    func focusLiveInThreadIsLive() async throws {
        let controller = makeController(liveTimeline: makeTimeline(kind: .thread(rootEventID: "$root"), eventIDs: ["$other"]),
                                        initialFocussedEventID: "$event",
                                        focussedTimeline: makeTimeline(kind: .detached, eventIDs: ["$event"]))
        try await waitForTimelineItems(controller)
        
        let deferred = deferFulfillment(isLivePublisher(of: controller)) { _ in true }
        
        controller.focusLive()
        
        #expect(try await deferred.fulfill())
    }
    
    @Test("The back pagination indicator stays at the top until the start of the timeline is reached",
          arguments: [(PaginationState.idle, true), (.paginating, true), (.endReached, false)])
    func backPaginationIndicator(backwardPaginationState: PaginationState, isShown: Bool) async throws {
        let paginationState = TimelinePaginationState(backward: backwardPaginationState, forward: .endReached)
        let controller = makeController(liveTimeline: makeTimeline(eventIDs: ["$event"], paginationState: paginationState))
        try await waitForTimelineItems(controller)
        
        #expect((controller.timelineItems.first is PaginationIndicatorRoomTimelineItem) == isShown)
    }
    
    // MARK: - Helpers
    
    private func makeTimeline(kind: TimelineKind = .live,
                              eventIDs: [String],
                              paginationState: TimelinePaginationState = TimelinePaginationState(backward: .idle, forward: .endReached)) -> TimelineProxyMock {
        let itemProxies = eventIDs.enumerated().map { index, eventID in
            TimelineItemProxy.event(EventTimelineItemProxy(item: .init(configuration: .init(eventID: eventID)), uniqueID: .init("\(index)")))
        }
        
        let provider = TimelineItemProviderMock()
        provider.kind = kind
        provider.itemProxies = itemProxies
        provider.paginationState = paginationState
        provider.updatePublisher = CurrentValueSubject((itemProxies, paginationState)).eraseToAnyPublisher()
        
        return TimelineProxyMock(.init(timelineItemProvider: provider))
    }
    
    /// Without a `focussedTimeline`, focusing on the initial event fails as if it wasn't found.
    private func makeController(liveTimeline: TimelineProxyMock,
                                initialFocussedEventID: String? = nil,
                                focussedTimeline: TimelineProxyMock? = nil) -> TimelineController {
        if let focussedTimeline {
            roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReturnValue = .success(focussedTimeline)
        } else {
            roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReturnValue = .failure(.eventNotFound)
        }
        
        return TimelineController(roomProxy: roomProxy,
                                  timelineProxy: liveTimeline,
                                  initialFocussedEventID: initialFocussedEventID,
                                  timelineItemFactory: RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                                               stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org")),
                                  mediaProvider: MediaProviderMock(.init()),
                                  userSettings: .mock())
    }
    
    /// The active timeline's items are only published once any initial focus attempt has finished.
    private func waitForTimelineItems(_ controller: TimelineController) async throws {
        let deferred = deferFulfillment(controller.callbacks) { callback in
            if case .updatedTimelineItems = callback {
                true
            } else {
                false
            }
        }
        try await deferred.fulfill()
    }
    
    private func isLivePublisher(of controller: TimelineController) -> AnyPublisher<Bool, Never> {
        controller.callbacks
            .compactMap { callback -> Bool? in
                if case let .isLive(isLive) = callback {
                    isLive
                } else {
                    nil
                }
            }
            .eraseToAnyPublisher()
    }
}
