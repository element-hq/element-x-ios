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
    
    @Test
    func paginationStateSentWhileAnUpdateIsBuildingIsNotLost() async throws {
        let newestItem = TimelineItemProxy.event(EventTimelineItemProxy(item: .init(configuration: .init(eventID: "$newest")), uniqueID: .init("0")))
        let olderItem = TimelineItemProxy.event(EventTimelineItemProxy(item: .init(configuration: .init(eventID: "$older")), uniqueID: .init("1")))
        // Combined the same way `TimelineItemProvider` does.
        let items = CurrentValueSubject<[TimelineItemProxy], Never>([newestItem])
        let paginationState = CurrentValueSubject<TimelinePaginationState, Never>(TimelinePaginationState(backward: .idle, forward: .endReached))
        let controller = makeController(liveEventIDs: ["$newest"],
                                        initialFocussedEventID: nil,
                                        updatePublisher: items.combineLatest(paginationState).eraseToAnyPublisher())
        try await waitForTimelineItems(controller)
        
        let paginationFinished = deferFulfillment(controller.callbacks) { callback in
            if case .paginationState(let state) = callback {
                state.backward == .idle
            } else {
                false
            }
        }
        // A back pagination as the SDK reports it, back to back, so each update arrives while the previous one is building.
        paginationState.send(TimelinePaginationState(backward: .paginating, forward: .endReached))
        items.send([olderItem, newestItem])
        paginationState.send(TimelinePaginationState(backward: .idle, forward: .endReached))
        try await paginationFinished.fulfill()
        
        #expect(controller.paginationState.backward == .idle)
    }
    
    // MARK: - Helpers
    
    private func makeController(liveEventIDs: [String],
                                initialFocussedEventID: String?,
                                updatePublisher: AnyPublisher<([TimelineItemProxy], TimelinePaginationState), Never>? = nil) -> TimelineController {
        let itemProxies = liveEventIDs.enumerated().map { index, eventID in
            TimelineItemProxy.event(EventTimelineItemProxy(item: .init(configuration: .init(eventID: eventID)), uniqueID: .init("\(index)")))
        }
        let paginationState = TimelinePaginationState(backward: .idle, forward: .endReached)
        
        let provider = TimelineItemProviderMock()
        provider.kind = .live
        provider.itemProxies = itemProxies
        provider.paginationState = paginationState
        provider.membershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
        provider.updatePublisher = updatePublisher ?? CurrentValueSubject((itemProxies, paginationState)).eraseToAnyPublisher()
        
        roomProxy.timelineFocusedOnEventEventIDNumberOfEventsReturnValue = .failure(.eventNotFound)
        
        return TimelineController(roomProxy: roomProxy,
                                  timelineProxy: TimelineProxyMock(.init(timelineItemProvider: provider)),
                                  initialFocussedEventID: initialFocussedEventID,
                                  timelineItemFactory: RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                                               stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org")),
                                  mediaProvider: MediaProviderMock(.init()),
                                  userSettings: .mock())
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
