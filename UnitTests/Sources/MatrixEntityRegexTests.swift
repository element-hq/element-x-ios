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

import Foundation

import XCTest

@testable import ElementX

class MatrixEntityRegexTests: XCTestCase {
    func testHomeserver() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixHomeserver("matrix.org"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixHomeserver("MATRIX.ORG"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixHomeserver("matrix?.org"))
    }

    func testUserID() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixUserIdentifier("@username:example.com"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixUserIdentifier("username:example.com"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixUserIdentifier("@username.example.com"))
    }
    
    func testRoomAlias() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixRoomAlias("#element-ios:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomAlias("element-ios:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomAlias("#element-ios.matrix.org"))
    }
    
    func testMatrixURI() {
        // Users
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:u/alice:example.org"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:u/alice:example.org?action=chat"))
        
        // Room ID
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/somewhere:example.org"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/my-room:example.com?via=elsewhere.ca"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/123_room:chat.myserver.net?via=elsewhere.ca&via=other.org"))
        
        // Room Alias
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:r/general:matrix.org"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:r/123_room:chat.myserver.net"))
        
        // Event
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/somewhere:example.org/e/event"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/my-room:example.com/e/message?via=elsewhere.ca"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixURI("matrix:roomid/123_room:chat.myserver.net/e/1234?via=elsewhere.ca&via=other.org"))
        
        // Inline
        let string = "Hello matrix:u/alice:example.org how are you?"
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("Hello matrix:u/alice:example.org how are you?"))
        XCTAssertEqual(MatrixEntityRegex.uriRegex.matches(in: string).count, 1)
        
        // Invalid
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("matrix://@alice:example.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("matrix://!somewhere:example.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("matrix://#general:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("matrix:event/somewhere:example.org/e/event"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixURI("matrix:e/somewhere:example.org/e/event"))
    }
    
    func testAllUsers() {
        XCTAssertTrue(MatrixEntityRegex.containsMatrixAllUsers("@room"))
        XCTAssertTrue(MatrixEntityRegex.containsMatrixAllUsers("a@rooma"))
        XCTAssertTrue(MatrixEntityRegex.containsMatrixAllUsers("a @room a"))
        XCTAssertFalse(MatrixEntityRegex.containsMatrixAllUsers("a @roaom a"))
        XCTAssertFalse(MatrixEntityRegex.containsMatrixAllUsers("@roaom"))
        XCTAssertTrue(MatrixEntityRegex.containsMatrixAllUsers("@room\n"))
    }
}
