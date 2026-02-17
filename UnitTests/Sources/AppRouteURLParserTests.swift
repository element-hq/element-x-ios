//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct AppRouteURLParserTests {
    var appSettings: AppSettings
    var appRouteURLParser: AppRouteURLParser
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
    }
    
    @Test
    func elementCallRoutes() throws {
        let url = try #require(URL(string: "https://call.element.io/test"))
        
        #expect(appRouteURLParser.route(from: url) == AppRoute.genericCallLink(url: url))
        
        let customSchemeURL = try #require(URL(string: "io.element.call:/?url=https%3A%2F%2Fcall.element.io%2Ftest"))
        
        #expect(appRouteURLParser.route(from: customSchemeURL) == AppRoute.genericCallLink(url: url))
    }
    
    @Test
    func customDomainUniversalLinkCallRoutes() throws {
        let url = try #require(URL(string: "https://somecustomdomain.element.io/test"))
        
        #expect(appRouteURLParser.route(from: url) == nil)
    }
    
    @Test
    func customSchemeLinkCallRoutes() throws {
        let urlString = "https://somecustomdomain.element.io/test?param=123"
        let url = try #require(URL(string: urlString))
        
        let encodedURLString = try #require(urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        
        let customSchemeURL = try #require(URL(string: "io.element.call:/?url=\(encodedURLString)"))
        
        #expect(appRouteURLParser.route(from: customSchemeURL) == AppRoute.genericCallLink(url: url))
    }
    
    @Test
    func httpCustomSchemeLinkCallRoutes() throws {
        let customSchemeURL = try #require(URL(string: "io.element.call:/?url=http%3A%2F%2Fcall.element.io%2Ftest"))
        
        #expect(appRouteURLParser.route(from: customSchemeURL) == nil)
    }
    
    @Test
    func matrixUserURL() throws {
        let userID = "@test:matrix.org"
        let url = try #require(URL(string: "https://matrix.to/#/\(userID)"))
        
        let route = appRouteURLParser.route(from: url)
        
        #expect(route == .userProfile(userID: userID))
    }
    
    @Test
    func matrixRoomIdentifierURL() throws {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        let url = try #require(URL(string: "https://matrix.to/#/\(id)"))
        
        let route = appRouteURLParser.route(from: url)
        
        #expect(route == .room(roomID: id, via: []))
    }
    
    @Test
    func webRoomIDURL() throws {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        let url = try #require(URL(string: "https://app.element.io/#/room/\(id)"))
        
        let route = appRouteURLParser.route(from: url)
        
        #expect(route == .room(roomID: id, via: []))
    }
    
    @Test
    func webUserIDURL() throws {
        let id = "@alice:matrix.org"
        let url = try #require(URL(string: "https://develop.element.io/#/user/\(id)"))
        
        let route = appRouteURLParser.route(from: url)
        
        #expect(route == .userProfile(userID: id))
    }
}
