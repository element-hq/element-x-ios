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
class GlobalSearchScreenViewModelTests: XCTestCase {
    var viewModel: GlobalSearchScreenViewModelProtocol!
    var context: GlobalSearchScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        cancellables.removeAll()
        viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                mediaProvider: MockMediaProvider())
        context = viewModel.context
    }
            
    func testSearching() async throws {
        let defered = deferFulfillment(context.$viewState) { state in
            state.rooms.count == 1
        }
        
        context.searchQuery = "Second"
            
        try await defered.fulfill()
    }
    
    func testRoomSelection() {
        let expectation = expectation(description: "Wait for confirmation")
        
        viewModel.actions
            .sink { action in
                switch action {
                case .select(let roomID):
                    XCTAssertEqual(roomID, "2")
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .select(roomID: "2"))
        
        waitForExpectations(timeout: 5.0)
    }
}
