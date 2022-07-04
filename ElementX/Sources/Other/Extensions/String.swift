// 
// Copyright 2021 New Vector Ltd
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

import SwiftUI

extension String {
    /// Returns the string as an `AttributedString` with the specified character tinted in a different color.
    /// - Parameters:
    ///   - character: The character to be tinted.
    ///   - color: The color to tint the character. Defaults to the accent color.
    /// - Returns: An `AttributedString`.
    func tinting(_ character: Character, color: Color = .accentColor) -> AttributedString {
        var string = AttributedString(self)
        let characterView = string.characters
        for index in characterView.indices where characterView[index] == character {
            string[index..<characterView.index(after: index)].foregroundColor = color
        }
        
        return string
    }
    
    /// Whether or not the string is a Matrix user ID.
    var isMatrixUserID: Bool {
        let range = NSRange(location: 0, length: count)
        
        let detector = try? NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
        return detector?.numberOfMatches(in: self, range: range) ?? 0 == 1
    }
}
