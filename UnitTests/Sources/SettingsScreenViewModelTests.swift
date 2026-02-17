//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct SettingsScreenViewModelTests {
    private var viewModel: SettingsScreenViewModelProtocol
    private var context: SettingsScreenViewModelType.Context
    
    init() {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: ""))))
        viewModel = SettingsScreenViewModel(userSession: userSession,
                                            appSettings: ServiceLocator.shared.settings,
                                            isBugReportServiceEnabled: true)
        context = viewModel.context
    }

    @Test
    func logout() async throws {
        var testSetup = self
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .logout }
        testSetup.context.send(viewAction: .logout)
        try await deferred.fulfill()
    }

    @Test
    func reportBug() async throws {
        var testSetup = self
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .reportBug }
        testSetup.context.send(viewAction: .reportBug)
        try await deferred.fulfill()
    }
    
    @Test
    func analytics() async throws {
        var testSetup = self
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .analytics }
        testSetup.context.send(viewAction: .analytics)
        try await deferred.fulfill()
    }
}
