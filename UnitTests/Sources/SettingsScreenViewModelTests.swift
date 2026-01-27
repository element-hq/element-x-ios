//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class SettingsScreenViewModelTests: XCTestCase {
    var viewModel: SettingsScreenViewModelProtocol!
    var context: SettingsScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    @MainActor override func setUpWithError() throws {
        cancellables.removeAll()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: ""))))
        viewModel = SettingsScreenViewModel(userSession: userSession,
                                            appSettings: ServiceLocator.shared.settings,
                                            isBugReportServiceEnabled: true)
        context = viewModel.context
    }

    @MainActor func testLogout() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0 == .logout }
        context.send(viewAction: .logout)
        try await deferred.fulfill()
    }

    func testReportBug() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0 == .reportBug }
        context.send(viewAction: .reportBug)
        try await deferred.fulfill()
    }
    
    func testAnalytics() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0 == .analytics }
        context.send(viewAction: .analytics)
        try await deferred.fulfill()
    }
}
