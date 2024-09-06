//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class MessageForwardingScreenViewModelTests: XCTestCase {
    let forwardingItem = MessageForwardingItem(id: .init(timelineID: "t1", eventID: "t1"),
                                               roomID: "1",
                                               content: .init(noPointer: .init()))
    var viewModel: MessageForwardingScreenViewModelProtocol!
    var context: MessageForwardingScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { .joined(JoinedRoomProxyMock(.init(id: $0))) }
        
        viewModel = MessageForwardingScreenViewModel(forwardingItem: forwardingItem,
                                                     clientProxy: clientProxy,
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                     userIndicatorController: UserIndicatorControllerMock(),
                                                     mediaProvider: MockMediaProvider())
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertNil(context.viewState.rooms.first(where: { $0.id == forwardingItem.roomID }), "The source room ID shouldn't be shown")
    }
    
    func testRoomSelection() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        XCTAssertEqual(context.viewState.selectedRoomID, "2")
    }
    
    func testSearching() async throws {
        let defered = deferFulfillment(context.$viewState) { state in
            state.rooms.count == 1
        }
        
        context.searchQuery = "Second"
            
        try await defered.fulfill()
    }
    
    func testForwarding() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        XCTAssertEqual(context.viewState.selectedRoomID, "2")
        
        let expectation = expectation(description: "Wait for confirmation")
        
        viewModel.actions
            .sink { action in
                switch action {
                case .sent(let roomID):
                    XCTAssertEqual(roomID, "2")
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .send)
        
        waitForExpectations(timeout: 5.0)
    }
}
