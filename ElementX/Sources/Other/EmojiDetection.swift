//
// Copyright 2023 New Vector Ltd
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

extension UnicodeScalar {
    var isZeroWidthJoiner: Bool {
        value == 8205
    }
    
    var isKeycap: Bool {
        value == 8419
    }
    
    var isNumber: Bool {
        switch value {
        case 48...57:
            return true
        default:
            return false
        }
    }
}

extension String {
    var containsOnlyEmoji: Bool {
        guard !isEmpty else {
            return false
        }
        
        var emojiMarkerCount = 0
        for scalar in unicodeScalars {
            let isEmojiMarker = scalar.properties.isEmoji ||
                scalar.properties.isEmojiPresentation ||
                scalar.isZeroWidthJoiner ||
                scalar.properties.isDefaultIgnorableCodePoint ||
                scalar.isKeycap
            
            guard isEmojiMarker else {
                return false
            }
            
            emojiMarkerCount += 1
        }
        
        // Plain numbers like 0 return true for .isEmoji. We don't want that
        let markersRequiringSiblings = unicodeScalars.filter {
            $0.properties.isEmoji && $0.isNumber
        }
        
        return markersRequiringSiblings.count != emojiMarkerCount && emojiMarkerCount == unicodeScalars.count
    }
}
