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

import XCTest

@testable import ElementX

@MainActor
class RoomMembersListScreenViewModelTests: XCTestCase {
    var viewModel: RoomMembersListScreenViewModel!
    
    var context: RoomMembersListScreenViewModel.Context {
        viewModel.context
    }
    
    func testJoinedMembers() async throws {
        setup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 2
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 2)
    }
    
    func testSearch() async throws {
        setup(with: [.mockAlice, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleJoinedMembers.count == 1
        }
        
        context.searchQuery = "alice"
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 1)
    }
    
    func testEmptySearch() async throws {
        setup(with: [.mockAlice, .mockBob])
        context.searchQuery = "WWW"
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.joinedMembersCount == 2
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 2)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    func testJoinedAndInvitedMembers() async throws {
        setup(with: [.mockInvited, .mockBob])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 1)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 1)
    }
    
    func testInvitedMembers() async throws {
        setup(with: [.mockInvited])
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 0)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    func testSearchInvitedMembers() async throws {
        setup(with: [.mockInvited])
        
        context.searchQuery = "invited"
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.visibleInvitedMembers.count == 1
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.state.joinedMembersCount, 0)
        XCTAssertEqual(viewModel.state.visibleInvitedMembers.count, 1)
        XCTAssertEqual(viewModel.state.visibleJoinedMembers.count, 0)
    }
    
    private func setup(with members: [RoomMemberProxyMock]) {
        viewModel = .init(roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members)),
                          mediaProvider: MockMediaProvider(),
                          userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
