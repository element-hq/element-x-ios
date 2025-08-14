//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SpaceScreenViewModelTests: XCTestCase {
    var spaceRoomListProxy: SpaceRoomListProxyMock!
    let mockSpaceRooms = [SpaceRoomProxyProtocol].mockSpaceList
    var paginationStateSubject: CurrentValueSubject<SpaceRoomListProxyPaginationState, Never> = .init(.idle(endReached: true))
    
    var viewModel: SpaceScreenViewModelProtocol!
    
    var context: SpaceScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() {
        setupViewModel()
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
    }
    
    func testSinglePagination() async throws {
        // Given a space screen view model for a space with a single paginations worth of children.
        let response = mockSpaceRooms.prefix(3)
        setupViewModel(paginationResponses: [Array(response)])
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response.isEmpty, "There should be some test rooms.")
        
        // When the pagination is triggered.
        var deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .loading }
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        try await deferred.fulfill()
        
        // Then the screen should show a paginating indicator.
        XCTAssertTrue(context.viewState.isPaginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        
        // When waiting for the pagination to finish.
        deferred = deferFulfillment(spaceRoomListProxy.paginationStatePublisher) { $0 == .idle(endReached: true) }
        try await deferred.fulfill()
        
        // Then no more pagination requests should be made the the space rooms should be populated.
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 1)
        XCTAssertEqual(context.viewState.rooms.map(\.id), response.map(\.id))
    }
    
    func testMultiplePaginations() async throws {
        // Given a space screen view model for a space with two distinct paginations worth of children.
        let response1 = mockSpaceRooms.prefix(3)
        let response2 = mockSpaceRooms.suffix(mockSpaceRooms.count - 3)
        setupViewModel(paginationResponses: [Array(response1), Array(response2)])
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertFalse(spaceRoomListProxy.paginateCalled)
        XCTAssertFalse(response1.isEmpty, "There should be some test rooms.")
        XCTAssertFalse(response2.isEmpty, "There should be more test rooms.")
        
        // When the pagination is triggered.
        let deferredIsPaginating = deferFulfillment(context.observe(\.viewState.isPaginating), transitionValues: [true, false, true, false])
        let deferredState = deferFulfillment(spaceRoomListProxy.paginationStatePublisher, keyPath: \.self, transitionValues: [.loading,
                                                                                                                              .idle(endReached: false),
                                                                                                                              .loading,
                                                                                                                              .idle(endReached: true)])
        paginationStateSubject.send(.idle(endReached: false)) // Invert the default to allow paginate to be called.
        
        // Then the screen should show 2 distinct paginations and finish up with all of the rooms visible.
        try await deferredIsPaginating.fulfill()
        try await deferredState.fulfill()
        
        XCTAssertFalse(context.viewState.isPaginating)
        XCTAssertEqual(spaceRoomListProxy.paginateCallsCount, 2)
        XCTAssertEqual(context.viewState.rooms.map(\.id), mockSpaceRooms.map(\.id))
    }
    
    func testSelectingSpace() async throws {
        setupViewModel()
        
        let selectedSpace = mockSpaceRooms[0]
        let deferred = deferFulfillment(viewModel.actionsPublisher) { _ in true }
        viewModel.context.send(viewAction: .spaceAction(.select(selectedSpace)))
        let action = try await deferred.fulfill()
        
        switch action {
        case .selectSpace(let spaceRoomProxy) where spaceRoomProxy.id == selectedSpace.id:
            break
        default:
            XCTFail("The action should select the space.")
        }
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(paginationResponses: [[SpaceRoomProxyProtocol]] = []) {
        spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceRoomProxy: SpaceRoomProxyMock(.init(isSpace: true)),
                                                          paginationStateSubject: paginationStateSubject,
                                                          paginationResponses: paginationResponses))
        
        viewModel = SpaceScreenViewModel(spaceRoomList: spaceRoomListProxy,
                                         mediaProvider: MediaProviderMock(configuration: .init()))
    }
}
