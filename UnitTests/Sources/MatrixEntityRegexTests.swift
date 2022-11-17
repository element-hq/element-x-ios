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

    func testUserId() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixUserIdentifier("@username:example.com"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixUserIdentifier("username:example.com"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixUserIdentifier("@username.example.com"))
    }

    func testRoomAlias() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixRoomAlias("#element-ios:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomAlias("element-ios:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomAlias("#element-ios.matrix.org"))
    }

    func testRoomId() {
        XCTAssertTrue(MatrixEntityRegex.isMatrixRoomIdentifier("!pMBteVpcoJRdCJxDmn:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomIdentifier("pMBteVpcoJRdCJxDmn:matrix.org"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixRoomIdentifier("!pMBteVpcoJRdCJxDmn.matrix.org"))
    }

    func testEventId() {
        // room version 1
        XCTAssertTrue(MatrixEntityRegex.isMatrixEventIdentifier("$h29iv0s8:example.com"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$h29iv0s8:example."))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$h29iv0s8:"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$h29iv0s8?"))

        // room version 3
        XCTAssertTrue(MatrixEntityRegex.isMatrixEventIdentifier("$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk."))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk:"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk?"))

        // room version 4
        XCTAssertTrue(MatrixEntityRegex.isMatrixEventIdentifier("$Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg."))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg:"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg?"))
    }
}
