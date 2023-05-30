//
// Copyright 2023 New Vector Ltd
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

class ServerConfirmationScreenViewStateTests: XCTestCase {
    func testLoginMessageString() {
        let matrixDotOrgLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockMatrixDotOrg.address,
                                                                  authenticationFlow: .login)
        XCTAssertEqual(matrixDotOrgLogin.message, L10n.screenServerConfirmationMessageLoginMatrixDotOrg, "matrix.org should have a custom message.")
        
        let elementDotIoLogin = ServerConfirmationScreenViewState(homeserverAddress: "element.io",
                                                                  authenticationFlow: .login)
        XCTAssertEqual(elementDotIoLogin.message, L10n.screenServerConfirmationMessageLoginElementDotIo, "element.io should have a custom message.")
        
        let otherLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockOIDC.address,
                                                           authenticationFlow: .login)
        XCTAssertTrue(otherLogin.message.isEmpty, "Other servers should not show a message.")
    }
    
    func testRegisterMessageString() {
        let matrixDotOrgLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockMatrixDotOrg.address,
                                                                  authenticationFlow: .register)
        XCTAssertEqual(matrixDotOrgLogin.message, L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
        
        let otherLogin = ServerConfirmationScreenViewState(homeserverAddress: LoginHomeserver.mockOIDC.address,
                                                           authenticationFlow: .register)
        XCTAssertEqual(otherLogin.message, L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
    }
}
