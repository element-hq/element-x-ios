//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
@testable import ElementX
import Testing

@Suite
struct AVMetadataMachineReadableCodeObjectExtensionsTest {
    @Test
    func decodeQRCodeVersion8() throws {
        // swiftlint:disable:next line_length
        let rawDataHexString = "4a34d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f0ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec11ec"
        // swiftlint:disable:next line_length
        let expectedDecodedString = "4d415452495802048bf94b094096e57d3ea43545604cf59b1704879d295cf7fdd99c62df7866da36005668747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f5f73796e617073652f636c69656e742f72656e64657a766f75732f3031485a32394d345936374a4e315658505759464e355a363638002168747470733a2f2f73796e617073652d6f6964632e656c656d656e742e6465762f"
        let symbolVersion = 8
        
        let data = try #require(Data(hexString: rawDataHexString))
        
        let resultData = try #require(try AVMetadataMachineReadableCodeObject.removeQRProtocolData(data, symbolVersion: symbolVersion))
        
        let resultString = resultData.map { String(format: "%02x", $0) }.joined()
        #expect(expectedDecodedString == resultString)
        
        let expectedResultData = try #require(Data(hexString: expectedDecodedString))
        #expect(expectedResultData == resultData)
    }
}
