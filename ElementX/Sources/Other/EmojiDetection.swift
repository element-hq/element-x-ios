//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
