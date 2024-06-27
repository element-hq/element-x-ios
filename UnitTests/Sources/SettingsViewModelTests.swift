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
