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
