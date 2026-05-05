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

struct AppRouteURLParserTests {
    var appSettings: AppSettings
    var appRouteURLParser: AppRouteURLParser
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
    }
    
    @Test
    func oidcCallbackRoute() {
        // Given an OIDC callback for this app.
        let callbackURL = appSettings.oidcRedirectURL.appending(queryItems: [URLQueryItem(name: "state", value: "12345"),
                                                                             URLQueryItem(name: "code", value: "67890")])
        
        // When parsing that route.
        let route = appRouteURLParser.route(from: callbackURL)
        
        // Then it should be considered a valid OIDC callback.
        #expect(route == .oidcCallback(url: callbackURL))
    }
    
    @Test
    func oidcCallbackAppVariantRoute() {
        // Given an OIDC callback for a different app variant.
        let callbackURL = appSettings.oidcRedirectURL
            .deletingLastPathComponent()
            .appending(component: "io.element.elementz")
            .appending(queryItems: [URLQueryItem(name: "state", value: "12345"),
                                    URLQueryItem(name: "code", value: "67890")])
        
        // When parsing that route in this app.
        let route = appRouteURLParser.route(from: callbackURL)
        
        // Then the route shouldn't be considered valid and should be ignored.
        #expect(route == nil)
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
