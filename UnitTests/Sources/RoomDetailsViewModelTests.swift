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
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsViewModelProtocol!
    var context: RoomDetailsViewModelType.Context!
    
    @MainActor override func setUpWithError() throws {
        viewModel = RoomDetailsViewModel(promptType: .regular, initialCount: Constants.counterInitialValue)
        context = viewModel.context
    }

    @MainActor func testCancel() async throws {
        var correctResult = false
        viewModel.callback = { result in
            switch result {
            case .cancel:
                correctResult = true
            }
        }

        context.send(viewAction: .cancel)
        await Task.yield()
        XCTAssert(correctResult)
    }
}
