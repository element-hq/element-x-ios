//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct MatrixEntityRegexTests {
    @Test
    func homeserver() {
        #expect(MatrixEntityRegex.isMatrixHomeserver("matrix.org"))
        #expect(MatrixEntityRegex.isMatrixHomeserver("MATRIX.ORG"))
        #expect(!MatrixEntityRegex.isMatrixHomeserver("matrix?.org"))
    }
    
    @Test
    func userID() {
        #expect(MatrixEntityRegex.isMatrixUserIdentifier("@username:example.com"))
        #expect(!MatrixEntityRegex.isMatrixUserIdentifier("username:example.com"))
        #expect(!MatrixEntityRegex.isMatrixUserIdentifier("@username.example.com"))
    }
    
    @Test
    func roomAlias() {
        #expect(MatrixEntityRegex.isMatrixRoomAlias("#element-ios:matrix.org"))
        #expect(!MatrixEntityRegex.isMatrixRoomAlias("element-ios:matrix.org"))
        #expect(!MatrixEntityRegex.isMatrixRoomAlias("#element-ios.matrix.org"))
    }
    
    @Test
    func matrixURI() {
        // Users
        #expect(MatrixEntityRegex.isMatrixURI("matrix:u/alice:example.org"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:u/alice:example.org?action=chat"))
        
        // Room ID
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/somewhere:example.org"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/my-room:example.com?via=elsewhere.ca"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/123_room:chat.myserver.net?via=elsewhere.ca&via=other.org"))
        
        // Room Alias
        #expect(MatrixEntityRegex.isMatrixURI("matrix:r/general:matrix.org"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:r/123_room:chat.myserver.net"))
        
        // Event
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/somewhere:example.org/e/event"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/my-room:example.com/e/message?via=elsewhere.ca"))
        #expect(MatrixEntityRegex.isMatrixURI("matrix:roomid/123_room:chat.myserver.net/e/1234?via=elsewhere.ca&via=other.org"))
        
        // Inline
        let string = "Hello matrix:u/alice:example.org how are you?"
        #expect(!MatrixEntityRegex.isMatrixURI("Hello matrix:u/alice:example.org how are you?"))
        #expect(MatrixEntityRegex.uriRegex.matches(in: string).count == 1)
        
        // Invalid
        #expect(!MatrixEntityRegex.isMatrixURI("matrix://@alice:example.org"))
        #expect(!MatrixEntityRegex.isMatrixURI("matrix://!somewhere:example.org"))
        #expect(!MatrixEntityRegex.isMatrixURI("matrix://#general:matrix.org"))
        #expect(!MatrixEntityRegex.isMatrixURI("matrix:event/somewhere:example.org/e/event"))
        #expect(!MatrixEntityRegex.isMatrixURI("matrix:e/somewhere:example.org/e/event"))
    }
    
    @Test
    func allUsers() {
        #expect(MatrixEntityRegex.containsMatrixAllUsers("@room"))
        #expect(MatrixEntityRegex.containsMatrixAllUsers("a@rooma"))
        #expect(MatrixEntityRegex.containsMatrixAllUsers("a @room a"))
        #expect(!MatrixEntityRegex.containsMatrixAllUsers("a @roaom a"))
        #expect(!MatrixEntityRegex.containsMatrixAllUsers("@roaom"))
        #expect(MatrixEntityRegex.containsMatrixAllUsers("@room\n"))
    }
}
