//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class StartChatScreenViewModelTests: XCTestCase {
    var viewModel: StartChatScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    var userDiscoveryService: UserDiscoveryServiceMock!
    
    var context: StartChatScreenViewModel.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = .init(.init(userID: ""))
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        viewModel = StartChatScreenViewModel(userSession: userSession,
                                             analytics: ServiceLocator.shared.analytics,
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             userDiscoveryService: userDiscoveryService)
    }
    
    func testQueryShowingNoResults() async throws {
        await search(query: "A")
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        
        await search(query: "AA")
        XCTAssertEqual(context.viewState.usersSection.type, .suggestions)
        XCTAssertFalse(userDiscoveryService.searchProfilesWithCalled)
        
        await search(query: "AAA")
        assertSearchResults(toBe: 0)
        
        XCTAssertTrue(userDiscoveryService.searchProfilesWithCalled)
    }
    
    // MARK: - Private
    
    private func assertSearchResults(toBe count: Int) {
        XCTAssertTrue(count >= 0)
        XCTAssertEqual(context.viewState.usersSection.type, .searchResult)
        XCTAssertEqual(context.viewState.usersSection.users.count, count)
        XCTAssertEqual(context.viewState.hasEmptySearchResults, count == 0)
    }
    
    @discardableResult
    private func search(query: String) async -> StartChatScreenViewState? {
        viewModel.context.searchQuery = query
        return await context.$viewState.nextValue
    }
}
