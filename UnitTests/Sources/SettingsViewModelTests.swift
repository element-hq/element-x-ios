// 
// Copyright 2021 New Vector Ltd
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
class SettingsViewModelTests: XCTestCase {

    var viewModel: SettingsViewModelProtocol!
    var context: SettingsViewModelType.Context!
    
    @MainActor override func setUpWithError() throws {
        viewModel = SettingsViewModel()
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssert(context.viewState.crashButtonVisible)
    }

    func testReportBug() async throws {
        var correctResult = false
        viewModel.callback = { result in
            correctResult = result == .reportBug
        }

        context.send(viewAction: .reportBug)
        await Task.yield()
        XCTAssert(correctResult)
    }

    func testCrash() async throws {
        var correctResult = false
        viewModel.callback = { result in
            correctResult = result == .crash
        }

        context.send(viewAction: .crash)
        await Task.yield()
        XCTAssert(correctResult)
    }

}
