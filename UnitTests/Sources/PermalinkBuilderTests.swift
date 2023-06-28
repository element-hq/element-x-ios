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

@testable import ElementX
import XCTest

class PermalinkBuilderTests: XCTestCase {
    private var appSettings: AppSettings!
    
    override func setUp() {
        AppSettings.configureWithSuiteName("io.element.elementx.unitests")
        AppSettings.reset()
        appSettings = AppSettings()
    }
    
    func testUserIdentifierPermalink() {
        let userId = "@abcdefghijklmnopqrstuvwxyz1234567890._-=/:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(userIdentifier: userId, baseURL: appSettings.permalinkBaseURL)
            XCTAssertEqual(permalink, URL(string: "\(appSettings.permalinkBaseURL)/#/\(userId)"))
        } catch {
            XCTFail("User identifier must be valid: \(error)")
        }
    }
    
    func testInvalidUserIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(userIdentifier: "This1sN0tV4lid!@#$%^&*()", baseURL: appSettings.permalinkBaseURL)
            XCTFail("A permalink should not be created.")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidUserIdentifier)
        }
    }
    
    func testRoomIdentifierPermalink() throws {
        let roomId = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(roomIdentifier: roomId, baseURL: appSettings.permalinkBaseURL)
            XCTAssertEqual(permalink, URL(string: "\(appSettings.permalinkBaseURL)/#/!abcdefghijklmnopqrstuvwxyz1234567890%3Amatrix.org"))
        } catch {
            XCTFail("Room identifier must be valid: \(error)")
        }
    }
    
    func testInvalidRoomIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(roomIdentifier: "This1sN0tV4lid!@#$%^&*()", baseURL: appSettings.permalinkBaseURL)
            XCTFail("A permalink should not be created.")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidRoomIdentifier)
        }
    }
    
    func testRoomAliasPermalink() throws {
        let roomAlias = "#abcdefghijklmnopqrstuvwxyz-_.1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(roomAlias: roomAlias, baseURL: appSettings.permalinkBaseURL)
            XCTAssertEqual(permalink, URL(string: "\(appSettings.permalinkBaseURL)/#/%23abcdefghijklmnopqrstuvwxyz-_.1234567890%3Amatrix.org"))
        } catch {
            XCTFail("Room alias must be valid: \(error)")
        }
    }
    
    func testInvalidRoomAlias() {
        do {
            _ = try PermalinkBuilder.permalinkTo(roomAlias: "This1sN0tV4lid!@#$%^&*()", baseURL: appSettings.permalinkBaseURL)
            XCTFail("A permalink should not be created.")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidRoomAlias)
        }
    }
    
    func testEventPermalink() throws {
        let eventId = "$abcdefghijklmnopqrstuvwxyz1234567890"
        let roomId = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventId, roomIdentifier: roomId, baseURL: appSettings.permalinkBaseURL)
            XCTAssertEqual(permalink, URL(string: "\(appSettings.permalinkBaseURL)/#/!abcdefghijklmnopqrstuvwxyz1234567890%3Amatrix.org/%24abcdefghijklmnopqrstuvwxyz1234567890"))
        } catch {
            XCTFail("Room and event identifiers must be valid: \(error)")
        }
    }
    
    func testInvalidEventIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(eventIdentifier: "This1sN0tV4lid!@#$%^&*()", roomIdentifier: "", baseURL: appSettings.permalinkBaseURL)
            XCTFail("A permalink should not be created.")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidEventIdentifier)
        }
    }
    
    func testPermalinkDetection() {
        var url = URL(staticString: "https://www.matrix.org")
        XCTAssertEqual(PermalinkBuilder.detectPermalink(in: url, baseURL: appSettings.permalinkBaseURL), nil)

        url = URL(staticString: "https://matrix.to/#/@bob:matrix.org?via=matrix.org")
        XCTAssertEqual(PermalinkBuilder.detectPermalink(in: url, baseURL: appSettings.permalinkBaseURL), PermalinkType.userIdentifier("@bob:matrix.org"))

        url = URL(staticString: "https://matrix.to/#/!roomidentifier:matrix.org?via=matrix.org")
        XCTAssertEqual(PermalinkBuilder.detectPermalink(in: url, baseURL: appSettings.permalinkBaseURL), PermalinkType.roomIdentifier("!roomidentifier:matrix.org"))

        url = URL(staticString: "https://matrix.to/#/%23roomalias:matrix.org?via=matrix.org")
        XCTAssertEqual(PermalinkBuilder.detectPermalink(in: url, baseURL: appSettings.permalinkBaseURL), PermalinkType.roomAlias("#roomalias:matrix.org"))
        
        url = URL(staticString: "https://matrix.to/#/!roomidentifier:matrix.org/$eventidentifier?via=matrix.org")
        XCTAssertEqual(PermalinkBuilder.detectPermalink(in: url, baseURL: appSettings.permalinkBaseURL), PermalinkType.event(roomIdentifier: "!roomidentifier:matrix.org", eventIdentifier: "$eventidentifier"))
    }
}
