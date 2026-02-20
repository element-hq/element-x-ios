//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct ServerConfirmationScreenViewStateTests {
    @Test
    func loginMessageString() {
        let matrixDotOrgLogin = ServerConfirmationScreenViewState(mode: .confirmation(LoginHomeserver.mockMatrixDotOrg.address),
                                                                  authenticationFlow: .login)
        #expect(matrixDotOrgLogin.message == L10n.screenServerConfirmationMessageLoginMatrixDotOrg, "matrix.org should have a custom message.")
        
        let elementDotIoLogin = ServerConfirmationScreenViewState(mode: .confirmation("element.io"),
                                                                  authenticationFlow: .login)
        #expect(elementDotIoLogin.message == L10n.screenServerConfirmationMessageLoginElementDotIo, "element.io should have a custom message.")
        
        let otherLogin = ServerConfirmationScreenViewState(mode: .confirmation(LoginHomeserver.mockOIDC.address),
                                                           authenticationFlow: .login)
        #expect(otherLogin.message == "", "Other servers should not show a message.")
        
        let pickerLogin = ServerConfirmationScreenViewState(mode: .picker(["element.io", "matrix.org"]),
                                                            authenticationFlow: .login)
        #expect(pickerLogin.message == nil, "The picker mode should not show a message.")
    }
    
    @Test
    func registerMessageString() {
        let matrixDotOrgRegister = ServerConfirmationScreenViewState(mode: .confirmation(LoginHomeserver.mockMatrixDotOrg.address),
                                                                     authenticationFlow: .register)
        #expect(matrixDotOrgRegister.message == L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
        
        let oidcRegister = ServerConfirmationScreenViewState(mode: .confirmation(LoginHomeserver.mockOIDC.address),
                                                             authenticationFlow: .register)
        #expect(oidcRegister.message == L10n.screenServerConfirmationMessageRegister, "The registration message should always be the same.")
    }
}
