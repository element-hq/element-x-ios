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
class MessageForwardingScreenViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: MessageForwardingScreenViewModelProtocol!
    
    var context: MessageForwardingScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = MessageForwardingScreenViewModel(promptType: .regular, initialCount: Constants.counterInitialValue)
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.count, Constants.counterInitialValue)
    }

    func testCounter() async throws {
        context.send(viewAction: .incrementCount)
        XCTAssertEqual(context.viewState.count, 1)
        
        context.send(viewAction: .incrementCount)
        XCTAssertEqual(context.viewState.count, 2)
        
        context.send(viewAction: .decrementCount)
        XCTAssertEqual(context.viewState.count, 1)
    }
}
