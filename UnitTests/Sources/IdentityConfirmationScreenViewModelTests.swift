//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct IdentityConfirmationScreenViewModelTests {
    let viewModel: IdentityConfirmationScreenViewModel
    var context: IdentityConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    init() {
        viewModel = IdentityConfirmationScreenViewModel(userSession: UserSessionMock(.init()),
                                                        appSettings: AppSettings(),
                                                        userIndicatorController: UserIndicatorControllerMock())
    }
    
    @Test
    func logoutShowsConfirmation() async throws {
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .logout)
        
        let alertInfo = try #require(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .logoutConfirmed }
        alertInfo.primaryButton.action?()
        try await deferred.fulfill()
    }
}
