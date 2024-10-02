//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX
@testable import MatrixRustSDK

class ClientProtocolTests: XCTestCase {
    let server = "https://matrix.org"
    let userIDServerName = "matrix.org"
    let wellKnownURL = "https://matrix.org/.well-known/element/element.json"
    
    var client: ClientProtocol!
    
    func testWellKnownLoggedOut() async {
        // Given a client that is logged out but has discovered a server.
        let client = ClientSDKMock()
        client.userIdServerNameThrowableError = MockError.notAvailable
        client.serverReturnValue = server
        
        // When discovering a server that contains the registration helper URL.
        client.getUrlUrlClosure = { [wellKnownURL] url in
            guard url == wellKnownURL else {
                XCTFail("An unexpected URL was used.")
                throw MockError.notAvailable
            }
            return "{\"registration_helper_url\":\"https://develop.element.io/#/mobile_register\"}"
        }
        
        guard case let .success(wellKnown) = await client.getElementWellKnown() else {
            XCTFail("The request should succeed.")
            return
        }
        
        // Then the well-known should include that URL.
        XCTAssertEqual(wellKnown, .init(call: nil, registrationHelperUrl: "https://develop.element.io/#/mobile_register"))
    }
    
    func testWellKnownLoggedIn() async {
        // Given a client that is logged in.
        let client = ClientSDKMock()
        client.userIdServerNameReturnValue = userIDServerName
        
        // When discovering a server that contains a custom call widget URL.
        client.getUrlUrlClosure = { [wellKnownURL] url in
            guard url == wellKnownURL else {
                XCTFail("An unexpected URL was used.")
                throw MockError.notAvailable
            }
            return "{\"call\":{\"widget_url\":\"https://call.element.dev\"}}"
        }
        
        guard case let .success(wellKnown) = await client.getElementWellKnown() else {
            XCTFail("The request should succeed.")
            return
        }
        
        // Then the well-known should include that URL.
        XCTAssertEqual(wellKnown, .init(call: .init(widgetUrl: "https://call.element.dev"), registrationHelperUrl: nil))
    }
    
    enum MockError: Error {
        case notAvailable
    }
}
