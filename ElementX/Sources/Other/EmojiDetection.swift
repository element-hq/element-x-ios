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

// Taken from https://gist.github.com/krummler/879e1ce942893db3104783d1d0e67b34
extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        unicodeScalars.count == 1 && unicodeScalars.first?.properties.isEmojiPresentation ?? false
    }

    /// Checks if the scalars will be merged into and emoji
    var isCombinedIntoEmoji: Bool {
        unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }

    var isEmoji: Bool {
        isSimpleEmoji || isCombinedIntoEmoji
    }
}

extension String {
    var containsOnlyEmoji: Bool {
        !isEmpty && !contains { !$0.isEmoji }
    }
}
