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
    func oAuthCallbackRoute() {
        // Given an OAuth callback for this app.
        let callbackURL = appSettings.oAuthRedirectURL.appending(queryItems: [URLQueryItem(name: "state", value: "12345"),
                                                                              URLQueryItem(name: "code", value: "67890")])
        
        // When parsing that route.
        let route = appRouteURLParser.route(from: callbackURL)
        
        // Then it should be considered a valid OAuth callback.
        #expect(route == .oAuthCallback(url: callbackURL))
    }
    
    @Test
    func oAuthCallbackAppVariantRoute() {
        // Given an OAuth callback for a different app variant.
        let callbackURL = appSettings.oAuthRedirectURL
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
        // UCMeet has no Element web hosts configured (elementWebHosts = []), so app.element.io URLs should not be parsed.
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        let url = try #require(URL(string: "https://app.element.io/#/room/\(id)"))

        let route = appRouteURLParser.route(from: url)

        #expect(route == nil)
    }

    @Test
    func webUserIDURL() throws {
        // UCMeet has no Element web hosts configured (elementWebHosts = []), so develop.element.io URLs should not be parsed.
        let id = "@alice:matrix.org"
        let url = try #require(URL(string: "https://develop.element.io/#/user/\(id)"))

        let route = appRouteURLParser.route(from: url)

        #expect(route == nil)
    }

    // MARK: - UCMeet ucmatrix.org permalink tests

    @Test
    func ucMatrixUserURL() throws {
        let userID = "@test:matrix.org"
        let url = try #require(URL(string: "https://ucmatrix.org/#/\(userID)"))

        let route = appRouteURLParser.route(from: url)

        #expect(route == .userProfile(userID: userID))
    }

    @Test
    func ucMatrixRoomIdentifierURL() throws {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        let url = try #require(URL(string: "https://ucmatrix.org/#/\(id)"))

        let route = appRouteURLParser.route(from: url)

        #expect(route == .room(roomID: id, via: []))
    }
}
