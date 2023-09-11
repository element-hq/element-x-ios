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

class AppRouteURLParserTests: XCTestCase {
    func testElementCallRoutes() {
        guard let url = URL(string: "https://call.element.io/test") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(AppRouteURLParser(appSettings: ServiceLocator.shared.settings).route(from: url), AppRoute.genericCallLink(url: url))
        
        guard let customSchemeURL = URL(string: "element://call?url=https%3A%2F%2Fcall.element.io%2Ftest") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(AppRouteURLParser(appSettings: ServiceLocator.shared.settings).route(from: customSchemeURL), AppRoute.genericCallLink(url: url))
    }
}
