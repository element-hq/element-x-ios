//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class UserAgentBuilderTests: XCTestCase {
    func testIsNotNil() {
        XCTAssertNotNil(UserAgentBuilder.makeASCIIUserAgent())
    }
    
    func testContainsClientName() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        XCTAssert(userAgent.contains(InfoPlistReader.main.bundleDisplayName) == true, "\(userAgent) does not contain client name")
    }
    
    func testContainsClientVersion() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        XCTAssert(userAgent.contains(InfoPlistReader.main.bundleShortVersionString) == true, "\(userAgent) does not contain client version")
    }
}
