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

@testable import ElementX
import XCTest

@MainActor
class InvitesListScreenViewModelTests: XCTestCase {
    var viewModel: InvitesListViewModelProtocol!
    var clientProxy: MockClientProxy!
    
    var context: InvitesListViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = MockClientProxy(userID: "@a:b.com")
        let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        viewModel = InvitesListViewModel(userSession: userSession)
    }

    func testInitialState() {
        XCTAssertTrue(context.viewState.invites?.isEmpty == true)
    }
}
