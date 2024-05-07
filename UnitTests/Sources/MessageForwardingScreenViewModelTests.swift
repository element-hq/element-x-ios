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
        clientProxy.roomForIdentifierClosure = { RoomProxyMock(with: .init(id: $0)) }
        
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
