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

struct EmojiItemSkin: Equatable {
    let value: String
    
    init?(from emojiMartEmojiSkin: EmojiMartEmojiSkin) {
        let unicodeStringComponents = emojiMartEmojiSkin.unified.components(separatedBy: "-")
        
        var emoji = ""
        
        for unicodeStringComponent in unicodeStringComponents {
            guard let unicodeCodePoint = Int(unicodeStringComponent, radix: 16),
                  let emojiUnicodeScalar = UnicodeScalar(unicodeCodePoint) else {
                return nil
            }
            emoji.append(String(emojiUnicodeScalar))
        }
        value = emoji
    }
}
