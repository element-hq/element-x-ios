//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// In the future we might use this to do some customisation in what is plain text used to represent mentions.
struct PlainMentionBuilder: MentionBuilderProtocol {
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange) { }
    
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?) {
        guard !attributedString.attributedSubstring(from: range).string.hasPrefix("@") else {
            return
        }
        attributedString.insert(NSAttributedString(string: "@"), at: range.location)
    }
}
