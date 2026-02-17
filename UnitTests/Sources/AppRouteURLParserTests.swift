//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class AppRouteURLParserTests: XCTestCase {
    var appSettings: AppSettings!
    var appRouteURLParser: AppRouteURLParser!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
    }
    
    func testElementCallRoutes() {
        // UCMeet uses embedded Element Call bundle (no hosted instance), so universal link call routes
        // are not expected to match. Only custom scheme routes work.
        guard let url = URL(string: "https://call.element.io/test") else {
            XCTFail("URL invalid")
            return
        }

        // No knownHosts configured for UCMeet, so universal links to call.element.io should not match
        XCTAssertNil(appRouteURLParser.route(from: url))
    }
    
    func testCustomDomainUniversalLinkCallRoutes() {
        guard let url = URL(string: "https://somecustomdomain.element.io/test") else {
            XCTFail("URL invalid")
            return
        }
        
        XCTAssertEqual(appRouteURLParser.route(from: url), nil)
    }
    
    func testCustomSchemeLinkCallRoutes() {
        let urlString = "https://somecustomdomain.example.com/test?param=123"
        guard let url = URL(string: urlString) else {
            XCTFail("URL invalid")
            return
        }

        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            XCTFail("Could not encode URL string")
            return
        }

        guard let customSchemeURL = URL(string: "org.ucmeet.call:/?url=\(encodedURLString)") else {
            XCTFail("URL invalid")
            return
        }

        XCTAssertEqual(appRouteURLParser.route(from: customSchemeURL), AppRoute.genericCallLink(url: url))
    }
    
    func testHttpCustomSchemeLinkCallRoutes() {
        guard let customSchemeURL = URL(string: "org.ucmeet.call:/?url=http%3A%2F%2Fcall.example.com%2Ftest") else {
            XCTFail("URL invalid")
            return
        }

        XCTAssertEqual(appRouteURLParser.route(from: customSchemeURL), nil)
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
        // UCMeet has no web client hosts configured, so Element web URLs should not be parsed
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        guard let url = URL(string: "https://app.element.io/#/room/\(id)") else {
            XCTFail("URL invalid")
            return
        }

        let route = appRouteURLParser.route(from: url)

        XCTAssertNil(route)
    }

    func testWebUserIDURL() {
        // UCMeet has no web client hosts configured, so Element web URLs should not be parsed
        let id = "@alice:matrix.org"
        guard let url = URL(string: "https://develop.element.io/#/user/\(id)") else {
            XCTFail("URL invalid")
            return
        }

        let route = appRouteURLParser.route(from: url)

        XCTAssertNil(route)
    }
}
