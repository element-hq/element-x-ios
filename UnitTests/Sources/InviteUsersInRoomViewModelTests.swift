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
class InviteUsersScreenViewModelTests: XCTestCase {
    var viewModel: InviteUsersViewModelProtocol!
    var clientProxy: MockClientProxy!
    
    var context: InviteUsersViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = .init(userID: "")
        let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        let viewModel = InviteUsersViewModel(userSession: userSession)
        viewModel.state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
        self.viewModel = viewModel
    }
    
    func testSelectUser() async throws {
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .selectUser(.mockAlice))
        await contextNextStateValue()
        XCTAssertTrue(context.viewState.selectedUsers.count == 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfile.mockAlice.userID)
    }
    
    func testReselectUser() async throws {
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .selectUser(.mockAlice))
        await contextNextStateValue()
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfile.mockAlice.userID)
        context.send(viewAction: .selectUser(.mockAlice))
        await contextNextStateValue()
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
    
    func testDeselectUser() async throws {
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
        context.send(viewAction: .selectUser(.mockAlice))
        await contextNextStateValue()
        XCTAssertEqual(context.viewState.selectedUsers.count, 1)
        XCTAssertEqual(context.viewState.selectedUsers.first?.userID, UserProfile.mockAlice.userID)
        context.send(viewAction: .deselectUser(.mockAlice))
        await contextNextStateValue()
        XCTAssertTrue(context.viewState.selectedUsers.isEmpty)
    }
    
    @discardableResult
    private func contextNextStateValue() async -> InviteUsersViewState? {
        await context.$viewState.nextValue
    }
}
