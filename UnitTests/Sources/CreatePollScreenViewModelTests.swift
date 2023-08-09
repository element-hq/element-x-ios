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
class CreatePollScreenViewModelTests: XCTestCase {
    var viewModel: CreatePollScreenViewModelProtocol!
    
    var context: CreatePollScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = CreatePollScreenViewModel()
    }

    func testInitialState() {
        XCTAssertFalse(context.viewState.placeholder.isEmpty)
        XCTAssertFalse(context.composerText.isEmpty)
    }

    func testCounter() async throws {
        context.composerText = "123"
        context.send(viewAction: .textChanged)
        XCTAssertEqual(context.composerText, "123")
    }
}
