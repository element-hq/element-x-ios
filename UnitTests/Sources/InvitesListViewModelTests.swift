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

@testable import ElementX
import XCTest

@MainActor
class InvitesListScreenViewModelTests: XCTestCase {
    var viewModel: InvitesListViewModelProtocol!
    var clientProxy: MockClientProxy!
    var userSession: MockUserSession!
    
    var context: InvitesListViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = MockClientProxy(userID: "@a:b.com")
        userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
    }

    func testEmptyState() throws {
        setupViewModel()
        let invites = try XCTUnwrap(context.viewState.invites)
        XCTAssertTrue(invites.isEmpty)
    }
    
    func testListState() throws {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded(.invites))
        clientProxy.invitesSummaryProvider = summaryProvider
        clientProxy.visibleRoomsSummaryProvider = summaryProvider
        setupViewModel()
        let invites = try XCTUnwrap(context.viewState.invites)
        XCTAssertEqual(invites.count, 2)
    }
    
    // MARK: - Private
    
    private func setupViewModel() {
        viewModel = InvitesListViewModel(userSession: userSession)
    }
}
