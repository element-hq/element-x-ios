//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
