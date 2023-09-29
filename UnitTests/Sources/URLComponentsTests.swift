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

class URLComponentsTests: XCTestCase {
    func testAddFragmentQueryItems() {
        guard let url = URL(string: "https://test.matrix.org"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertNil(components.fragmentQueryItems)
        
        let fragmentQueryItems: [URLQueryItem] = [.init(name: "first", value: "1"), .init(name: "second", value: "2")]
        components.fragmentQueryItems = fragmentQueryItems
        
        XCTAssertEqual(components.url?.absoluteString, "https://test.matrix.org#?first=1&second=2")
    }
    
    func testRemoveFragmentQueryItem() {
        guard let url = URL(string: "https://test.matrix.org#random/data?first=1&second=2"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            XCTFail("URL invalid")
            return
        }
                
        XCTAssertNotNil(components.fragmentQueryItems)
        guard var fragmentQueryItems = components.fragmentQueryItems else {
            return
        }
        
        fragmentQueryItems.removeAll { $0.name == "first" }
        
        components.fragmentQueryItems = fragmentQueryItems
        
        XCTAssertEqual(components.url?.absoluteString, "https://test.matrix.org#random/data?second=2")
    }
    
    func testAppendFragmentQueryItem() {
        guard let url = URL(string: "https://test.matrix.org#/random/data?first=1&second=2"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            XCTFail("URL invalid")
            return
        }
                
        XCTAssertNotNil(components.fragmentQueryItems)
        guard var fragmentQueryItems = components.fragmentQueryItems else {
            return
        }
        
        fragmentQueryItems.insert(.init(name: "mr in between", value: "hello"), at: 1)
        
        components.fragmentQueryItems = fragmentQueryItems
        
        XCTAssertEqual(components.url?.absoluteString, "https://test.matrix.org#/random/data?first=1&mr%20in%20between=hello&second=2")
    }
    
    func testChangeFragmentQueryItemValue() {
        guard let url = URL(string: "https://test.matrix.org#/random/data?first=1&second=2"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertNotNil(components.fragmentQueryItems)
        guard var fragmentQueryItems = components.fragmentQueryItems else {
            return
        }
        
        fragmentQueryItems[0].value = "last"
        
        components.fragmentQueryItems = fragmentQueryItems
        
        XCTAssertEqual(components.url?.absoluteString, "https://test.matrix.org#/random/data?first=last&second=2")
    }
    
    func testElementCallParameters() {
        guard let url = URL(string: "https://call.element.io/room#/callName?appPrompt=true&confineToRoom=false"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            XCTFail("URL invalid")
            return
        }
        
        components.fragmentQueryItems?.removeAll { $0.name == "appPrompt" }
        components.fragmentQueryItems?.removeAll { $0.name == "confineToRoom" }
        
        components.fragmentQueryItems?.append(.init(name: "skipLobby", value: "true"))
        
        components.fragmentQueryItems?.append(.init(name: "appPrompt", value: "false"))
        components.fragmentQueryItems?.append(.init(name: "confineToRoom", value: "true"))
        
        XCTAssertEqual(components.url?.absoluteString, "https://call.element.io/room#/callName?skipLobby=true&appPrompt=false&confineToRoom=true")
    }
}
