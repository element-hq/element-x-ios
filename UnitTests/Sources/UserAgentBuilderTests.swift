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

class UserAgentBuilderTests: XCTestCase {
    func testIsNotNil() {
        XCTAssertNotNil(UserAgentBuilder.makeASCIIUserAgent())
    }
    
    func testContainsClientName() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        XCTAssert(userAgent?.contains(InfoPlistReader.target.bundleDisplayName) == true, "\(userAgent ?? "nil") does not contain client name")
    }
    
    func testContainsClientVersion() {
        let userAgent = UserAgentBuilder.makeASCIIUserAgent()
        XCTAssert(userAgent?.contains(InfoPlistReader.target.bundleShortVersionString) == true, "\(userAgent ?? "nil") does not contain client version")
    }
}
