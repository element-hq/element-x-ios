//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDK
import Testing

/// Just for API sanity checking, they're already properly tested in the SDK/Ruma
@Suite
struct PermalinkTests {
    @Test
    func userIdentifierPermalink() throws {
        let invalidUserId = "This1sN0tV4lid!@#$%^&*()"
        #expect(throws: (any Error).self) { try matrixToUserPermalink(userId: invalidUserId) }
        
        let validUserId = "@abcdefghijklmnopqrstuvwxyz1234567890._-=/:matrix.org"
        #expect(try matrixToUserPermalink(userId: validUserId) == "https://matrix.to/#/@abcdefghijklmnopqrstuvwxyz1234567890._-=%2F:matrix.org")
    }
    
    @Test
    func permalinkDetection() {
        var url: URL = "https://www.matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) == nil)
        
        url = "https://matrix.to/#/@bob:matrix.org?via=matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) ==
            MatrixEntity(id: .user(id: "@bob:matrix.org"),
                         via: ["matrix.org"]))
        
        url = "https://matrix.to/#/!roomidentifier:matrix.org?via=matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) ==
            MatrixEntity(id: .room(id: "!roomidentifier:matrix.org"),
                         via: ["matrix.org"]))
        
        url = "https://matrix.to/#/%23roomalias:matrix.org?via=matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) ==
            MatrixEntity(id: .roomAlias(alias: "#roomalias:matrix.org"),
                         via: ["matrix.org"]))
        
        url = "https://matrix.to/#/!roomidentifier:matrix.org/$eventidentifier?via=matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) ==
            MatrixEntity(id: .eventOnRoomId(roomId: "!roomidentifier:matrix.org", eventId: "$eventidentifier"),
                         via: ["matrix.org"]))
        
        url = "https://matrix.to/#/#roomalias:matrix.org/$eventidentifier?via=matrix.org"
        #expect(parseMatrixEntityFrom(uri: url.absoluteString) ==
            MatrixEntity(id: .eventOnRoomAlias(alias: "#roomalias:matrix.org", eventId: "$eventidentifier"),
                         via: ["matrix.org"]))
    }
}
