//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct StartChatScreenViewModelTests {
    private var viewModel: StartChatScreenViewModelProtocol!
    private var clientProxy: ClientProxyMock!
    private var userDiscoveryService: UserDiscoveryServiceMock!
    
    private var context: StartChatScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        clientProxy = .init(.init(userID: ""))
        userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([])
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        viewModel = StartChatScreenViewModel(userSession: userSession,
                                             analytics: ServiceLocator.shared.analytics,
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             userDiscoveryService: userDiscoveryService,
                                             appSettings: ServiceLocator.shared.settings)
    }
    
    @Test
    func queryShowingNoResults() async {
        var testSetup = self
        await testSetup.search(query: "A")
        #expect(testSetup.context.viewState.usersSection.type == .suggestions)
        
        await testSetup.search(query: "AA")
        #expect(testSetup.context.viewState.usersSection.type == .suggestions)
        #expect(!testSetup.userDiscoveryService.searchProfilesWithCalled)
        
        await testSetup.search(query: "AAA")
        testSetup.assertSearchResults(toBe: 0)
        
        #expect(testSetup.userDiscoveryService.searchProfilesWithCalled)
    }
    
    @Test
    func joinRoomByAddress() async throws {
        var testSetup = self
        testSetup.clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "id", servers: []))
        
        let deferredViewState = deferFulfillment(testSetup.viewModel.context.$viewState) { viewState in
            viewState.joinByAddressState == .addressFound(address: "#room:example.com", roomID: "id")
        }
        testSetup.viewModel.context.roomAddress = "#room:example.com"
        try await deferredViewState.fulfill()
        
        let deferredAction = deferFulfillment(testSetup.viewModel.actions) { action in
            action == .showRoom(roomID: "id")
        }
        testSetup.context.send(viewAction: .joinRoomByAddress)
        try await deferredAction.fulfill()
    }
    
    @Test
    func joinRoomByAddressFailsBecauseInvalid() async throws {
        var testSetup = self
        let deferred = deferFulfillment(testSetup.viewModel.context.$viewState) { viewState in
            viewState.joinByAddressState == .invalidAddress
        }
        testSetup.viewModel.context.roomAddress = ":"
        testSetup.context.send(viewAction: .joinRoomByAddress)
        try await deferred.fulfill()
    }
    
    @Test
    func joinRoomByAddressFailsBecauseNotFound() async throws {
        var testSetup = self
        testSetup.clientProxy.resolveRoomAliasReturnValue = .failure(.failedResolvingRoomAlias)
        
        let deferred = deferFulfillment(testSetup.viewModel.context.$viewState) { viewState in
            viewState.joinByAddressState == .addressNotFound
        }
        testSetup.viewModel.context.roomAddress = "#room:example.com"
        testSetup.context.send(viewAction: .joinRoomByAddress)
        try await deferred.fulfill()
    }
    
    // MARK: - Private
    
    private func assertSearchResults(toBe count: Int) {
        #expect(count >= 0)
        #expect(context.viewState.usersSection.type == .searchResult)
        #expect(context.viewState.usersSection.users.count == count)
        #expect(context.viewState.hasEmptySearchResults == (count == 0))
    }
    
    @discardableResult
    private mutating func search(query: String) async -> StartChatScreenViewState? {
        viewModel.context.searchQuery = query
        return await context.$viewState.nextValue
    }
}
