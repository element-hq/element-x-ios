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
    
    @Test
    func initialFocusOnLoadedEventUsesTheLiveTimeline() async throws {
        let controller = makeController(liveEventIDs: ["$event"], initialFocussedEventID: "$event")
        try await waitForTimelineItems(controller)
        
        #expect(!roomProxy.timelineFocusedOnEventEventIDNumberOfEventsCalled)
        #expect(controller.timelineKind == .live)
    }
    
    @Test
    func initialFocusOnUnloadedEventLoadsADetachedTimeline() async throws {
        let controller = makeController(liveEventIDs: ["$other"], initialFocussedEventID: "$event")
        try await waitForTimelineItems(controller)
        
        #expect(roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReceivedArguments?.eventID == "$event")
    }
    
    // MARK: - Helpers
    
    private func makeController(liveEventIDs: [String], initialFocussedEventID: String) -> TimelineController {
        let itemProxies = liveEventIDs.enumerated().map { index, eventID in
            TimelineItemProxy.event(EventTimelineItemProxy(item: .init(configuration: .init(eventID: eventID)), uniqueID: .init("\(index)")))
        }
        let paginationState = TimelinePaginationState(backward: .idle, forward: .endReached)
        
        let provider = TimelineItemProviderMock()
        provider.kind = .live
        provider.itemProxies = itemProxies
        provider.paginationState = paginationState
        provider.membershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
        provider.updatePublisher = CurrentValueSubject((itemProxies, paginationState)).eraseToAnyPublisher()
        
        roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReturnValue = .failure(.eventNotFound)
        
        return TimelineController(roomProxy: roomProxy,
                                  timelineProxy: TimelineProxyMock(.init(timelineItemProvider: provider)),
                                  initialFocussedEventID: initialFocussedEventID,
                                  timelineItemFactory: RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                                               stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org")),
                                  mediaProvider: MediaProviderMock(.init()),
                                  userSettings: .volatile())
    }
    
    /// The live timeline's items are only published once any initial focus attempt has finished.
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
}
