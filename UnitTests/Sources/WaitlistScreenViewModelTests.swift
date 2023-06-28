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
class WaitlistScreenViewModelTests: XCTestCase {
    var viewModel: WaitlistScreenViewModelProtocol!
    var context: WaitlistScreenViewModelType.Context { viewModel.context }
    
    override func setUpWithError() throws {
        viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
    }

    func testSuccess() async throws {
        XCTAssertNil(context.viewState.userSession, "No user session should be set on a new view model.")
        XCTAssertTrue(context.viewState.isWaiting, "The view should start off in the waiting state.")
        
        viewModel.update(userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@alice:matrix.org"),
                                                      mediaProvider: MockMediaProvider()))
        
        XCTAssertNotNil(context.viewState.userSession, "The user session should have been updated.")
        XCTAssertFalse(context.viewState.isWaiting, "The view should not be in the waiting state after setting a user session.")
    }
}
