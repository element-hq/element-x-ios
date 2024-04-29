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
import MatrixRustSDK
import XCTest

/// Just for API sanity checking, they're already properly tested in the SDK/Ruma
class PermalinkTests: XCTestCase {
    func testUserIdentifierPermalink() {
        let invalidUserId = "This1sN0tV4lid!@#$%^&*()"
        XCTAssertNil(try? matrixToUserPermalink(userId: invalidUserId))
        
        let validUserId = "@abcdefghijklmnopqrstuvwxyz1234567890._-=/:matrix.org"
        XCTAssertEqual(try? matrixToUserPermalink(userId: validUserId), .some("https://matrix.to/#/@abcdefghijklmnopqrstuvwxyz1234567890._-=%2F:matrix.org"))
    }
    
    func testPermalinkDetection() {
        var url: URL = "https://www.matrix.org"
        XCTAssertNil(parseMatrixEntityFrom(uri: url.absoluteString))
        
        url = "https://matrix.to/#/@bob:matrix.org?via=matrix.org"
        XCTAssertEqual(parseMatrixEntityFrom(uri: url.absoluteString),
                       MatrixEntity(id: .user(id: "@bob:matrix.org"),
                                    via: ["matrix.org"]))
        
        url = "https://matrix.to/#/!roomidentifier:matrix.org?via=matrix.org"
        XCTAssertEqual(parseMatrixEntityFrom(uri: url.absoluteString),
                       MatrixEntity(id: .room(id: "!roomidentifier:matrix.org"),
                                    via: ["matrix.org"]))
        
        url = "https://matrix.to/#/%23roomalias:matrix.org?via=matrix.org"
        XCTAssertEqual(parseMatrixEntityFrom(uri: url.absoluteString),
                       MatrixEntity(id: .roomAlias(alias: "#roomalias:matrix.org"),
                                    via: ["matrix.org"]))
        
        url = "https://matrix.to/#/!roomidentifier:matrix.org/$eventidentifier?via=matrix.org"
        XCTAssertEqual(parseMatrixEntityFrom(uri: url.absoluteString),
                       MatrixEntity(id: .eventOnRoomId(roomId: "!roomidentifier:matrix.org", eventId: "$eventidentifier"),
                                    via: ["matrix.org"]))
        
        url = "https://matrix.to/#/#roomalias:matrix.org/$eventidentifier?via=matrix.org"
        XCTAssertEqual(parseMatrixEntityFrom(uri: url.absoluteString),
                       MatrixEntity(id: .eventOnRoomAlias(alias: "#roomalias:matrix.org", eventId: "$eventidentifier"),
                                    via: ["matrix.org"]))
    }
}
