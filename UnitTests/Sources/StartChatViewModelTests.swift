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
class StartChatScreenViewModelTests: XCTestCase {
    var viewModel: StartChatViewModelProtocol!
    var clientProxy: MockClientProxy!
    var usersProvider: UsersProviderMock!
    
    var context: StartChatViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = .init(userID: "")
        usersProvider = UsersProviderMock()
        usersProvider.fetchSuggestionsReturnValue = .success([])
        usersProvider.searchProfilesWithReturnValue = .success([])
        let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        viewModel = StartChatViewModel(userSession: userSession, userIndicatorController: nil, usersProvider: usersProvider)
        
        setupAppSettings()
        ServiceLocator.shared.settings.startChatUserSuggestionsEnabled = true
    }
    
    func testQueryShowingNoResults() async throws {
        await search(query: "A")
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        XCTAssertTrue(usersProvider.fetchSuggestionsCalled)
        
        await search(query: "AA")
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        XCTAssertFalse(usersProvider.searchProfilesWithCalled)
        
        await search(query: "AAA")
        assertSearchResults(toBe: 0)
        
        XCTAssertTrue(usersProvider.searchProfilesWithCalled)
    }
    
    // MARK: - Private
    
    private func assertSearchResults(toBe count: Int) {
        XCTAssertTrue(count >= 0)
        XCTAssertEqual(context.viewState.usersSection.type, .searchResult)
        XCTAssertEqual(context.viewState.usersSection.users.count, count)
        XCTAssertEqual(context.viewState.hasEmptySearchResults, count == 0)
    }
    
    @discardableResult
    private func search(query: String) async -> StartChatViewState? {
        viewModel.context.searchQuery = query
        return await context.$viewState.nextValue
    }
}
