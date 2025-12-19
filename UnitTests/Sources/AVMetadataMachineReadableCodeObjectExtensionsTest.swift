//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import XCTest

@testable import ElementX

final class AVMetadataMachineReadableCodeObjectExtensionsTest: XCTestCase {
    func testDecodeQRCodeVersion8() {
        // swiftlint:disable:next line_length
        let rawDataHexString = "4a34d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f0ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec"
        // swiftlint:disable:next line_length
        let expectedDecodedString = "4d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f"
        let symbolVersion = 8
        
        guard let data = Data(hexString: rawDataHexString) else {
            XCTFail("Could not initialise the raw data")
            return
        }
        
        guard let resultData = try? AVMetadataMachineReadableCodeObject.removeQRProtocolData(data, symbolVersion: symbolVersion) else {
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
