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
        XCTAssertTrue(MatrixEntityRegex.isMatrixEventIdentifier("$shlXuTEUoMpcJqwqsDjIu33PY9bZny6US5EnX8mkMjc"))
        XCTAssertTrue(MatrixEntityRegex.isMatrixEventIdentifier("$8dDBOeRGpH3I-Mup6ypy2HA4MgkadFGG2h0R_pK_ebs"))
        XCTAssertFalse(MatrixEntityRegex.isMatrixEventIdentifier("$8dDBOeRGpH3I-Mup6ypy2HA4MgkadFGG2h0R_pK_ebs?"))
    }
}
