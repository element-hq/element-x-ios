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
        XCTAssertEqual(context.options.count, 2)
        XCTAssertTrue(context.options.allSatisfy(\.text.isEmpty))
        XCTAssertTrue(context.question.isEmpty)
        XCTAssertTrue(context.viewState.bindings.isCreateButtonDisabled)
        XCTAssertFalse(context.viewState.bindings.isUndisclosed)
    }

    func testValidPoll() async throws {
        context.question = "foo"
        context.options[0].text = "bla1"
        context.options[1].text = "bla2"
        XCTAssertFalse(context.viewState.bindings.isCreateButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions.first())
        context.send(viewAction: .create)
        let action = try await deferred.fulfill()

        guard case .create(let question, let options, let kind) = action else {
            XCTFail("Unexpected action")
            return
        }
        XCTAssertEqual(question, "foo")
        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0], "bla1")
        XCTAssertEqual(options[1], "bla2")
        XCTAssertEqual(kind, .disclosed)
    }

    func testInvalidPollEmptyOption() {
        context.question = "foo"
        context.options[0].text = "bla"
        context.options[1].text = "bla"
        context.send(viewAction: .addOption)
        XCTAssertTrue(context.viewState.bindings.isCreateButtonDisabled)
    }
}
