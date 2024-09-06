//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class AppRouteURLParserTests: XCTestCase {
    var appSettings: AppSettings!
    var appRouteURLParser: AppRouteURLParser!
    
    override func setUp() {
        AppSettings.resetAllSettings()
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
    
    func testMatrixUserURL() {
        let userID = "@test:matrix.org"
        guard let url = URL(string: "https://matrix.to/#/\(userID)") else {
            XCTFail("Invalid url")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .userProfile(userID: userID))
    }
    
    func testMatrixRoomIdentifierURL() {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        guard let url = URL(string: "https://matrix.to/#/\(id)") else {
            XCTFail("Invalid url")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .room(roomID: id, via: []))
    }
    
    func testWebRoomIDURL() {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        guard let url = URL(string: "https://app.element.io/#/room/\(id)") else {
            XCTFail("URL invalid")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .room(roomID: id, via: []))
    }
    
    func testWebUserIDURL() {
        let id = "@alice:matrix.org"
        guard let url = URL(string: "https://develop.element.io/#/user/\(id)") else {
            XCTFail("URL invalid")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .userProfile(userID: id))
    }
}
