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
    var viewModel: MessageForwardingScreenViewModelProtocol!
    var context: MessageForwardingScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        viewModel = MessageForwardingScreenViewModel(roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms)), sourceRoomID: "1")
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertNil(context.viewState.rooms.first(where: { $0.id == "1" }), "The source room ID shouldn't be shown")
    }
    
    func testRoomSelection() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        XCTAssertEqual(context.viewState.selectedRoomID, "2")
    }
    
    func testSearching() {
        context.searchQuery = "Second"
        XCTAssertEqual(context.viewState.visibleRooms.count, 1)
    }
    
    func testForwarding() {
        context.send(viewAction: .selectRoom(roomID: "2"))
        XCTAssertEqual(context.viewState.selectedRoomID, "2")
        
        let expectation = expectation(description: "Wait for confirmation")
        
        viewModel.actions
            .sink { action in
                switch action {
                case .send(let roomID):
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
