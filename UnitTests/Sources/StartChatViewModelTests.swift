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
class StartChatScreenViewModelTests: XCTestCase {
    var viewModel: StartChatViewModelProtocol!
    var clientProxy: MockClientProxy!
    
    var context: StartChatViewModel.Context {
        viewModel.context
    }
    
    @MainActor override func setUpWithError() throws {
        clientProxy = .init(userID: "")
        let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        viewModel = StartChatViewModel(userSession: userSession, userIndicatorController: nil)
    }
    
    func test_queryShowingNoResults() async throws {
        viewModel.context.searchQuery = "A"
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        
        viewModel.context.searchQuery = "AA"
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        
        viewModel.context.searchQuery = "AAA"
        _ = await context.$viewState.firstValue
        XCTAssertEqual(context.viewState.usersSection.type, .searchResult)
        XCTAssert(context.viewState.hasEmptySearchResults)
    }
    
    func test_queryShowingResults() async throws {
        clientProxy.searchUsersResult = .success(.init(results: [UserProfileProxy.mockAlice], limited: true))
        
        viewModel.context.searchQuery = "AAA"
        _ = await context.$viewState.firstValue
        XCTAssertEqual(context.viewState.usersSection.type, .searchResult)
        XCTAssertEqual(context.viewState.usersSection.users.count, 1)
        XCTAssertFalse(context.viewState.hasEmptySearchResults)
    }
}
