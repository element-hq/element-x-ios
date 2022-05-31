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

class SettingsViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: SettingsViewModelProtocol!
    var context: SettingsViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = SettingsViewModel()
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssert(viewModel.context.crashButtonVisible)
    }

    func testReportBug() throws {
        var correctResult = false
        self.viewModel.completion = { result in
            switch result {
            case .reportBug:
                correctResult = true
            default:
                break
            }
        }

        context.send(viewAction: .reportBug)
        async { expectation in
            XCTAssert(correctResult)
            expectation.fulfill()
        }
    }

    func testCrash() throws {
        var correctResult = false
        self.viewModel.completion = { result in
            switch result {
            case .crash:
                correctResult = true
            default:
                break
            }
        }

        context.send(viewAction: .crash)
        async { expectation in
            XCTAssert(correctResult)
            expectation.fulfill()
        }
    }

    private func async(_ timeout: TimeInterval = 0.5, _ block: @escaping (XCTestExpectation) -> Void) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: "Async operation expectation")
        block(expectation)
        waiter.wait(for: [expectation], timeout: timeout)
    }

}
