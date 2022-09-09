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
    func testUserIdentifierPermalink() {
        let userId = "@abcdefghijklmnopqrstuvwxyz1234567890._-=/:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(userIdentifier: userId)
            XCTAssertEqual(permalink, URL(string: "\(BuildSettings.matrixDotToUrl)/#/\(userId)"))
        } catch {
            XCTFail("User identifier must be valid: \(error)")
        }
    }
    
    func testInvalidUserIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(userIdentifier: "This1sN0tV4lid!@#$%^&*()")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidUserIdentifier)
        }
    }
    
    func testRoomIdentifierPermalink() throws {
        let roomId = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(roomIdentifier: roomId)
            XCTAssertEqual(permalink, URL(string: "\(BuildSettings.matrixDotToUrl)/#/!abcdefghijklmnopqrstuvwxyz1234567890%3Amatrix.org"))
        } catch {
            XCTFail("Room identifier must be valid: \(error)")
        }
    }
    
    func testInvalidRoomIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(roomIdentifier: "This1sN0tV4lid!@#$%^&*()")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidRoomIdentifier)
        }
    }
    
    func testRoomAliasPermalink() throws {
        let roomAlias = "#abcdefghijklmnopqrstuvwxyz-_.1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(roomAlias: roomAlias)
            XCTAssertEqual(permalink, URL(string: "\(BuildSettings.matrixDotToUrl)/#/%23abcdefghijklmnopqrstuvwxyz-_.1234567890%3Amatrix.org"))
        } catch {
            XCTFail("Room alias must be valid: \(error)")
        }
    }
    
    func testInvalidRoomAlias() {
        do {
            _ = try PermalinkBuilder.permalinkTo(roomAlias: "This1sN0tV4lid!@#$%^&*()")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidRoomAlias)
        }
    }
    
    func testEventPermalink() throws {
        let eventId = "$abcdefghijklmnopqrstuvwxyz1234567890"
        let roomId = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        
        do {
            let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventId, roomIdentifier: roomId)
            XCTAssertEqual(permalink, URL(string: "\(BuildSettings.matrixDotToUrl)/#/!abcdefghijklmnopqrstuvwxyz1234567890%3Amatrix.org/%24abcdefghijklmnopqrstuvwxyz1234567890"))
        } catch {
            XCTFail("Room and event identifiers must be valid: \(error)")
        }
    }
    
    func testInvalidEventIdentifier() {
        do {
            _ = try PermalinkBuilder.permalinkTo(eventIdentifier: "This1sN0tV4lid!@#$%^&*()", roomIdentifier: "")
        } catch {
            XCTAssertEqual(error as? PermalinkBuilderError, PermalinkBuilderError.invalidEventIdentifier)
        }
    }
}
