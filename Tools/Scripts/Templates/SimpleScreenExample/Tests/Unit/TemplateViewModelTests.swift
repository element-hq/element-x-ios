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
class TemplateScreenViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: TemplateViewModelProtocol!
    var context: TemplateViewModelType.Context!
    
    @MainActor override func setUpWithError() throws {
        viewModel = TemplateViewModel(promptType: .regular, initialCount: Constants.counterInitialValue)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.count, Constants.counterInitialValue)
    }

    func testCounter() async throws {
        context.send(viewAction: .incrementCount)
        await Task.yield()
        XCTAssertEqual(context.viewState.count, 1)
        
        context.send(viewAction: .incrementCount)
        await Task.yield()
        XCTAssertEqual(context.viewState.count, 2)
        
        context.send(viewAction: .decrementCount)
        await Task.yield()
        XCTAssertEqual(context.viewState.count, 1)
    }
}
