//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Data {
    init?(hexString: String) {
        self.init()
        
        var hex = hexString
        
        // If the hex string has an odd length, prepend a zero
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }
        
        for i in stride(from: 0, to: hex.count, by: 2) {
            let startIndex = hex.index(hex.startIndex, offsetBy: i)
            let endIndex = hex.index(hex.startIndex, offsetBy: i + 2)
            let byteString = String(hex[startIndex..<endIndex])
            
            if let byte = UInt8(byteString, radix: 16) {
                append(byte)
            } else {
                return nil
            }
        }
    }
}
