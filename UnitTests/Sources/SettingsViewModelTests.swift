//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SettingsScreenViewModelTests: XCTestCase {
    var viewModel: SettingsScreenViewModelProtocol!
    var context: SettingsScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    @MainActor override func setUpWithError() throws {
        cancellables.removeAll()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: ""))))
        viewModel = SettingsScreenViewModel(userSession: userSession)
        context = viewModel.context
    }

    @MainActor func testLogout() async throws {
        var correctResult = false
        
        viewModel.actions
            .sink { action in
                switch action {
                case .logout:
                    correctResult = true
                default:
                    break
                }
            }
            .store(in: &cancellables)

        context.send(viewAction: .logout)
        await Task.yield()
        XCTAssert(correctResult)
    }

    func testReportBug() async throws {
        var correctResult = false
        viewModel.actions
            .sink { action in
                correctResult = action == .reportBug
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .reportBug)
        await Task.yield()
        XCTAssert(correctResult)
    }
    
    func testAnalytics() async throws {
        var correctResult = false
        viewModel.actions
            .sink { action in
                correctResult = action == .analytics
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .analytics)
        await Task.yield()
        XCTAssert(correctResult)
    }
}
