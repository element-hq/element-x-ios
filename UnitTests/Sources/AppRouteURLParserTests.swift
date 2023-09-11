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
    var appSettings: AppSettings!
    var appRouteURLParser: AppRouteURLParser!
    
    override func setUp() {
        AppSettings.reset()
        appSettings = AppSettings()
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
    }
    
    func testElementCallRoutes() {
        guard let url = URL(string: "https://call.element.io/test") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: url), AppRoute.genericCallLink(url: url))
        
        guard let customSchemeURL = URL(string: "io.element.call:/?url=https%3A%2F%2Fcall.element.io%2Ftest") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: customSchemeURL), AppRoute.genericCallLink(url: url))
    }
    
    func testCustomDomainUniversalLinkCallRoutes() {
        guard let url = URL(string: "https://somecustomdomain.element.io/test") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: url), nil)
    }
    
    func testCustomSchemeLinkCallRoutes() {
        let urlString = "https://somecustomdomain.element.io/test?param=123"
        guard let url = URL(string: urlString) else {
            XCTFail("URL invalid")
            return
        }
        
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            XCTFail("Could not encode URL string")
            return
        }
        
        guard let customSchemeURL = URL(string: "io.element.call:/?url=\(encodedURLString)") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: customSchemeURL), AppRoute.genericCallLink(url: url))
    }
    
    func testHttpCustomSchemeLinkCallRoutes() {
        guard let customSchemeURL = URL(string: "io.element.call:/?url=http%3A%2F%2Fcall.element.io%2Ftest") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: customSchemeURL), nil)
    }
    
    func testOIDCCallbackRoute() {
        // Given an OIDC callback for this app.
        let callbackURL = appSettings.oidcRedirectURL.appending(queryItems: [URLQueryItem(name: "state", value: "12345"),
                                                                             URLQueryItem(name: "code", value: "67890")])
        
        // When parsing that route.
        let route = appRouteURLParser.route(from: callbackURL)
        
        // Then it should be considered a valid OIDC callback.
        XCTAssertEqual(route, AppRoute.oidcCallback(url: callbackURL))
    }
    
    func testOIDCCallbackAppVariantRoute() {
        // Given an OIDC callback for a different app variant.
        let callbackURL = appSettings.oidcRedirectURL
            .deletingLastPathComponent()
            .appending(component: "elementz")
            .appending(queryItems: [URLQueryItem(name: "state", value: "12345"),
                                    URLQueryItem(name: "code", value: "67890")])
        
        // When parsing that route in this app.
        let route = appRouteURLParser.route(from: callbackURL)
        
        // Then the route shouldn't be considered valid and should be ignored.
        XCTAssertEqual(route, nil)
    }
}
