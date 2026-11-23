//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct RemoteLogoutScreenViewModelTests {
    var viewModel: RemoteLogoutScreenViewModelProtocol
    
    var context: RemoteLogoutScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        viewModel = RemoteLogoutScreenViewModel(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@alice:example.com")))))
    }
    
    @Test("The screen shows the profile of the user who was logged out")
    func initialState() {
        #expect(context.viewState.userProfile.id == "@alice:example.com")
        #expect(context.mediaProvider != nil)
    }
    
    @Test("Tapping OK tells the coordinator the screen is done")
    func done() async throws {
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .done }
        context.send(viewAction: .done)
        try await deferred.fulfill()
    }
}
