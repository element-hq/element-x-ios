//
// Copyright 2024 New Vector Ltd
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

import AVKit
import XCTest

@testable import ElementX

final class AVMetadataMachineReadableCodeObjectExtensionsTest: XCTestCase {
    func testDecoQRCodeVersion8() {
        // swiftlint:disable:next line_length
        let rawDataHexString = "4a34d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f0ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec"
        // swiftlint:disable:next line_length
        let expectedDecodedString = "4d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f"
        let symbolVersion = 8
        
        guard let data = Data(hexString: rawDataHexString) else {
            XCTFail("Could not initialise the raw data")
            return
        }
        
        guard let resultData = AVMetadataMachineReadableCodeObject.removeQrProtocolData(data, symbolVersion: symbolVersion) else {
            XCTFail("Could not remove the protocol data")
            return
        }
        
        let resultString = resultData.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(expectedDecodedString, resultString)
        
        guard let expectedResultData = Data(hexString: expectedDecodedString) else {
            XCTFail("Could not initialise the decoded data")
            return
        }
        XCTAssertEqual(expectedResultData, resultData)
    }
}
